defmodule Otis.LoggerHandler do
  use     GenEvent
  require Logger

  def init(id) do
    {:ok, %{id: id, progress_count: 0}}
  end

  # Rate limit the source progress events to 1 out of 10 (or roughly every 1s)
  def handle_event({:rendition_progress, [_channel_id, _rendition_id, _position, :infinity]}, state) do
    {:ok, state}
  end
  def handle_event({:rendition_progress, _args} = event, %{progress_count: 0} = state) do
    log_event(event, state)
    {:ok, %{state | progress_count: 100}}
  end
  def handle_event({:rendition_progress, _args}, state) do
    {:ok, %{state | progress_count: state.progress_count - 1}}
  end

  def handle_event(event, state) do
    log_event(event, state)
    {:ok, state}
  end

  def log_event(event, _state) do
    Logger.info "EVENT: #{ inspect event }"
  end
end
