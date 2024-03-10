defmodule Chat.Server.MessageHub do
  use GenServer

  require Logger

  alias Chat.Server.Connection

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @spec relay_tcp_message(message :: term(), sender_pid :: pid()) :: :ok
  def relay_tcp_message(message, sender_pid) do
    GenServer.cast(__MODULE__, {:relay_tcp_message, sender_pid, message})
  end

  @impl true
  def init(port) do
    {:ok, udp_socket} = :gen_udp.open(port, mode: :binary)
    {:ok, %{supervisor: nil, udp_socket: udp_socket}}
  end

  @impl true
  def handle_cast({:supervisor, supervisor}, state) do
    Logger.info("Received supervisor #{inspect(supervisor)}")

    {:noreply, %{state | supervisor: supervisor}}
  end

  @impl true
  def handle_cast({:relay_tcp_message, sender_pid, message}, state) do
    Logger.info("Relaying message: #{inspect(message)}")

    get_connection_pids(state)
    |> Enum.filter(&(&1 != sender_pid))
    |> Enum.each(&Connection.send_message(&1, message))

    {:noreply, state}
  end

  @impl true
  def handle_info({:udp, _socket, sender_addres, sender_port, message}, state) do
    Logger.info("Relaying media message: #{inspect(message)}")

    get_connection_pids(state)
    |> Enum.map(&Connection.get_client_address/1)
    |> Enum.filter(&(&1 != {sender_addres, sender_port}))
    |> Enum.each(fn {dest_address, dest_port} ->
      :gen_udp.send(state.udp_socket, dest_address, dest_port, message)
    end)

    {:noreply, state}
  end

  defp get_connection_pids(%{supervisor: supervisor} = _state) do
    Supervisor.which_children(supervisor)
    |> Enum.filter(&match?({{Connection, _id}, _pid, :worker, _modules}, &1))
    |> Enum.map(fn {{Connection, _id}, pid, :worker, _modules} -> pid end)
  end
end
