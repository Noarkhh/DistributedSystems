defmodule Chat.Server.Connection do
  use GenServer

  require Logger

  alias Chat.Server.MessageHub

  def start_link() do
    GenServer.start_link(__MODULE__, [])
  end

  @spec send_message(connection_pid :: pid(), message :: iodata()) :: :ok
  def send_message(connection_pid, message) do
    GenServer.cast(connection_pid, {:send_message, message})
  end

  @spec get_client_address(connection_pid :: pid()) :: {:inet.ip_address(), :inet.port_number()}
  def get_client_address(connection_pid) do
    GenServer.call(connection_pid, :client_address)
  end

  @impl true
  def init(_init_arg) do
    state = %{
      tcp_socket: nil
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:client_address, _from, state) do
    {:ok, sockaddr} = :inet.peername(state.tcp_socket)
    {:reply, sockaddr, state}
  end

  @impl true
  def handle_cast({:tcp_socket, socket}, state) do
    {:noreply, %{state | tcp_socket: socket}}
  end

  @impl true
  def handle_cast({:send_message, message}, state) do
    Logger.info("Sending message #{message}")
    :ok = :gen_tcp.send(state.tcp_socket, message)
    {:noreply, state}
  end

  @impl true
  def handle_info({:tcp, _socket, msg}, state) do
    Logger.info("Received message: #{inspect(msg)}")
    MessageHub.relay_tcp_message(msg, self())
    {:noreply, state}
  end

  @impl true
  def handle_info({:tcp_closed, _socket}, state) do
    {:stop, :normal, state}
  end

  @impl true
  def terminate(_reason, state) do
    :gen_tcp.close(state.tcp_socket)
  end
end
