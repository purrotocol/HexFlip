# HexFlip — Session Memory

**Project path:** `/home/bas/HexFlip`
**Language:** Dart / Flutter
**Purpose:** Modular hex-based card game playtesting sandbox
**Platforms:** Linux desktop, Windows desktop, Web

---

## Critical Architecture Facts

### Layer Ordering (strictly respected)
```
UI (screens/ widgets/) → State (state/) → Engine (engine/) → Models (models/) → Persistence (persistence/)
```
Engine layer has NO Flutter imports except `dart:math` and `package:flutter/painting.dart` (for `Offset`).
Models have no Flutter dependency except `dart:ui` for `Color`.

### State Management
- Riverpod `StateNotifier` pattern. No code-gen (annotations declared but unused).
- `GameState` is **mutable** — fields mutated in-place by engine.
- `GameStateNotifier` overrides `updateShouldNotify` to always return `true` and uses a null-swap trick in `_notify()` to force listener rebuild even with same object reference.
- Provider file: `/home/bas/HexFlip/lib/state/providers.dart`
- Barrel: `/home/bas/HexFlip/lib/state/state.dart`

### The Five Providers
| Provider | State type | Purpose |
|---|---|---|
| `gameRulesProvider` | `GameRules` | Active rules |
| `activeBoardProvider` | `BoardModel` | Active board (editor + game) |
| `decksProvider` | `Map<String, DeckModel>` | All saved decks |
| `gameStateProvider` | `GameState?` | Live game; null = no game |
| `setupDeckSelectionProvider` | `({String? p1DeckId, String? p2DeckId})` | Setup flow only |

---

## Core Invariants (never violate)

1. **`HexCard.owner` is the ONLY mutable field on a card.** `sides` is final.
2. **`sides[i]` faces `AxialCoord.directions[i]`.** Index 0 = top-right, clockwise. Never changes.
3. **Opposing side = `(i + 3) % 6`.** Side 0 opposes side 3, side 1 opposes side 4, etc.
4. **Flip = owner toggle only.** No geometric transformation, no side reassignment.
5. **Flat-top hex layout throughout.** `x = size * (3/2 * q)`, `y = size * (sqrt(3)/2 * q + sqrt(3) * r)`.
6. **All rules are data-driven.** `GameRules`, `AttackEligibilityRule`, `ComparisonRule` are plain JSON-serializable objects.

---

## Key File Locations

| File | Role |
|---|---|
| `/home/bas/HexFlip/lib/main.dart` | Entry point — `ProviderScope(child: HexFlipApp())` |
| `/home/bas/HexFlip/lib/app.dart` | `HexFlipApp` MaterialApp + `_AppLoader` startup |
| `/home/bas/HexFlip/lib/models/hex_cell.dart` | `AxialCoord` (with directions array) + `HexCell` |
| `/home/bas/HexFlip/lib/engine/hex_math.dart` | All hex geometry: neighbor, opposite, pixel conversions, rotation |
| `/home/bas/HexFlip/lib/engine/adjacency_resolver.dart` | Core flip logic — mutates board in-place |
| `/home/bas/HexFlip/lib/engine/flip_engine.dart` | Wraps adjacency results into FlipResult/FlipEvent |
| `/home/bas/HexFlip/lib/engine/turn_manager.dart` | Turn lifecycle: placeCard, endTurn, isGameOver |
| `/home/bas/HexFlip/lib/state/game_state_notifier.dart` | Bridges UI → engine; mutable-state notify pattern |
| `/home/bas/HexFlip/lib/screens/game_screen.dart` | Game UI; contains `_previewAdjacency` for read-only preview |
| `/home/bas/HexFlip/lib/widgets/hex_board_widget.dart` | Board renderer via CustomPainter |
| `/home/bas/HexFlip/lib/widgets/app_colors.dart` | Single source of truth for all colors |
| `/home/bas/HexFlip/lib/persistence/storage_service.dart` | File I/O under `<appDoc>/hexflip/` |
| `/home/bas/HexFlip/assets/configs/default_deck.json` | 10-card bundled deck |
| `/home/bas/HexFlip/assets/configs/default_rules.json` | Default rules (deck=10, hand=5, allSides, numberGreater) |
| `/home/bas/HexFlip/DESIGN.md` | Original pre-implementation design doc |
| `/home/bas/HexFlip/INDEX.md` | Comprehensive project index (generated 2026-02-16) |

