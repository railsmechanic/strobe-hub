defmodule Otis.Persistence.ReceiversTest do
  use    ExUnit.Case
  alias  Otis.Receivers
  import MockReceiver

  setup do
    MessagingHandler.attach
    id = Otis.uuid
    {:ok, channel} = Otis.Channels.create(id, "Fishy")
    channel = %Otis.Channel{pid: channel, id: id}
    assert_receive {:channel_added, [^id, _]}
    channel_volume = 0.56
    Otis.Channel.volume channel, channel_volume
    {:ok, channel: channel, channel_volume: channel_volume}
  end

  test "receivers get their volume set from the db", context do
    id = Otis.uuid
    channel = Otis.State.Channel.find(context.channel.id)
    _record = Otis.State.Receiver.create!(channel, id: id, name: "Receiver", volume: 0.34)
    mock = connect!(id, 1234)
    assert_receive {:receiver_connected, [^id, _]}
    {:ok, msg} = ctrl_recv(mock)
    assert msg == %{ "volume" => (0.34 * context.channel_volume) }
  end

  test "receiver volume changes get persisted to the db", context do
    id = Otis.uuid
    channel = Otis.State.Channel.find(context.channel.id)
    _record = Otis.State.Receiver.create!(channel, id: id, name: "Receiver", volume: 0.34)
    _mock = connect!(id, 1234)
    assert_receive {:receiver_connected, [^id, _]}
    Otis.State.Events.sync_notify {:receiver_volume_change, [id, 0.98]}
    assert_receive {:receiver_volume_change, [^id, 0.98]}
    record = Otis.State.Receiver.find id
    assert record.volume == 0.98
  end

  test "receivers get attached to the assigned channel", context do
    id = Otis.uuid
    channel = Otis.State.Channel.find(context.channel.id)
    _record = Otis.State.Receiver.create!(channel, id: id, name: "Receiver", volume: 0.34)
    _mock = connect!(id, 1234)
    assert_receive {:receiver_connected, [^id, _]}
    {:ok, receiver} = Receivers.receiver(id)
    receivers = Otis.Receivers.Channels.lookup(context.channel.id)
    assert receivers == [receiver]
  end

  test "receiver channel changes get persisted", context do
    id = Otis.uuid
    channel = Otis.State.Channel.find(context.channel.id)
    _record = Otis.State.Receiver.create!(channel, id: id, name: "Receiver", volume: 0.34)
    _mock = connect!(id, 1234)
    assert_receive {:receiver_connected, [^id, _]}
    {:ok, receiver} = Receivers.receiver(id)
    receivers = Otis.Receivers.Channels.lookup(context.channel.id)
    assert receivers == [receiver]

    channel1_id = context.channel.id
    channel2_id = Otis.uuid()
    {:ok, _channel2} = Otis.Channels.create(channel2_id, "Froggy")
    assert_receive {:channel_added, [^channel2_id, _]}

    Otis.Receivers.attach id, channel2_id
    assert_receive {:receiver_removed, [^channel1_id, ^id]}
    assert_receive {:receiver_added, [^channel2_id, ^id]}
    record = Otis.State.Receiver.find id
    assert record.channel_id == channel2_id
    {:ok, receiver} = Receivers.receiver(id)
    receivers = Otis.Receivers.Channels.lookup(context.channel.id)
    assert receivers == []
    receivers = Otis.Receivers.Channels.lookup(channel2_id)
    assert receivers == [receiver]
  end
end