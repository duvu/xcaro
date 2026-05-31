package chess

import (
	"testing"
)

func TestApplyMoveBasicPawnAdvance(t *testing.T) {
	outcome, err := ApplyMove(StartingFEN, "e2", "e4", "")
	if err != nil {
		t.Fatalf("expected legal pawn advance, got error: %v", err)
	}
	if outcome.GameOver {
		t.Fatalf("expected game not over after e2e4")
	}
	if outcome.NewFEN == StartingFEN {
		t.Fatalf("expected FEN to change after move")
	}
}

func TestApplyMoveIllegalMove(t *testing.T) {
	_, err := ApplyMove(StartingFEN, "e2", "e5", "")
	if err != ErrIllegalMove {
		t.Fatalf("expected ErrIllegalMove, got %v", err)
	}
}

func TestApplyMoveInvalidFEN(t *testing.T) {
	_, err := ApplyMove("not-a-fen", "e2", "e4", "")
	if err != ErrInvalidSquare {
		t.Fatalf("expected ErrInvalidSquare for invalid FEN, got %v", err)
	}
}

func TestApplyMoveCastlingKingside(t *testing.T) {
	// Position after 1.e4 e5 2.Nf3 Nc6 3.Bc4 Bc5 — white can castle kingside
	fen := "r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4"
	outcome, err := ApplyMove(fen, "e1", "g1", "")
	if err != nil {
		t.Fatalf("expected kingside castling to succeed: %v", err)
	}
	if outcome.GameOver {
		t.Fatalf("expected game not over after castling")
	}
}

func TestApplyMovePromotion(t *testing.T) {
	// White pawn on e7, black king far away
	fen := "8/4P3/8/8/8/8/8/k1K5 w - - 0 1"
	outcome, err := ApplyMove(fen, "e7", "e8", "q")
	if err != nil {
		t.Fatalf("expected promotion to succeed: %v", err)
	}
	// After promotion to queen on e8 with lone kings, this should be immediate
	// checkmate or just a won position; either way FEN must differ
	if outcome.NewFEN == fen {
		t.Fatalf("expected FEN to change after promotion")
	}
}

func TestApplyMoveEnPassant(t *testing.T) {
	// White pawn on e5, black just played d7-d5 (en passant possible e5xd6)
	fen := "rnbqkbnr/ppp1pppp/8/3pP3/8/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 3"
	outcome, err := ApplyMove(fen, "e5", "d6", "")
	if err != nil {
		t.Fatalf("expected en passant capture to succeed: %v", err)
	}
	if outcome.GameOver {
		t.Fatalf("expected game not over after en passant")
	}
}

func TestApplyMoveScholarsMate(t *testing.T) {
	// Scholar's mate sequence: 1.e4 e5 2.Qh5 Nc6 3.Bc4 Nf6?? 4.Qxf7#
	moves := []struct{ from, to, prom string }{
		{"e2", "e4", ""},
		{"e7", "e5", ""},
		{"d1", "h5", ""},
		{"b8", "c6", ""},
		{"f1", "c4", ""},
		{"g8", "f6", ""},
		{"h5", "f7", ""},
	}

	fen := StartingFEN
	var outcome MoveOutcome
	var err error
	for _, m := range moves {
		outcome, err = ApplyMove(fen, m.from, m.to, m.prom)
		if err != nil {
			t.Fatalf("expected move %s%s to succeed: %v", m.from, m.to, err)
		}
		fen = outcome.NewFEN
	}
	if !outcome.GameOver {
		t.Fatalf("expected Scholar's mate to end the game")
	}
	if outcome.Winner != "white" {
		t.Fatalf("expected white to win Scholar's mate, got winner=%q", outcome.Winner)
	}
	if outcome.Result != "win" {
		t.Fatalf("expected result=win for Scholar's mate, got %q", outcome.Result)
	}
}

func TestApplyMoveStalemate(t *testing.T) {
	// Classic stalemate position: black king in corner, no legal moves but not in check
	// 8/8/8/8/8/2K5/1Q6/k7 b - - 0 1  (black to move, stalemated)
	fen := "8/8/8/8/8/2K5/1Q6/k7 b - - 0 1"
	// Black has no legal move from starting position; we can't make a "move" into stalemate
	// Instead verify legal moves count is 0
	moves, err := LegalMovesFromFEN(fen)
	if err != nil {
		t.Fatalf("expected LegalMovesFromFEN to succeed: %v", err)
	}
	if len(moves) != 0 {
		t.Fatalf("expected 0 legal moves in stalemate, got %d", len(moves))
	}
}

func TestLegalMovesFromStartingPosition(t *testing.T) {
	moves, err := LegalMovesFromFEN(StartingFEN)
	if err != nil {
		t.Fatalf("expected legal moves from starting FEN: %v", err)
	}
	// 20 legal moves from starting position (16 pawn + 4 knight)
	if len(moves) != 20 {
		t.Fatalf("expected 20 legal moves from starting position, got %d", len(moves))
	}
}

func TestColorToPlay(t *testing.T) {
	color, err := ColorToPlay(StartingFEN)
	if err != nil {
		t.Fatalf("expected ColorToPlay to succeed: %v", err)
	}
	if color != "white" {
		t.Fatalf("expected white to move first, got %q", color)
	}

	// After e2e4, black moves
	outcome, _ := ApplyMove(StartingFEN, "e2", "e4", "")
	color, err = ColorToPlay(outcome.NewFEN)
	if err != nil {
		t.Fatalf("expected ColorToPlay to succeed after first move: %v", err)
	}
	if color != "black" {
		t.Fatalf("expected black to move after e2e4, got %q", color)
	}
}
