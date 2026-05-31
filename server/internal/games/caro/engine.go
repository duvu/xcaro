package caro

import "errors"

const (
	GameType     = "caro"
	BoardSize    = 15
	WinCondition = 5
)

var (
	ErrInvalidCoordinates = errors.New("invalid_coordinates")
	ErrCellOccupied       = errors.New("cell_occupied")
)

type MoveOutcome struct {
	WinningCells [][]int
	Draw         bool
}

func ApplyMove(board *[BoardSize][BoardSize]int, player, x, y int) (MoveOutcome, error) {
	if x < 0 || x >= BoardSize || y < 0 || y >= BoardSize {
		return MoveOutcome{}, ErrInvalidCoordinates
	}
	if board[x][y] != 0 {
		return MoveOutcome{}, ErrCellOccupied
	}

	board[x][y] = player
	winningCells, won := checkWin(*board, player)
	if won {
		return MoveOutcome{WinningCells: winningCells}, nil
	}
	if isDraw(*board) {
		return MoveOutcome{Draw: true}, nil
	}
	return MoveOutcome{}, nil
}

func checkWin(board [BoardSize][BoardSize]int, player int) ([][]int, bool) {
	dirs := [][2]int{{0, 1}, {1, 0}, {1, 1}, {1, -1}}
	for _, d := range dirs {
		dx, dy := d[0], d[1]
		for x := 0; x < BoardSize; x++ {
			for y := 0; y < BoardSize; y++ {
				if board[x][y] != player {
					continue
				}
				count := 1
				for k := 1; k < WinCondition; k++ {
					nx, ny := x+k*dx, y+k*dy
					if nx < 0 || nx >= BoardSize || ny < 0 || ny >= BoardSize {
						break
					}
					if board[nx][ny] != player {
						break
					}
					count++
				}
				if count >= WinCondition {
					cells := make([][]int, 0, WinCondition)
					for k := 0; k < WinCondition; k++ {
						cells = append(cells, []int{x + k*dx, y + k*dy})
					}
					return cells, true
				}
			}
		}
	}
	return nil, false
}

func isDraw(board [BoardSize][BoardSize]int) bool {
	for x := 0; x < BoardSize; x++ {
		for y := 0; y < BoardSize; y++ {
			if board[x][y] == 0 {
				return false
			}
		}
	}
	return true
}
