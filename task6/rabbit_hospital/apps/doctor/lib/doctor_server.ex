defmodule DoctorServer do
  use GenServer

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, [])
  end

  @impl true
  def init(requests_strings) do
    {:ok, connection} = AMQP.Connection.open()
    {:ok, channel} = AMQP.Channel.open(connection)
    {:ok, %{queue: queue_name}} = AMQP.Queue.declare(channel, "", exclusive: true)
    AMQP.Exchange.declare(channel, "requests", :direct)
    AMQP.Basic.consume(channel, queue_name, nil, no_ack: true)

    AMQP.Exchange.declare(channel, "admin_exchange", :fanout)
    AMQP.Queue.bind(channel, queue_name, "admin_exchange")

    Enum.each(requests_strings, fn request ->
      [_name, joint] = String.split(request)
      AMQP.Basic.publish(channel, "requests", joint, "#{request} #{queue_name}")
    end)

    {:ok, %{queue_name: queue_name, connection: connection}}
  end

  @impl true
  def handle_info({:basic_deliver, data, _metadata}, state) do
    case String.split(data) do
      ["admin_info" | info] -> IO.puts("admin info: #{Enum.join(info, " ")}")
      [name, joint, "done"] -> IO.puts("#{joint} joint of patient #{name} handled")
    end

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
