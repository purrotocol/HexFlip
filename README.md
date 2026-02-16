# HexFlip

A modular hex-based card game playtesting sandbox built with Flutter. Place cards on a hexagonal grid, resolve adjacency comparisons, and flip neighboring cards based on configurable rules.

**Targets:** Linux desktop · Windows desktop · Web

---

## What it is

HexFlip is a flexible mechanics testbed — not a finished game. The goal is fast iteration on card game rules without touching code. Everything that matters (card values, board shape, attack logic, comparison conditions) is driven by data.

Two players alternate placing cards from their hands onto a hex grid. When a card is placed, each of its six sides is compared against the adjacent face of any neighboring card. If the attacker wins the comparison, the neighbor flips to the active player's ownership. The player with the most cells at the end wins.

---

## Gameplay

```
┌─────────────────────────────────────────────────────┐
│  P1: 7 cells    HexFlip    P2: 12 cells  [P2 turn]  │
├─────────────────────────────────────────────────────┤
│                                                     │
│              ⬡  ⬡  ⬡                               │
│            ⬡  ⬡  ⬡  ⬡                             │
│          ⬡  ⬡  ●  ⬡  ⬡                            │
│            ⬡  ⬡  ⬡  ⬡                             │
│              ⬡  ⬡  ⬡                               │
│                                                     │
├─────────────────────────────────────────────────────┤
│  Hand: [▲3][●7][■2][★5][◆4][▲8][●1]               │
│  Deck: 3 remaining           [Draw] [End Turn]      │
└─────────────────────────────────────────────────────┘
```

Each hexagonal card has **6 sides**, one facing each neighbor direction. Each side has a **shape**, **number (1–9)**, and **color**. The comparison logic (number greater? shape match required? color match required?) is fully configurable.

After placing a card, an overlay shows every adjacency comparison — which sides fought, who won, and which cards flipped.

---

## Features

- **Hex grid board** — flat-top axial coordinates, pan/zoom support, Classic 19-cell and Small 7-cell layouts
- **Card editor** — create and edit decks with per-side shape, number, and color
- **Board editor** — toggle cells on/off to design custom board shapes (range ±4)
- **Rules editor** — configure hand size, draw rate, attack eligibility mode, and comparison conditions without touching code
- **Comparison overlay** — post-placement breakdown of every attacker/defender matchup
- **Flip highlighting** — green border on flipped cells, yellow on selected target
- **Data-driven persistence** — decks, boards, and rules saved as JSON under the app documents directory

---

## Architecture

```
UI (screens/ + widgets/)
        │
   Riverpod state (state/)
        │
    Engine (engine/)          ← no Flutter dependency
        │
    Models (models/)          ← pure Dart + dart:ui Color
        │
  Persistence (persistence/)
```

The engine layer is entirely stateless and Flutter-free. `AdjacencyResolver`, `FlipEngine`, `TurnManager`, and `DeckManager` are all static methods operating on plain model objects — straightforward to unit test.

State is managed with Riverpod `StateNotifier`. `GameState` is mutated in-place by the engine; the notifier uses a null-swap trick to force Riverpod to fire change notifications even when the object reference is unchanged.

### Key files

| Path | Role |
|---|---|
| `lib/engine/adjacency_resolver.dart` | Core flip logic — 6-direction comparison loop |
| `lib/engine/hex_math.dart` | All hex geometry: pixel↔axial, neighbors, side angles |
| `lib/state/game_state_notifier.dart` | Bridges UI actions to engine calls |
| `lib/screens/game_screen.dart` | Game UI, preview-before-mutate pattern |
| `lib/widgets/hex_board_widget.dart` | CustomPainter board renderer |
| `lib/persistence/storage_service.dart` | JSON file I/O under `<appDocDir>/hexflip/` |
| `assets/configs/` | Default deck, boards, and rules as JSON |

### Hex coordinate system

Axial coordinates (q, r), flat-top layout. Side index 0 = top-right, clockwise to 5 = top-left. Opposing side is always `(i + 3) % 6`.

---

## Building

**Prerequisites:** Flutter 3.10+, Dart 3.0+

```bash
# Get dependencies
flutter pub get

# Run (Linux)
flutter run -d linux

# Run (web)
flutter run -d chrome

# Release builds
flutter build linux
flutter build windows    # Windows host required
flutter build web
```

---

## Rules configuration

The default rules (`assets/configs/default_rules.json`):

```json
{
  "startingHandSize": 5,
  "cardsDrawnPerTurn": 1,
  "handLimit": 7,
  "deckSize": 10,
  "autoDrawEnabled": true,
  "attackEligibility": { "mode": "allSides" },
  "comparison": {
    "requireNumberGreater": true,
    "allowEqual": false,
    "requireShapeMatch": false,
    "requireColorMatch": false
  }
}
```

All of these fields are editable in the Rules Editor at runtime and persisted per-session.

**Attack eligibility modes:**
- `allSides` — every side can attack
- `specificSides` — only whitelisted side indices
- `excludeSides` — all sides except blacklisted indices

**Comparison conditions** (any combination):
- Number must be strictly greater (or allow equal)
- Shape must match
- Color must match
- Both shape and color must match

---

## Project status

This is a playtesting tool in active development. Current known gaps:

- Save buttons in the Rules, Board, and Card editors update in-memory state but do not yet write to disk — changes are lost on restart
- The default test file (`test/widget_test.dart`) is a Flutter scaffold placeholder and will fail
- `shared_preferences` is declared but unused; all persistence uses JSON files

---

## License

MIT
