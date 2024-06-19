defmodule Chat.Server do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Chat.Server.ConnectionEstablisher
    ]

    {:ok, supervisor} =
      Supervisor.start_link(children, strategy: :one_for_one, name: ServerSupervisor)

    GenServer.cast(Chat.Server.ConnectionEstablisher, {:supervisor, supervisor})

    {:ok, supervisor}
  end
end
