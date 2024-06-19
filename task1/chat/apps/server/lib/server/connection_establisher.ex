defmodule Chat.Server.ConnectionEstablisher do
  use GenServer

  require Logger

  alias Chat.Server.ConnectionEstablisher
  alias Chat.Server.Connection

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    {:ok, listening_tcp_socket} = :gen_tcp.listen(8008, [])

    Logger.info("Started listening TCP socket")
    {:ok, %{listening_tcp_socket: listening_tcp_socket, supervisor: nil}}
  end

  @impl true
  def handle_cast({:supervisor, supervisor}, state) do
    Logger.info("Received supervisor's PID")
    accept_connection(supervisor, state.listening_tcp_socket)
    {:noreply, %{state | supervisor: supervisor}}
  end

  @impl true
  def terminate(_reason, state) do
    :gen_tcp.close(state.listening_tcp_socket)
  end

  defp accept_connection(supervisor, listening_tcp_socket) do
    {:ok, connected_tcp_socket} = :gen_tcp.accept(listening_tcp_socket)

    {:ok, {peer_addr, peer_port}} = :inet.peername(connected_tcp_socket)

    Logger.info("Connected to client: #{:inet.ntoa(peer_addr)}:#{peer_port}")

    current_connections =
      Supervisor.which_children(supervisor)
      |> Enum.filter(fn {id, pid, :worker, _modules} -> id != ConnectionEstablisher end)

    Logger.info("Current connections: #{inspect(current_connections)}")

    new_connection_id_number =
      current_connections
      |> Enum.map(fn {{Connection, id}, _pid, :worker, _modules} -> id end)
      |> Enum.max(&>=/2, fn -> 0 end)
      |> then(&(&1 + 1))

    new_connection_child_spec =
      get_new_connection_child_spec(new_connection_id_number)

    {:ok, connection_pid} =
      Supervisor.start_child(supervisor, new_connection_child_spec)

    :ok = :gen_tcp.controlling_process(connected_tcp_socket, connection_pid)

    GenServer.cast(connection_pid, {:tcp_socket, connected_tcp_socket})

    accept_connection(supervisor, listening_tcp_socket)
  end

  defp get_new_connection_child_spec(id_number) do
    %{
      id: {Connection, id_number},
      start: {Connection, :start_link, []}
    }
  end
end
