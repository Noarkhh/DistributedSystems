defmodule TechnicianServer do
  use GenServer

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, [])
  end

  @impl true
  def init(treated_joints) do
    {:ok, connection} = AMQP.Connection.open()
    {:ok, channel} = AMQP.Channel.open(connection)
    {:ok, %{queue: admin_queue_name}} = AMQP.Queue.declare(channel, "", exclusive: true)
    AMQP.Exchange.declare(channel, "requests", :direct)
    AMQP.Basic.consume(channel, admin_queue_name, nil, no_ack: true)

    AMQP.Exchange.declare(channel, "admin_exchange", :fanout)
    AMQP.Queue.bind(channel, admin_queue_name, "admin_exchange")

    Enum.each(treated_joints, fn joint ->
      queue_name = "#{joint}_queue"

      AMQP.Queue.declare(channel, queue_name, durable: true)
      AMQP.Queue.bind(channel, queue_name, "requests", routing_key: joint)
      AMQP.Basic.consume(channel, queue_name, nil, no_ack: true)
    end)

    {:ok, %{connection: connection, channel: channel}}
  end

  @impl true
  def handle_info({:basic_deliver, data, _metadata}, state) do
    case String.split(data) do
      ["admin_info" | info] ->
        IO.puts("admin info: #{Enum.join(info, " ")}")

      [name, joint, doctor_queue] ->
        IO.puts("Handling #{joint} joint of patient #{name}...")
        Process.sleep(Enum.random(100..400))
        message = "#{name} #{joint} done"
        AMQP.Basic.publish(state.channel, "", doctor_queue, message)
        AMQP.Basic.publish(state.channel, "", "admin_queue", message)
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
