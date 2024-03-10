defmodule Chat.Client do
  use Application

  alias Chat.Client.Connection
  alias Chat.Client.CLI

  @listening_port 8008

  @impl true
  def start(_type, _args) do
    children = [
      CLI,
      {Connection, {{127, 0, 0, 1}, get_listening_port()}}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: ClientSupervisor)
  end

  defp get_listening_port() do
    case System.argv() do
      [] -> @listening_port
      [port | _rest] -> Integer.parse(port) |> elem(0)
    end
  end
end
