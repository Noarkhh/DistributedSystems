defmodule Chat.Server.ConnectionManager do
  use GenServer

  require Logger

  alias Chat.Server.Connection

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(listening_port) do
    {:ok, listening_tcp_socket} = :gen_tcp.listen(listening_port, mode: :binary)

    Logger.info("Started listening on port #{listening_port}")

    state = %{
      supervisor: nil,
      listening_tcp_socket: listening_tcp_socket
    }

    {:ok, state}
  end

  @impl true
  def handle_cast({:supervisor, supervisor}, state) do
    Logger.info("Received supervisor #{inspect(supervisor)}")

    state = %{state | supervisor: supervisor}
    {:noreply, state, {:continue, %{}}}
  end

  @impl true
  def handle_continue(continue_arg, state) do
    %{listening_tcp_socket: listening_tcp_socket, supervisor: supervisor} = state
    {:ok, connected_tcp_socket} = :gen_tcp.accept(listening_tcp_socket)

    {:ok, {peer_addr, peer_port}} = :inet.peername(connected_tcp_socket)

    Logger.info("Accepted connection from #{:inet.ntoa(peer_addr)}:#{peer_port}")

    new_connection_id =
      Supervisor.which_children(supervisor)
      |> Enum.filter(fn {id, _pid, :worker, _modules} -> match?({Connection, _id}, id) end)
      |> Enum.map(fn {{Connection, id}, _pid, :worker, _modules} -> id end)
      |> Enum.max(&>=/2, fn -> -1 end)
      |> then(&(&1 + 1))

    {:ok, new_connection_pid} =
      Supervisor.start_child(supervisor, get_new_connection_child_spec(new_connection_id))

    current_connections =
      Supervisor.which_children(supervisor)
      |> Enum.filter(fn {id, _pid, :worker, _modules} -> match?({Connection, _id}, id) end)

    Logger.info("Current connections: #{inspect(current_connections)}")

    :gen_tcp.controlling_process(connected_tcp_socket, new_connection_pid)

    GenServer.cast(new_connection_pid, {:tcp_socket, connected_tcp_socket})

    {:noreply, state, {:continue, continue_arg}}
  end

  @impl true
  def terminate(_reason, state) do
    Logger.info("Closing listening TCP socket")
    :gen_tcp.close(state.listening_tcp_socket)
  end

  defp get_new_connection_child_spec(id) do
    %{
      id: {Connection, id},
      start: {Connection, :start_link, []},
      restart: :temporary
    }
  end
end
