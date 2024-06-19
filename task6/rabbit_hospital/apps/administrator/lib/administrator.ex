defmodule Administrator do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AdministratorServer
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: AdministratorSupervisor)
  end
end
