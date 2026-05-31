package chess

import (
	"errors"
	"strings"

	"github.com/notnil/chess"
)

// StartingFEN is the FEN string for the standard chess starting position.
const StartingFEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

// ErrInvalidSquare is returned when the from or to square is not a valid chess square.
var ErrInvalidSquare = errors.New("invalid square")

// ErrIllegalMove is returned when the attempted move is not legal in the current position.
var ErrIllegalMove = errors.New("illegal move")

// MoveOutcome holds the result of a successfully applied chess move.
type MoveOutcome struct {
	// NewFEN is the FEN after the move is applied.
	NewFEN string
	// GameOver is true when the game has ended.
	GameOver bool
	// Winner is "white", "black", or "" for draw.
	Winner string
	// Result is "win", "draw", or "" for ongoing game.
	Result string
}

// ApplyMove applies a chess move expressed in UCI notation (e.g. "e2e4", "e7e8q") to the
// position described by fen. It returns the new FEN, the outcome, and any error.
// player is 1 for white, 2 for black.
func ApplyMove(fen, from, to, promotion string) (MoveOutcome, error) {
	game, err := gameFromFEN(fen)
	if err != nil {
		return MoveOutcome{}, ErrInvalidSquare
	}

	uci := from + to
	if promotion != "" {
		uci += strings.ToLower(promotion[:1])
	}

	var matched *chess.Move
	for _, m := range game.ValidMoves() {
		if m.String() == uci {
			matched = m
			break
		}
	}
	if matched == nil {
		return MoveOutcome{}, ErrIllegalMove
	}

	if err := game.Move(matched); err != nil {
		return MoveOutcome{}, ErrIllegalMove
	}

	newFEN := game.FEN()
	outcome := game.Outcome()

	if outcome == chess.NoOutcome {
		return MoveOutcome{NewFEN: newFEN}, nil
	}

	result := MoveOutcome{NewFEN: newFEN, GameOver: true}
	switch outcome {
	case chess.WhiteWon:
		result.Winner = "white"
		result.Result = "win"
	case chess.BlackWon:
		result.Winner = "black"
		result.Result = "win"
	default:
		result.Result = "draw"
	}
	return result, nil
}

// LegalMovesFromFEN returns all legal moves for the current position in UCI notation.
func LegalMovesFromFEN(fen string) ([]string, error) {
	game, err := gameFromFEN(fen)
	if err != nil {
		return nil, ErrInvalidSquare
	}
	moves := game.ValidMoves()
	uciMoves := make([]string, 0, len(moves))
	for _, m := range moves {
		uciMoves = append(uciMoves, m.String())
	}
	return uciMoves, nil
}

// ColorToPlay returns "white" or "black" for the side to move in the given FEN.
func ColorToPlay(fen string) (string, error) {
	game, err := gameFromFEN(fen)
	if err != nil {
		return "", ErrInvalidSquare
	}
	if game.Position().Turn() == chess.White {
		return "white", nil
	}
	return "black", nil
}

// gameFromFEN parses a FEN string into a chess.Game.
func gameFromFEN(fen string) (*chess.Game, error) {
	fenOption, err := chess.FEN(fen)
	if err != nil {
		return nil, err
	}
	game := chess.NewGame(fenOption)
	return game, nil
}
