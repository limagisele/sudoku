defmodule Sudoku.Cli do
  alias Sudoku.{State, Game}

  def start(ui) do
    with {:ok, state} <- State.new(ui),
         {:ok, state} <- State.event(state, {:start_game}),
    do: state, else: (error -> error)
  end

  def play() do
    start(&handle/2)
  end

  def handle(%State{status: :initial}, :start) do
    IO.puts("Game Started")
  end

  def handle(%State{status: :playing} = state, :get_input) do
    display(state.board)

    IO.puts("What position to fill?")
    pos = IO.gets("Position: ") |> String.trim |> String.to_integer
    IO.puts("With what number?")
    guess = IO.gets("Guess: ") |> String.trim |> String.to_integer

    {pos, guess}
  end

  def handle(%State{status: :playing} = state) do
    with {pos, guess} <- state.ui.(state, :get_input),
         {:ok, updated_board, message} <- Game.play_at(state.board, pos, guess),
         {:ok, state} <- State.event(%{state | board: updated_board}, {:board_solved?, updated_board})
    do
      IO.puts(message)
      handle(state)
    else
      (error -> error)
    end
  end

  def handle(%State{status: :game_over} = state) do
    IO.puts("You Won!")
    display(state.board)
  end

  def display(board) do
    0..8
    |> Enum.map(fn row ->
      0..8
      |> Enum.map(fn col ->
        elem(board, row * 9 + col)
      end)
      |> Enum.join(" ")
    end)
    |> Enum.join("\n")
    |> IO.puts()
  end
end
