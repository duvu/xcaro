package elo

import "math"

const K = 32

// Calculate returns new ratings for A and B.
// result: 1.0 = A wins, 0.0 = B wins, 0.5 = draw
func Calculate(ratingA, ratingB int, result float64) (newA, newB int) {
	ea := 1.0 / (1.0 + math.Pow(10, float64(ratingB-ratingA)/400.0))
	eb := 1.0 - ea
	newA = ratingA + int(math.Round(K*(result-ea)))
	newB = ratingB + int(math.Round(K*((1-result)-eb)))
	return
}
