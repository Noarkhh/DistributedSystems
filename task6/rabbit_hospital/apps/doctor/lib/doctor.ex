defmodule Doctor do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {DoctorServer, get_requests()}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: DoctorSupervisor)
  end

  defp get_requests() do
    System.argv()
    |> Enum.chunk_every(2)
    |> Enum.map(fn [name, joint] -> "#{name} #{joint}" end)
  end
end
