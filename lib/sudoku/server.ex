defmodule Sudoku.Server do
  use GenServer

  alias Sudoku.{Game, State}

  @name :sudoku_server

  def start do
    IO.puts "Starting the sudoku server..."
    GenServer.start(__MODULE__, %State{}, name: @name)
  end

  def start_game do
    GenServer.call @name, :start_game
  end

  def get_input do
    GenServer.call @name, :get_input, 60_000
  end

  def report_winner do
    GenServer.call @name, :report_winner
  end

  def board_solved?(board) do
    GenServer.call @name, {:board_solved?, board}
  end

  def play(%State{status: :game_over}) do
    report_winner()
  end

  def play(state) do
    {pos, guess} = get_input()
    {message, updated_board} = Game.play_at(state.board, pos, guess)

    wrong_pos_list =
    case {message, updated_board} do
      {:wrong_guess, _} -> add_wrong_pos(state, pos)
      {:correct_guess, _} -> remove_wrong_pos(state, pos)
      {_, _} -> state.wrong_pos_filled
    end

    partial_state = board_solved?(updated_board)

    IO.puts("#{IO.ANSI.yellow()}#{message}#{IO.ANSI.reset()}")

    new_state = %State{partial_state | wrong_pos_filled: wrong_pos_list}

    IO.puts("#{IO.ANSI.red()}Wrong positions filled: #{inspect new_state.wrong_pos_filled}#{IO.ANSI.reset()}")

    play(new_state)
  end

  def add_wrong_pos(state, pos) do
    case pos in state.wrong_pos_filled do
      false -> [ pos | state.wrong_pos_filled]
      true -> state.wrong_pos_filled
    end
  end

  def remove_wrong_pos(state, pos) do
    case pos in state.wrong_pos_filled do
      true -> List.delete(state.wrong_pos_filled, pos)
      false -> state.wrong_pos_filled
    end
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call(:start_game, _from, %State{status: :initial} = state) do
    new_state = %State{state | status: :playing}
    {:reply, new_state, new_state}
  end

  def handle_call(:get_input, _from, %State{status: :playing} = state) do
    display(state.board)

    IO.puts("What position to fill?")
    pos = IO.gets("Position: ") |> String.trim |> String.to_integer
    IO.puts("With what number?")
    guess = IO.gets("Guess: ") |> String.trim |> String.to_integer

    {:reply, {pos, guess}, state}
  end

  def handle_call({:board_solved?, updated_board}, _from, %State{status: :playing} = state) do
    solved_or_not = Game.solved?(updated_board)

    case solved_or_not do
      true ->
        new_state = %State{state | status: :game_over, winner: true, board: updated_board}
        {:reply, new_state, new_state}
      _    ->
        new_state = %State{state | board: updated_board}
        {:reply, new_state, new_state}
    end
  end

  def handle_call(:report_winner, _from, %State{status: :game_over} = state) do
    IO.puts("#{IO.ANSI.green()}You Won!")
    {:reply, display(state.board), state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  defp display(board) do
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
