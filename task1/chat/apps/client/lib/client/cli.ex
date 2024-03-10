defmodule Chat.Client.CLI do
  alias Chat.Client.Connection
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    nickname = IO.gets("Enter your nickname: ") |> String.trim()
    {:ok, %{nickname: nickname}, {:continue, %{}}}
  end

  @impl true
  def handle_continue(continue_arg, state) do
    get_input(:tcp)
    |> process_input(state.nickname)

    {:noreply, state, {:continue, continue_arg}}
  end

  defp process_input(input, nickname, mode \\ :tcp) do
    case input do
      "Q" -> :init.stop(0)
      "U" -> get_input(:udp) |> process_input(nickname, :udp)
      "M" -> get_input(:multicast) |> process_input(nickname, :multicast)
      "" -> :ok
      other -> Connection.send_message(other, nickname, mode)
    end
  end

  defp get_input(mode) do
    prompt =
      case mode do
        :tcp -> "> "
        :udp -> "[U]> "
        :multicast -> "[M]> "
      end

    if mode == :tcp do
      IO.gets(prompt)
    else
      get_input_rec(prompt)
    end
    |> String.trim()
  end

  defp get_input_rec(prompt) do
    input = IO.gets(prompt)

    if input == "\n",
      do: input,
      else: input <> get_input_rec("")
  end
end
