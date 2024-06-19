defmodule AdministratorServer do
  use GenServer

  @joints ["hip", "elbow", "knee"]

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, [])
  end

  @impl true
  def init(_arg) do
    {:ok, connection} = AMQP.Connection.open()
    {:ok, channel} = AMQP.Channel.open(connection)
    AMQP.Queue.declare(channel, "admin_queue", exclusive: true)
    AMQP.Exchange.declare(channel, "admin_exchange", :fanout)
    AMQP.Basic.consume(channel, "admin_queue", nil, no_ack: true)

    Enum.each(@joints, fn joint ->
      AMQP.Queue.bind(channel, "admin_queue", "requests", routing_key: joint)
    end)

    AMQP.Basic.publish(channel, "admin_exchange", "", "admin_info Admin started")

    {:ok, %{connection: connection, channel: channel}}
  end

  @impl true
  def handle_info({:basic_deliver, data, _metadata}, state) do
    IO.puts("Received data: #{data}")

    {:noreply, state}
  end

  @impl true
  def handle_info(_message, state) do
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, state) do
    AMQP.Connection.close(state.connection)
  end
end
