---
title: Code Reference
layout: default
nav_order: 3
---

# Code Reference
{: .no_toc }

Per-file documentation for every source file in the project.
{: .fs-6 .fw-300 }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Entry points

| File | Role |
|---|---|
| `lib/main.dart` | Entry point — wraps app in `ProviderScope` |
| `lib/app.dart` | `HexFlipApp` — `MaterialApp` + `_AppLoader` startup widget that loads defaults before showing HomeScreen |

---

## Models (`lib/models/`)

Pure data — no Flutter dependency except `dart:ui` for `Color`. All are JSON-serializable via `fromJson` / `toJson`.

| File | Class / Type | Description |
|---|---|---|
| `models.dart` | — | Barrel export for the entire models directory |
| `card_side.dart` | `CardSide`, `SymbolShape` | Atomic card face value; `SymbolShape` enum: circle \| square \| triangle \| star \| diamond |
| `card_model.dart` | `HexCard`, `PlayerOwner` | 6 sides + mutable `owner`. `flip()` toggles owner. `freshCopy()` resets owner to red |
| `deck_model.dart` | `DeckModel` | Named ordered list of `HexCard` templates |
| `hex_cell.dart` | `AxialCoord`, `HexCell` | `AxialCoord` implements `==` and `hashCode` for use as `Map` key; `HexCell` holds coord, `isActive`, and optional `card` |
| `board_model.dart` | `BoardModel` | `Map<AxialCoord, HexCell>` + `activeCoords` getter + `cleared()` deep-copy helper |
| `player.dart` | `Player` | Hand, deck, score, `draw(count, handLimit)` |
| `game_state.dart` | `GameState`, `FlipEvent`, `GamePhase` | Top-level live container; `scores` computed property; `boardFull` and `bothHandsEmpty` end-of-game checks |
| `rules/game_rules.dart` | `GameRules` | All configurable rule fields (see [Rules](rules)) |
| `rules/attack_eligibility.dart` | `AttackEligibilityRule`, `AttackMode` | `sideCanAttack(side)` predicate |
| `rules/comparison_rule.dart` | `ComparisonRule` | `attackSucceeds(attacker, defender)` predicate |

### AxialCoord directions

```dart
static const List<AxialCoord> directions = [
  AxialCoord( 1, -1), // 0: top-right
  AxialCoord( 1,  0), // 1: right
  AxialCoord( 0,  1), // 2: bottom-right
  AxialCoord(-1,  1), // 3: bottom-left
  AxialCoord(-1,  0), // 4: left
  AxialCoord( 0, -1), // 5: top-left
];
```

---

## Engine (`lib/engine/`)

Stateless business logic — no Flutter imports. All methods are `static` or top-level functions.

### `hex_math.dart` — `HexMath`

Single source of truth for hex geometry.

| Method | Description |
|---|---|
| `neighborAt(origin, sideIndex)` | `AxialCoord` of the neighbor in direction `sideIndex` |
| `oppositeSide(sideIndex)` | `(sideIndex + 3) % 6` |
| `neighborsOf(origin)` | All 6 `({coord, sideIndex})` records |
| `sideRotationRadians(sideIndex)` | `sideIndex * π / 3` — used for UI rendering |
| `hexToPixel(coord, size)` | Flat-top axial → pixel `Offset` |
| `pixelToHex(pixel, size)` | Pixel → nearest `AxialCoord` (cube-rounding) |

### `adjacency_resolver.dart` — `AdjacencyResolver`

`resolve(placedCoord, board, rules)` loops over 6 directions from the placed card:

1. Skip if no cell / inactive / empty / same-owner.
2. Determine attacking side (`placed.sides[d]`) and defending side (`neighbor.sides[(d+3)%6]`).
3. Run `attackEligibility.sideCanAttack(attackerSide)`.
4. Run `comparisonRule.attackSucceeds(attackerSide, defenderSide)`.
5. If both pass: `neighborCell.card!.flip()` (mutates in place).
6. Record an `AdjacencyComparison` for every direction regardless of outcome.

Returns `List<AdjacencyComparison>`. Fields: `attackerCoord`, `defenderCoord`, `attackerSideIndex`, `defenderSideIndex`, `attackerSide`, `defenderSide`, `eligible`, `succeeds`, `flipped`.

### `flip_engine.dart` — `FlipEngine`

