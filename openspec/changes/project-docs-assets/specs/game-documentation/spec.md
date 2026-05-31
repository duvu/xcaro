## ADDED Requirements

### Requirement: Gomoku Game Rules Document
The project SHALL include a user-facing markdown document explaining Gomoku rules and PlayVerse game features.

#### Scenario: Rules file present at root
- **WHEN** a user visits the repository or accesses the in-app help
- **THEN** `GAME_RULES.md` exists at the repo root and covers: objective, board layout, how to place a stone, win condition (5 in a row), draw condition, and UI controls for PlayVerse

---

### Requirement: Architecture Documentation
The project SHALL include a developer-facing architecture overview document.

#### Scenario: Architecture document present
- **WHEN** a developer opens `docs/architecture.md`
- **THEN** the document covers: system overview diagram (text/ASCII), Flutter client architecture (Provider state, screen hierarchy, WS lifecycle), Go server architecture (Gin routes, WS hub, MongoDB collections), JWT auth flow, and Elo rating system design

---

### Requirement: API Reference Document
The project SHALL include a concise REST API reference listing all endpoints.

#### Scenario: API reference present
- **WHEN** a developer opens `docs/api.md`
- **THEN** the document lists every endpoint: method, path, auth requirement, request body shape, and response shape; covers auth, games, leaderboard, user profile endpoints
