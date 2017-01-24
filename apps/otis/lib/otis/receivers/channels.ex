defmodule Otis.Receivers.Channels do
  use Supervisor

  alias Otis.Receiver
  @supervisor_name __MODULE__
  @channel_registry Otis.Receivers.ChannelRegistry
  @subscriber_registry Otis.Receivers.SubscriberRegistry

  def channel_namespace, do: @channel_registry
  def subscriber_namespace, do: @subscriber_registry

  def add_receiver(receiver, channel) do
    # Notify new receiver before actually joining channel group to allow
    # broadcasters to send buffer packets to new receiver before existing
    # stream packets are sent automatically.
    notify_add_receiver(receiver, channel)
    {:ok, _proxy} = Supervisor.start_child(@supervisor_name, [receiver, channel])
  end

  def register(receiver, channel) do
    Registry.register(@channel_registry, channel.id, receiver)
  end

  def lookup(channel_id) do
    @channel_registry |> Registry.lookup(channel_id) |> Enum.map(&elem(&1, 1))
  end

  def subscribe(name, channel_id) do
    Registry.register(@subscriber_registry, channel_id, name)
  end

  def subscribers(channel_id) do
    @subscriber_registry |> Registry.lookup(channel_id)
  end

  def notify_add_receiver(receiver, channel) do
    Otis.State.Events.notify({:receiver_added, [channel.id, receiver.id]})
    Enum.each(subscribers(channel.id), fn({pid, _name}) ->
      send pid, {:receiver_joined, [receiver.id, receiver]}
    end)
  end

  def notify_remove_receiver(receiver, channel) do
    Otis.State.Events.notify({:receiver_removed, [channel.id, receiver.id]})
    Enum.each(subscribers(channel.id), fn({pid, _name}) ->
      send pid, {:receiver_left, [receiver.id, receiver]}
    end)
  end

  def send_data(channel_id, data) do
    Enum.each(lookup(channel_id), fn(r) ->
      Receiver.send_data(r, data)
    end)
  end

  def volume_multiplier(channel_id, volume) do
    Enum.each(lookup(channel_id), fn(r) ->
      Receiver.volume_multiplier(r, volume)
    end)
  end

  def stop(channel_id) do
    Enum.each(lookup(channel_id), fn(r) ->
      Receiver.stop(r)
    end)
  end

  def latency(channel_id) do
    channel_id |> lookup() |> Enum.map(&Receiver.latency!/1) |> max_latency()
  end

  defp max_latency([]) do
    0
  end
  defp max_latency(r) do
    Enum.max(r)
  end

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: @supervisor_name)
  end

  def init(:ok) do
    children = [
      worker(Otis.Receivers.Proxy, [], [restart: :temporary])
    ]
    supervise(children, strategy: :simple_one_for_one)
  end
end