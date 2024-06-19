defmodule Technician do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {TechnicianServer, get_supported_joints()}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: TechnicianSupervisor)
  end

  defp get_supported_joints() do
    System.argv()
  end
end