Thin orchestrator over `AdjacencyResolver`. Converts `AdjacencyComparison` results into `FlipEvent { cellCoord, from, to }` — the minimal data the UI needs.

`resolve()` returns `FlipResult { comparisons, flipEvents }`.

### `turn_manager.dart` — `TurnManager`

| Method | Description |
|---|---|
| `canPlaceCard(coord, state)` | Cell must exist, be active, and be empty |
| `placeCard(card, coord, state)` | Removes from hand, assigns owner, places on board, runs `FlipEngine`, appends `FlipEvent`s |
| `endTurn(state)` | Switches turn; optionally auto-draws for the new current player |
| `isGameOver(state)` | `true` if board full or both hands empty |
| `computeFinalScores(state)` | Counts board cells; writes to `player.score` |

### `deck_manager.dart` — `DeckManager`

| Method | Description |
|---|---|
| `shuffle(cards)` | Returns a new shuffled list without mutating input |
| `buildPlayer(owner, deckTemplate, rules)` | Creates fresh card copies, assigns owner, shuffles |
| `dealStartingHand(player, rules)` | Draws `startingHandSize` cards respecting `handLimit` |

---

## State (`lib/state/`)

Riverpod `StateNotifier` providers.

| File | Provider / Notifier | Initial State | Purpose |
|---|---|---|---|
| `providers.dart` | `gameRulesProvider` | `GameRules()` defaults | Active rules being edited or used |
| | `activeBoardProvider` | Programmatic Classic 19 | Board being edited or used for next game |
| | `decksProvider` | `{}` | All known decks keyed by id |
| | `gameStateProvider` | `null` | Live game state; null = no game in progress |
| | `setupDeckSelectionProvider` | `(null, null)` | Transient P1/P2 deck selection during setup |
| `game_state_notifier.dart` | `GameStateNotifier` | — | `startGame`, `placeCard`, `endTurn`, `drawCard`, `clearFlipEvents`, `resetGame` |
| `board_notifier.dart` | `BoardNotifier` | — | `loadBoard`, `toggleCell`, `setName`, `clearCards` |
| `decks_notifier.dart` | `DecksNotifier` | — | `addOrUpdateDeck`, `removeDeck`, `loadDecks` |
| `game_rules_notifier.dart` | `GameRulesNotifier` | — | Per-field setters + bulk `update(rules)` |
| `setup_deck_selection_notifier.dart` | `SetupDeckSelectionNotifier` | — | `selectP1Deck`, `selectP2Deck`, `reset` |

**Notification pattern:** `GameStateNotifier` overrides `updateShouldNotify` to always return `true`. The `_notify()` helper temporarily sets state to `null` then restores it, forcing Riverpod to fire change notifications even when the `GameState` object reference is unchanged.

**Default board:** `BoardNotifier` programmatically initialises the Classic 19 board on startup: all cells where `max(|q|, |r|, |q+r|) ≤ 2`. Matches `classic_board.json` exactly.

---

## Screens (`lib/screens/`)

| File | Widget | Description |
|---|---|---|
| `home_screen.dart` | `HomeScreen` | Main menu — four navigation buttons |
| `setup_screen.dart` | `SetupScreen` | Board / deck / rules selection → starts game |
| `game_screen.dart` | `GameScreen` | Game view: board, hand, controls, overlays |
| `card_editor_screen.dart` | `CardEditorScreen` | Two-panel: deck list (left) + 6-side card editor (right) |
| `board_editor_screen.dart` | `BoardEditorScreen` | Hex grid with toggle-cell interaction; range q,r ∈ [−4, 4] |
| `rules_editor_screen.dart` | `RulesEditorScreen` | Form-based editor for all `GameRules` fields |

### GameScreen details

Local state: `_selectedCard`, `_lastComparisons`, `_showComparisonOverlay`.

Layout (`Column` inside `Stack`):
1. `_TopBar` — player scores and current-turn indicator
2. `HexBoardWidget` (expanded) — interactive hex grid
3. `_BottomBar` — Draw and End Turn buttons
4. `HandWidget` — current player's hand

Stack overlays:
- `ComparisonOverlay` — shown after placement when adjacency comparisons exist
- `_GameOverOverlay` — shown when `gameState.phase == GamePhase.ended`

**Preview pattern:** `_previewAdjacency(...)` is a read-only mirror of `AdjacencyResolver` that does not call `flip()`. This gives comparison data to the overlay without causing a double-resolution side effect.

---

