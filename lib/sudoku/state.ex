defmodule Sudoku.State do
  alias Sudoku.{Game, State}

  defstruct status: :initial,
            player: nil,
            winner: false,
            board: Game.new(),
            solved: false,
            ui: nil

  def new, do: {:ok, %State{}}
  def new(ui), do: {:ok, %State{ui: ui}}

  def event(%State{status: :initial} = state, {:start_game}) do
    {:ok, %State{state | status: :playing}}
  end

  def event(%State{status: :playing} = state, {:board_solved?, board}) do
    solved_or_not = Game.solved?(board)

    case solved_or_not do
      true -> {:ok, %State{state | status: :game_over, winner: :true, solved: :true}}
      _    -> {:ok, state}
    end
  end

  def event(state, action) do
    {:error, {:invalid_state_action, %{status: state.status, action: action}}}
  end
end
