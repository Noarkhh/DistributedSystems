defmodule Chat.Server do
  @moduledoc false

  @listening_port 8008

  use Application

  require Logger

  alias Chat.Server.MessageHub
  alias Chat.Server.ConnectionManager

  @impl true
  def start(_type, _args) do
    children = [
      {ConnectionManager, get_listening_port()},
      {MessageHub, get_listening_port()}
    ]

    {:ok, supervisor} =
      Supervisor.start_link(children, strategy: :one_for_one, name: Server.Supervisor)

    Logger.info("Started the main supervisor: #{inspect(supervisor)}")

    GenServer.cast(ConnectionManager, {:supervisor, supervisor})
    GenServer.cast(MessageHub, {:supervisor, supervisor})

    {:ok, supervisor}
  end

  defp get_listening_port() do
    case System.argv() do
      [] -> @listening_port
      [port | _rest] -> Integer.parse(port) |> elem(0)
    end
  end
end
