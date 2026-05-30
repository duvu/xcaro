package metrics

import "sync/atomic"

// Metrics holds atomic counters for operational observability.
type Metrics struct {
	ActiveWsConnections int64
	TotalGamesCreated   int64
	TotalMovesMade      int64
	ActiveQueueSize     int64
	HttpRequestsTotal   int64
}

var global Metrics

// Get returns the global Metrics instance.
func Get() *Metrics { return &global }

func (m *Metrics) IncConnections()        { atomic.AddInt64(&m.ActiveWsConnections, 1) }
func (m *Metrics) DecConnections()        { atomic.AddInt64(&m.ActiveWsConnections, -1) }
func (m *Metrics) IncGames()              { atomic.AddInt64(&m.TotalGamesCreated, 1) }
func (m *Metrics) IncMoves()              { atomic.AddInt64(&m.TotalMovesMade, 1) }
func (m *Metrics) SetQueueSize(n int64)   { atomic.StoreInt64(&m.ActiveQueueSize, n) }
func (m *Metrics) IncRequests()           { atomic.AddInt64(&m.HttpRequestsTotal, 1) }

// Snapshot returns a copy of current metric values.
func (m *Metrics) Snapshot() map[string]int64 {
	return map[string]int64{
		"active_ws_connections": atomic.LoadInt64(&m.ActiveWsConnections),
		"total_games_created":   atomic.LoadInt64(&m.TotalGamesCreated),
		"total_moves_made":      atomic.LoadInt64(&m.TotalMovesMade),
		"active_queue_size":     atomic.LoadInt64(&m.ActiveQueueSize),
		"http_requests_total":   atomic.LoadInt64(&m.HttpRequestsTotal),
	}
}
