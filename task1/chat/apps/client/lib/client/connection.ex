defmodule Chat.Client.Connection do
  use GenServer

  require Logger

  @multicast_address {224, 0, 1, 0}
  @multicast_port 8001

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def send_message(message, nickname, mode) do
    GenServer.cast(__MODULE__, {:send, message, nickname, mode})
  end

  @impl true
  def init({server_address, server_port}) do
    connected_tcp_socket = connect_to_server(server_address, server_port)

    {:ok, {_address, port}} = :inet.sockname(connected_tcp_socket)
    {:ok, udp_socket} = :gen_udp.open(port, mode: :binary)

    {:ok, multicast_socket} =
      :gen_udp.open(@multicast_port,
        mode: :binary,
        reuseaddr: true,
        ip: @multicast_address,
        multicast_loop: true,
        add_membership: {@multicast_address, {0, 0, 0, 0}}
      )

    Logger.debug("Connected to the server: #{:inet.ntoa(server_address)}:#{server_port}")

    {:ok,
     %{
       tcp_socket: connected_tcp_socket,
       udp_socket: udp_socket,
       multicast_socket: multicast_socket,
       server_address: server_address,
       server_port: server_port
     }}
  end

  @impl true
  def handle_info({:tcp, _socket, message}, state) do
    IO.write("\nNew message from #{message}\n> ")

    {:noreply, state}
  end

  @impl true
  def handle_info(
        {:udp, multicast_socket, _sender_address, sender_port, message},
        %{multicast_socket: multicast_socket} = state
      ) do
    {:ok, {_local_address, local_port}} = :inet.sockname(state.udp_socket)

    if local_port != sender_port do
      IO.write("\nNew multicast media message from #{message}\n> ")
    end

    {:noreply, state}
  end

  @impl true
  def handle_info({:udp, _socket, _address, _port, message}, state) do
    IO.write("\nNew media message from #{message}\n> ")

    {:noreply, state}
  end

  @impl true
  def handle_info({:tcp_closed, _socket}, state) do
    {:stop, :normal, state}
  end

  @impl true
  def handle_cast({:send, message, nickname, :tcp}, state) do
    :ok = :gen_tcp.send(state.tcp_socket, "#{nickname}:\n#{message}")

    {:noreply, state}
  end

  @impl true
  def handle_cast({:send, message, nickname, :udp}, state) do
    :ok =
      :gen_udp.send(
        state.udp_socket,
        state.server_address,
        state.server_port,
        "#{nickname}:\n#{message}"
      )

    {:noreply, state}
  end

  @impl true
  def handle_cast({:send, message, nickname, :multicast}, state) do
    :ok =
      :inet.setopts(state.multicast_socket, drop_membership: {@multicast_address, {0, 0, 0, 0}})

    :ok =
      :gen_udp.send(
        state.udp_socket,
        @multicast_address,
        @multicast_port,
        "#{nickname}:\n#{message}"
      )

    :ok =
      :inet.setopts(state.multicast_socket, add_membership: {@multicast_address, {0, 0, 0, 0}})

    {:noreply, state}
  end

  defp connect_to_server(server_address, server_port, retry_timeout \\ 1000) do
    case :gen_tcp.connect(server_address, server_port, mode: :binary) do
      {:ok, socket} ->
        IO.write("Server connection established\n> ")
        socket

      {:error, :econnrefused} ->
        IO.puts("Server connection failed, retrying in #{retry_timeout}ms...")
        Process.sleep(retry_timeout)
        connect_to_server(server_address, server_port, retry_timeout + 1000)
    end
  end
end
