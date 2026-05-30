package elo

import "testing"

func TestCalculate_Win(t *testing.T) {
	newA, newB := Calculate(1200, 1200, 1.0)
	if newA <= 1200 {
		t.Errorf("winner should gain rating, got %d", newA)
	}
	if newB >= 1200 {
		t.Errorf("loser should lose rating, got %d", newB)
	}
}

func TestCalculate_Loss(t *testing.T) {
	newA, newB := Calculate(1200, 1200, 0.0)
	if newA >= 1200 {
		t.Errorf("loser should lose rating, got %d", newA)
	}
	if newB <= 1200 {
		t.Errorf("winner should gain rating, got %d", newB)
	}
}

func TestCalculate_Draw(t *testing.T) {
	newA, newB := Calculate(1200, 1200, 0.5)
	if newA != 1200 {
		t.Errorf("equal draw should not change A, got %d", newA)
	}
	if newB != 1200 {
		t.Errorf("equal draw should not change B, got %d", newB)
	}
}

func TestCalculate_UnequalRatings(t *testing.T) {
	newA, newB := Calculate(1400, 1200, 1.0)
	if newA-1400 >= 16 {
		t.Errorf("high rated winner gains too much: %d", newA-1400)
	}
	if 1200-newB >= 16 {
		t.Errorf("low rated loser loses too much: %d", 1200-newB)
	}
}
