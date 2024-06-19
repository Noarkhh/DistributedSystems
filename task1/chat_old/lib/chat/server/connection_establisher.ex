defmodule Chat.Server.ConnectionEstablisher do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    {:ok, listening_tcp_socket} = :gen_tcp.listen(8000, [])

    {:ok, %{listening_tcp_socket: listening_tcp_socket, supervisor: nil}}
  end

  @impl true
  def handle_cast({:supervisor, supervisor}, state) do
    accept_connection(supervisor, state.listening_tcp_socket)
    {:noreply, %{state | supervisor: supervisor}}
  end

  @impl true
  def terminate(_reason, state) do
    :gen_tcp.close(state.listening_tcp_socket)
  end

  defp accept_connection(supervisor, listening_tcp_socket) do
    {:ok, connected_tcp_socket} = :gen_tcp.accept(listening_tcp_socket)

    {:ok, connection_pid} =
      Supervisor.start_child(supervisor, Chat.Server.Connection)

    :ok = :gen_tcp.controlling_process(connected_tcp_socket, connection_pid)

    GenServer.cast(connection_pid, {:tcp_socket, connected_tcp_socket})

    accept_connection(supervisor, listening_tcp_socket)
  end
end