## Widgets (`lib/widgets/`)

| File | Widget | Description |
|---|---|---|
| `app_colors.dart` | `AppColors` | All UI colors as `static const Color` — dark purple-navy theme |
| `hex_board_widget.dart` | `HexBoardWidget`, `_BoardPainter` | `InteractiveViewer` (pan/zoom 0.5–3.0) + `CustomPaint`. Renders fill, borders, side symbols, center dot. Tap → `pixelToHex` → `onCellTapped` |
| `hex_card_widget.dart` | `HexCardWidget`, `_HexCardPainter` | Single card in `size*2 × size*2` bounding box. Supports `isSelected` (yellow border) and `isSmall` (skips side symbols) |
| `hand_widget.dart` | `HandWidget` | Horizontal `ListView.separated`, 120 px height. Shows hand size and deck count |
| `comparison_overlay.dart` | `ComparisonOverlay` | Full-screen semi-transparent modal. One row per `AdjacencyComparison`: attacker ↔ result icon ↔ defender |

`_drawShape` in `_HexCardPainter` handles: circle (`drawCircle`), square (`drawRect`), triangle (3-point path), star (10-point alternating outer/inner radius path), diamond (4-point path).

---

## Persistence (`lib/persistence/`)

`StorageService` uses `path_provider` to locate the app documents directory.

```
<appDocDir>/hexflip/
  decks/<id>.json
  boards/<id>.json
  rules/<name>.json
```

| Method | Description |
|---|---|
| `saveDeck(deck)` | Writes `decks/<id>.json` |
| `loadDeck(id)` | Returns null if missing or malformed |
| `loadAllDecks()` | Scans decks dir; skips malformed files |
| `deleteDeck(id)` | Deletes file silently |
| `saveBoard / loadBoard / loadAllBoards / deleteBoard` | Analogous board methods |
| `saveRules(rules, name)` | Writes `rules/<name>.json` |
| `loadRules(name)` | Returns null if missing |
| `loadDefaultDeck(assetName)` | Reads from `assets/configs/` via `rootBundle` |
| `loadDefaultBoard(assetName)` | Same |
| `loadDefaultRules()` | Loads `assets/configs/default_rules.json` |

**Startup sequence (`_AppLoader._loadDefaults`):**

1. Load all decks from disk. If none → fall back to `default_deck.json` asset.
2. Load rules with key `'last_rules'`. If none → load `default_rules.json` asset.
3. Load saved boards. If any → use first as active board.
4. Set `_loaded = true` → show HomeScreen.

---

## Asset configuration files (`assets/configs/`)

| File | Description |
|---|---|
| `default_deck.json` | 10 cards (`c1`–`c10`), each with 6 sides using all 5 shapes and numbers 1–9 |
| `classic_board.json` | 19-cell board: center + two rings. Condition: `max(|q|, |r|, |q+r|) ≤ 2` |
| `small_board.json` | 7-cell board: center + one ring. Condition: `max(|q|, |r|, |q+r|) ≤ 1` |
| `default_rules.json` | Hand=5, draw=1, limit=7, deck=10, allSides, numberGreater only |

---

## Dependencies

### Runtime

| Package | Purpose |
|---|---|
| `flutter_riverpod ^2.4.9` | State management — typed providers, no `BuildContext` threading |
| `uuid ^4.3.3` | UUID v4 for `HexCard.id` and `DeckModel.id` |
| `collection ^1.18.0` | Extended collection utilities |
| `path_provider ^2.1.2` | App documents directory for JSON persistence |
| `shared_preferences ^2.2.2` | Declared; not currently used — file JSON is used instead |

### Dev

| Package | Purpose |
|---|---|
| `flutter_lints ^3.0.0` | Linting rules |
| `mocktail ^1.0.2` | Mock objects for unit tests (available; not yet used) |
| `riverpod_generator ^2.3.9` | Riverpod code gen (available; not currently used) |
| `build_runner ^2.4.8` | Build system for code gen (available; not currently used) |

---

## Test coverage

`test/widget_test.dart` is the default Flutter scaffold test. It references `MyApp` which does not exist in HexFlip — it is a leftover placeholder and will fail as-is.

Engine functions (`hex_math.dart`, `adjacency_resolver.dart`, `flip_engine.dart`, `turn_manager.dart`, `deck_manager.dart`) are all pure / static and highly testable without Flutter infrastructure. `mocktail` is ready for future unit test development.
