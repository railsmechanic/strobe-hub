
defmodule Otis.Zone.Emitter do
  @moduledoc """
  Emits a given audio packet ({timestamp, data}) at the given time
  """

  use     Monotonic
  require Logger

  defstruct [:socket, pool: Otis.EmitterPool]

  # Public API

  def new(socket) do
    %__MODULE__{ socket: socket }
  end

  def emit(emitter, timestamp, packet, socket) do
    send(emitter, {:emit, timestamp, packet, socket})
  end

  def discard!(emitter, timestamp) do
    send(emitter, {:discard, timestamp})
  end

  ## GenServer api

  def start_link(opts) do
    :proc_lib.start_link(__MODULE__, :init, [opts])
  end

  @blank_emit {nil, nil, nil} # timestamp, packet, socket

  def init([interval: packet_interval, packet_size: packet_size, pool: pool]) do
    :proc_lib.init_ack({:ok, self})

    state = {
      {0, 0, 3000},                        # timing information
      @blank_emit,                         # emit data
      {packet_interval, packet_size, pool} # config
    }
    Process.flag :priority, :high
    wait(state)
  end

  defp wait(state) do
    # Logger.debug "Emitter.wait... #{inspect state}"
    receive do
      {:discard, _timestamp} ->
        # We're by definition waiting without a packet so this is a no-op
        wait(state)
      {:emit, time, packet, socket} ->
        start(time, packet, socket, state)
      msg ->
        Logger.debug "Emitter got #{inspect msg}"
        wait(state)
    end
  end

  defp start(time, packet, socket, {{_t, n, d}, _emit, config} = _state) do
    now = monotonic_microseconds
    monitor_emit_time(time, now, packet)
    state = {{monotonic_microseconds, n, d}, {time, packet, socket}, config}
    test_packet state
  end

  defp loop(state) do
    receive do
      {:discard, timestamp} ->
        # Check that we're not actually waiting to send a different packet
        if discard_packet?(timestamp, state) do
          Logger.info "Discarding packet #{timestamp - monotonic_microseconds}"
          start_waiting(state)
        else
          test_packet(new_state(state))
        end
    after 2 ->
      test_packet(new_state(state))
    end
  end

  defp discard_packet?(time, {_loop, {_emit_time, packet, _socket}, _config} = _state) do
    packet.timestamp == time
  end

  defp test_packet({{now, _, d}, {time, _packet, _socket}, _config} = state) do
    case time - now do
      x when x <= 1 ->
        emit_frame(state)
      x when x <= d ->
        loop_tight(state)
      _ ->
        loop(state)
    end
  end

  @jitter 500

  defp loop_tight({{_t, n, d}, {time, _packet, _socket} = emit, config}) do
    now   = monotonic_microseconds
    state = {{now, n, d}, emit, config}
    case time - now do
      x when x <= @jitter ->
        emit_frame(state)
      _ -> loop_tight(state)
    end
  end

  defp emit_frame({_loop, {_time, packet, socket}, {_pi, _ps, pool} = _config} = state) do
    # now = monotonic_microseconds
    # Logger.debug "At #{_time - now}: emit #{timestamp - now} on socket #{inspect socket}"
    Otis.Zone.Socket.send(socket, packet.timestamp, packet.data)
    :poolboy.checkin(pool, self)
    start_waiting(state)
  end

  defp start_waiting(state) do
    wait(waiting_state(state))
  end

  defp waiting_state({loop, _emit, config} = _state) do
    {loop, @blank_emit, config}
  end

  defp new_state({{t, n, d}, emit, config}) do
    m   = n+1
    now = monotonic_microseconds
    delay = case d do
      0 -> now - t
      _ -> (((n * d) + (now - t)) / m)
    end
    {{now, m, delay}, emit, config}
  end

  defp monitor_emit_time(time, now, packet) do
    case time - now do
      s when s < 0 ->
        play_latency = packet.timestamp - now
        if (abs(s)/play_latency) >= 0.1 do
          Logger.warn "Late emitter: emit time (ms): #{Float.round(s/1000, 2)}; packet play in (ms): #{round(play_latency/1000)}"
        end
      _ -> nil
    end
  end
end

defimpl Otis.Broadcaster.Emitter, for: Otis.Zone.Emitter do
  def emit(emitter, emit_time, packet) do
    pid = :poolboy.checkout(emitter.pool)
    Otis.Zone.Emitter.emit(pid, emit_time, packet, emitter.socket)
    {:emitter, pid}
  end

  def stop(emitter) do
    Otis.Zone.Socket.stop(emitter.socket)
  end
end