---

## Placement Flow (important to understand for any game logic changes)

```
GameScreen._onCellTapped(coord)
  ↓
_previewAdjacency(...)   ← read-only, NO mutation, captures comparisons for overlay
  ↓
gameStateProvider.notifier.placeCard(card, coord)
  ↓
TurnManager.placeCard → FlipEngine.resolve → AdjacencyResolver.resolve
  (mutates board.cells[coord].card and neighbor card owners in-place)
  ↓
_notify() forces Riverpod rebuild
  ↓
ComparisonOverlay shown if comparisons.isNotEmpty
  ↓
User dismisses → clearFlipEvents() → green flip highlights clear
```

**Why the preview pattern?** If comparisons were read from game state after mutation, the flip flags would already be set. The preview runs before mutation to capture pre-flip attacker/defender data cleanly.

---

## Persistence Layout

```
<getApplicationDocumentsDirectory()>/hexflip/
  decks/<id>.json      — DeckModel
  boards/<id>.json     — BoardModel
  rules/<name>.json    — GameRules  (key 'last_rules' for auto-save)
```

Default assets served via `rootBundle.loadString('assets/configs/<name>')`.

Startup loads: saved decks (fallback to default_deck.json) → saved rules (fallback to default_rules.json) → saved boards.

---

## Known Issues / Technical Debt

1. **`test/widget_test.dart`** references `MyApp` which does not exist. Test will fail. No meaningful tests written yet.
2. **`shared_preferences`** is in pubspec but unused. File-based JSON is used for all persistence.
3. **`riverpod_generator` / `build_runner`** are in dev-deps but code-gen is not used. Providers are hand-written.
4. **`RulesEditorScreen` Save button** shows a SnackBar but does not call `StorageService.saveRules()`. Rules are only loaded from disk on startup, not written back on editor save.
5. **`BoardEditorScreen` Save** updates the board name in state but does not call `StorageService.saveBoard()`. Board changes are in-memory only until the app restarts and reloads from disk (which would not include unsaved boards).
6. **`decksProvider` changes** from the Card Editor are not automatically persisted — `_saveDeck()` updates the Riverpod state but does not call `StorageService.saveDeck()`. Deck edits are lost on app restart.

---

## Shapes and Numbers

**SymbolShape enum:** `circle`, `square`, `triangle`, `star`, `diamond`

**Number range:** 1–9 (enforced in the card editor UI via `_NumberField` clamp; not enforced in the model itself).

**Color picker:** 12 preset colors in both CardEditorScreen and RulesEditorScreen:
black, white, red, blue, green, yellow, orange, purple, cyan, pink, gray, brown.

---

## Board Layouts

| Board | Cells | Condition |
|---|---|---|
| Classic 19 | 19 | `max(|q|, |r|, |q+r|) ≤ 2` |
| Small 7 | 7 | `max(|q|, |r|, |q+r|) ≤ 1` |
| Custom | any | Toggle in BoardEditorScreen, range ±4 |

`BoardNotifier` defaults to Classic 19 (programmatically generated, matches `classic_board.json`).

---

## Theme

Dark navy/purple. Accent color: `#4CC9F0` (cyan). Player colors: muted red `#8B2020` (P1) and muted blue `#1A4A8A` (P2). Flip highlight: `#00FF88` (green). Selection highlight: `#FFCC00` (yellow).
