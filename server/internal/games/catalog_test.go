package games

import "testing"

func TestNormalizeGameTypeDefaultsToCaro(t *testing.T) {
	if got := NormalizeGameType(""); got != GameTypeCaro {
		t.Fatalf("expected default game type %q, got %q", GameTypeCaro, got)
	}
	if got := NormalizeGameType("  CARO "); got != GameTypeCaro {
		t.Fatalf("expected normalized game type %q, got %q", GameTypeCaro, got)
	}
}

func TestDefaultCatalogContainsCaro(t *testing.T) {
	catalog := DefaultCatalog()
	if len(catalog) == 0 {
		t.Fatalf("expected non-empty default catalog")
	}
	if catalog[0].GameType != GameTypeCaro {
		t.Fatalf("expected first catalog entry to be %q, got %q", GameTypeCaro, catalog[0].GameType)
	}
	if !catalog[0].SupportsOnline || !catalog[0].SupportsOffline || !catalog[0].SupportsAI {
		t.Fatalf("expected Caro catalog entry to advertise current supported modes: %#v", catalog[0])
	}
}

func TestDefaultCatalogContainsChess(t *testing.T) {
	catalog := DefaultCatalog()
	var chessEntry *CatalogEntry
	for i := range catalog {
		if catalog[i].GameType == GameTypeChess {
			chessEntry = &catalog[i]
			break
		}
	}
	if chessEntry == nil {
		t.Fatalf("expected chess entry in default catalog, got %#v", catalog)
	}
	if !chessEntry.SupportsOnline || !chessEntry.SupportsOffline || !chessEntry.SupportsAI {
		t.Fatalf("expected chess catalog entry to support online/offline/AI: %#v", chessEntry)
	}
}

func TestIsSupportedGameTypeChess(t *testing.T) {
	if !IsSupportedGameType(GameTypeChess) {
		t.Fatalf("expected chess to be a supported game type")
	}
	if !IsSupportedGameType("CHESS") {
		t.Fatalf("expected chess (uppercase) to be normalized and supported")
	}
	if IsSupportedGameType("checkers") {
		t.Fatalf("expected checkers to be unsupported")
	}
}

