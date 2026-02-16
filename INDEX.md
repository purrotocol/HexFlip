# HexFlip — Project Index

**Version:** 1.0.0+1
**Platform:** Flutter (Dart) — Desktop (Linux, Windows) and Web
**Purpose:** A modular, data-driven hex-based card game playtesting sandbox. No polish, no art — pure mechanics iteration.
**Last updated:** 2026-02-16

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture Overview](#2-architecture-overview)
3. [Directory Structure](#3-directory-structure)
4. [Core Data Models](#4-core-data-models)
5. [Engine Layer (Business Logic)](#5-engine-layer-business-logic)
6. [State Management](#6-state-management)
7. [Screens](#7-screens)
8. [Widgets](#8-widgets)
9. [Persistence Layer](#9-persistence-layer)
10. [Asset Configuration Files](#10-asset-configuration-files)
11. [Dependencies](#11-dependencies)
12. [Build Targets](#12-build-targets)
13. [Key Design Constraints](#13-key-design-constraints)
14. [Data Flow — Card Placement Sequence](#14-data-flow--card-placement-sequence)
15. [Hex Coordinate System](#15-hex-coordinate-system)
16. [Color Palette](#16-color-palette)
17. [Test Coverage](#17-test-coverage)

---

## 1. Project Overview

HexFlip is a Flutter/Dart playtesting tool for a configurable hexagonal card game. Two players take turns placing hex cards on a hex-grid board. When a card is placed, its six sides face each adjacent occupied cell. If a side's attributes beat the opposing neighbor's facing side (per the configured comparison rules), that neighbor card flips ownership.

The game ends when the board is full or both hands are empty. Whoever owns more cells wins.

**Design priorities (in order):**
- Flexibility and modularity above all else
- Data-driven rule system — no hard-coded assumptions
- Clean adjacency comparison engine
- Fast iteration for playtesting

**Out of scope (intentionally):**
- AI opponent
- Network multiplayer
- Complex animations (only color transitions and highlights)
- Card art, titles, or asymmetric card faces
- Sound effects

---

## 2. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│  UI Layer (screens/ + widgets/)                                 │
│    ConsumerWidget / ConsumerStatefulWidget (flutter_riverpod)   │
│    reads/writes providers via ref.watch / ref.read              │
└─────────────────────────┬───────────────────────────────────────┘
                          │ Riverpod providers
┌─────────────────────────▼───────────────────────────────────────┐
│  State Layer (state/)                                           │
│    StateNotifier subclasses exposing typed public methods       │
│    GameStateNotifier, BoardNotifier, DecksNotifier,             │
│    GameRulesNotifier, SetupDeckSelectionNotifier                │
└─────────────────────────┬───────────────────────────────────────┘
                          │ direct method calls
┌─────────────────────────▼───────────────────────────────────────┐
│  Engine Layer (engine/)                                         │
│    Stateless pure functions / static methods                    │
│    HexMath, AdjacencyResolver, FlipEngine, TurnManager,         │
│    DeckManager                                                  │
└─────────────────────────┬───────────────────────────────────────┘
                          │ operate on
┌─────────────────────────▼───────────────────────────────────────┐
│  Model Layer (models/)                                          │
│    Pure Dart data classes, all JSON-serializable                │
│    CardSide, HexCard, DeckModel, HexCell, AxialCoord,           │
│    BoardModel, Player, GameState, GameRules (+ sub-rules)       │
└─────────────────────────┬───────────────────────────────────────┘
                          │ loaded/saved by
┌─────────────────────────▼───────────────────────────────────────┐
│  Persistence Layer (persistence/)                               │
│    StorageService — file I/O and bundled asset loading          │
└─────────────────────────────────────────────────────────────────┘
```

**State management pattern:** Riverpod `StateNotifier` providers. `GameState` is a mutable object; `GameStateNotifier` overrides `updateShouldNotify` to always return `true` and uses a null-swap trick to force listeners to fire even when the object reference is unchanged.

**Navigation:** Simple Flutter `Navigator.push` / `Navigator.pushReplacement`. No named routes, no Router. Screen flow: HomeScreen → SetupScreen → GameScreen. Editors are modal pushes from HomeScreen.

---

## 3. Directory Structure

```
/home/bas/HexFlip/
├── lib/
│   ├── main.dart                    # Entry point — wraps app in ProviderScope
│   ├── app.dart                     # HexFlipApp MaterialApp + _AppLoader startup widget
│   │
│   ├── models/                      # Pure data — no Flutter dependency except dart:ui for Color
│   │   ├── models.dart              # Barrel export for the entire models directory
│   │   ├── card_side.dart           # CardSide value type + SymbolShape enum
│   │   ├── card_model.dart          # HexCard (6 sides, owner) + PlayerOwner enum
│   │   ├── deck_model.dart          # DeckModel — named list of HexCards
│   │   ├── hex_cell.dart            # AxialCoord (q,r) + HexCell (coord, isActive, card?)
│   │   ├── board_model.dart         # BoardModel — Map<AxialCoord, HexCell> + helpers
│   │   ├── player.dart              # Player — owner, hand, deck, score, draw logic
│   │   ├── game_state.dart          # GameState — live board + players + phase + events
│   │   └── rules/
│   │       ├── game_rules.dart      # GameRules — all configurable rule fields
│   │       ├── attack_eligibility.dart  # AttackEligibilityRule + AttackMode enum
│   │       └── comparison_rule.dart # ComparisonRule — flip success conditions
│   │
│   ├── engine/                      # Stateless business logic — no Flutter, no state
│   │   ├── hex_math.dart            # neighborAt, oppositeSide, hexToPixel, pixelToHex, sideRotationRadians
│   │   ├── adjacency_resolver.dart  # AdjacencyResolver.resolve() + AdjacencyComparison result type
│   │   ├── flip_engine.dart         # FlipEngine.resolve() — wraps adjacency into FlipResult
│   │   ├── turn_manager.dart        # TurnManager — placeCard, endTurn, isGameOver, computeFinalScores
│   │   └── deck_manager.dart        # DeckManager — shuffle, buildPlayer, dealStartingHand
│   │
│   ├── state/                       # Riverpod providers and StateNotifier subclasses
│   │   ├── state.dart               # Barrel export for all state files
│   │   ├── providers.dart           # Provider declarations: gameRulesProvider, activeBoardProvider,
│   │   │                            #   decksProvider, gameStateProvider, setupDeckSelectionProvider
│   │   ├── game_state_notifier.dart # GameStateNotifier — startGame, placeCard, endTurn, drawCard, resetGame
│   │   ├── board_notifier.dart      # BoardNotifier — loadBoard, toggleCell, setName, clearCards
│   │   │                            #   Default: programmatically builds Classic 19 board
│   │   ├── decks_notifier.dart      # DecksNotifier — addOrUpdateDeck, removeDeck, loadDecks
│   │   ├── game_rules_notifier.dart # GameRulesNotifier — per-field setters + bulk update()
│   │   └── setup_deck_selection_notifier.dart  # Tracks P1/P2 deck IDs during setup flow
│   │
│   ├── screens/                     # Full-screen UI pages
│   │   ├── home_screen.dart         # Main menu with 4 navigation buttons
│   │   ├── setup_screen.dart        # Board/deck/rules selection → launches game
│   │   ├── game_screen.dart         # Main game view: board + hand + controls + overlays
│   │   ├── card_editor_screen.dart  # Two-panel: deck list (left) + card side editor (right)
│   │   ├── board_editor_screen.dart # Hex grid editor with toggle-cell interaction
│   │   └── rules_editor_screen.dart # Form-based editor for all GameRules fields
│   │
│   ├── widgets/                     # Reusable UI components
│   │   ├── app_colors.dart          # AppColors — centralized dark-theme color constants
│   │   ├── hex_board_widget.dart    # HexBoardWidget (ConsumerWidget) + _BoardPainter (CustomPainter)
│   │   ├── hex_card_widget.dart     # HexCardWidget + _HexCardPainter — renders a single card
│   │   ├── hand_widget.dart         # HandWidget — horizontal scrollable list of cards for current player
│   │   └── comparison_overlay.dart  # ComparisonOverlay — modal showing attack results after placement
│   │
│   └── persistence/
│       └── storage_service.dart     # StorageService — JSON file I/O + rootBundle asset loading
│
├── assets/
│   └── configs/
│       ├── default_deck.json        # Bundled deck: 10 cards, each with 6 distinct sides (shapes 1–9)
│       ├── classic_board.json       # 19-cell hex board (center + 2 rings)
│       ├── small_board.json         # 7-cell hex board (center + 1 ring)
│       └── default_rules.json       # Default rules: hand=5, draw=1, limit=7, deck=10, allSides, numberGreater
│
├── test/
│   └── widget_test.dart             # Placeholder smoke test (not yet updated for HexFlip)
│
├── linux/                           # Linux desktop runner (CMake)
├── windows/                         # Windows desktop runner (CMake + Flutter cpp wrapper)
├── web/                             # Web runner (index.html, manifest.json, icons)
├── pubspec.yaml                     # Project metadata, dependencies, asset declarations
├── analysis_options.yaml            # Linter: flutter_lints + prefer_const_constructors
├── DESIGN.md                        # Original architecture design document (pre-implementation)
└── INDEX.md                         # This file
```

---

## 4. Core Data Models

All models are in `/home/bas/HexFlip/lib/models/`. All are JSON-serializable via `fromJson` / `toJson`. Most use `copyWith` for immutable-style updates.

### 4.1 CardSide (`card_side.dart`)

The atomic unit of a card's face. Immutable value type.

```dart
class CardSide {
  final SymbolShape shape;   // enum: circle | square | triangle | star | diamond
  final int number;          // 1–9 (range enforced by editor, not model)
  final Color shapeColor;    // Flutter Color, stored as #RRGGBB hex in JSON
  final Color numberColor;   // Color of the printed number
}
```

Color serialization strips the alpha channel: stored as `#RRGGBB`, parsed with `FF` prepended.

### 4.2 HexCard (`card_model.dart`)

A playable card. Has exactly 6 `CardSide` entries — one per hex edge — indexed clockwise from top-right.

```dart
class HexCard {
  final String id;           // UUID v4
  final List<CardSide> sides; // length == 6, index 0 = top-right, clockwise
  PlayerOwner owner;         // THE ONLY MUTABLE FIELD — red | blue
}
```

`flip()` = `owner = owner == red ? blue : red`. Nothing else changes.
`freshCopy()` returns a new instance with the same sides but `owner` reset to `red`.

### 4.3 DeckModel (`deck_model.dart`)

A named, ordered list of `HexCard` templates. Stored as a unit in persistence.

```dart
class DeckModel {
  final String id;           // UUID v4
  final String name;
  final List<HexCard> cards;
}
```

### 4.4 AxialCoord (`hex_cell.dart`)

Immutable axial coordinate for the hex grid. Implements `==` and `hashCode` so it can be used as a `Map` key.

```dart
@immutable
class AxialCoord {
  final int q;
  final int r;
  static const List<AxialCoord> directions = [
    AxialCoord(1, -1), // 0: top-right
    AxialCoord(1, 0),  // 1: right
    AxialCoord(0, 1),  // 2: bottom-right
    AxialCoord(-1, 1), // 3: bottom-left
    AxialCoord(-1, 0), // 4: left
    AxialCoord(0, -1), // 5: top-left
  ];
}
```

### 4.5 HexCell (`hex_cell.dart`)

A single board position. Mutable: `isActive` can be toggled in the editor, `card` is set when placed.

```dart
class HexCell {
  final AxialCoord coord;
  bool isActive;   // Is this cell part of the playable board?
  HexCard? card;   // null = empty
}
```

### 4.6 BoardModel (`board_model.dart`)

The board as a `Map<AxialCoord, HexCell>`. `activeCoords` convenience getter returns only playable cells. `cleared()` returns a deep copy with all cards removed (used at game start).

### 4.7 Player (`player.dart`)

Holds a player's hand and deck. `draw(count, handLimit)` moves cards from deck to hand respecting the limit. Score is an integer set by `TurnManager.computeFinalScores` at game end.

### 4.8 GameState (`game_state.dart`)

The top-level live game container. **Mutable** — the engine layer operates on it in place.

```dart
class GameState {
  final BoardModel board;           // mutable cells inside
  final Player player1;             // red
  final Player player2;             // blue
  PlayerOwner currentTurn;          // mutable
  GamePhase phase;                  // setup | playing | ended
  final List<FlipEvent> pendingFlipEvents;  // consumed by UI animation
  final GameRules rules;
}
```

`scores` computed property counts board ownership. `boardFull` and `bothHandsEmpty` are end-of-game checks.

`FlipEvent` is a simple record: `{cellCoord, from, to}` — used by `HexBoardWidget` to highlight freshly flipped cells.

### 4.9 GameRules (`rules/game_rules.dart`)

All configurable parameters for a game session.

| Field | Type | Default | Description |
|---|---|---|---|
| `startingHandSize` | int | 5 | Cards dealt to each player at game start |
| `cardsDrawnPerTurn` | int | 1 | Cards drawn when auto-draw fires or Draw is pressed |
| `handLimit` | int | 7 | Maximum cards in hand |
| `deckSize` | int | 10 | How many cards to take from the deck template |
| `autoDrawEnabled` | bool | true | Draw automatically at turn start |
| `placementRequired` | bool | true | Must place a card each turn |
| `attackEligibility` | AttackEligibilityRule | allSides | Which card sides can attack |
| `comparisonRule` | ComparisonRule | numberGreater | How to determine flip success |

### 4.10 AttackEligibilityRule (`rules/attack_eligibility.dart`)

Determines whether a given attacking side is even eligible to participate in a comparison.

```dart
enum AttackMode { allSides, specificShape, specificColor, shapeAndColor }
```

`sideCanAttack(CardSide side)` returns true/false. With `allSides` (default), all sides attack. With `specificShape`, only sides whose shape matches `requiredShape` attack.

### 4.11 ComparisonRule (`rules/comparison_rule.dart`)

Given two eligible sides (attacker and defender), determines whether the flip succeeds.

`attackSucceeds(CardSide attacker, CardSide defender)` checks the enabled conditions in order:
1. Number check: `attacker.number > defender.number` (or `>=` if `allowEqual`)
2. Shape match: `attacker.shape == defender.shape`
3. Color match: `attacker.shapeColor == defender.shapeColor`
4. Both shape and color simultaneously

All enabled conditions must pass. Default: only number-greater is required.

---

## 5. Engine Layer (Business Logic)

All engine code is in `/home/bas/HexFlip/lib/engine/`. Stateless — no Flutter imports except `dart:math` and `package:flutter/painting.dart` (for `Offset`). All methods are `static` or top-level functions.

### 5.1 HexMath (`hex_math.dart`)

Pure math utilities. Single source of truth for hex geometry.

| Function | Purpose |
|---|---|
| `neighborAt(origin, sideIndex)` | Returns `AxialCoord` of the neighbor in direction `sideIndex` |
| `oppositeSide(sideIndex)` | Returns `(sideIndex + 3) % 6` — the facing side of a neighbor |
| `neighborsOf(origin)` | Returns all 6 `({coord, sideIndex})` records |
| `sideRotationRadians(sideIndex)` | Returns `sideIndex * pi / 3` for UI rendering |
| `hexToPixel(coord, size)` | Flat-top axial → pixel `Offset` |
| `pixelToHex(pixel, size)` | Pixel → nearest `AxialCoord` (cube-coordinate rounding) |

### 5.2 AdjacencyResolver (`adjacency_resolver.dart`)

`AdjacencyResolver.resolve(placedCoord, board, rules)`:

For each of 6 directions from `placedCoord`:
1. Skip if no cell, inactive cell, empty cell, or same-owner card.
2. Determine `attackerSide = placed.sides[sideIndex]` and `defenderSide = neighbor.sides[oppositeSide(sideIndex)]`.
3. Run eligibility: `rules.attackEligibility.sideCanAttack(attackerSide)`.
4. Run comparison: `rules.comparisonRule.attackSucceeds(attackerSide, defenderSide)`.
5. If both pass: call `neighborCell.card!.flip()` (mutates in place).
6. Record an `AdjacencyComparison` for every qualifying direction (eligible or not, flipped or not).

Returns `List<AdjacencyComparison>` — all comparisons, for the UI overlay to display.

`AdjacencyComparison` fields: `attackerCoord`, `defenderCoord`, `attackerSideIndex`, `defenderSideIndex`, `attackerSide`, `defenderSide`, `eligible`, `succeeds`, `flipped`.

### 5.3 FlipEngine (`flip_engine.dart`)

Thin orchestrator over `AdjacencyResolver`. Converts `AdjacencyComparison` results into `FlipEvent` objects that carry only `{cellCoord, from, to}` — the minimal data the UI needs to animate.

`FlipEngine.resolve()` returns `FlipResult { comparisons, flipEvents }`.

### 5.4 TurnManager (`turn_manager.dart`)

Manages the turn lifecycle. All methods are static.

| Method | Description |
|---|---|
| `canPlaceCard(coord, state)` | Validates placement: cell must exist, be active, and be empty |
| `placeCard(card, coord, state)` | Removes card from hand, sets owner, places on board, runs FlipEngine, appends FlipEvents |
| `endTurn(state)` | Switches turn, optionally auto-draws for the new current player |
| `isGameOver(state)` | True if board full or both hands empty |
| `computeFinalScores(state)` | Counts board cells and writes to `player.score` |

### 5.5 DeckManager (`deck_manager.dart`)

Handles deck construction and initial deal. All methods are static.

| Method | Description |
|---|---|
| `shuffle(cards)` | Returns a new shuffled list without mutating the input |
| `buildPlayer(owner, deckTemplate, rules)` | Creates fresh card copies, assigns owner, shuffles |
| `dealStartingHand(player, rules)` | Draws `startingHandSize` cards respecting `handLimit` |

---

## 6. State Management

All state code is in `/home/bas/HexFlip/lib/state/`. Uses `flutter_riverpod` `StateNotifier` pattern.

### 6.1 Providers (`providers.dart`)

| Provider | Type | Initial State | Purpose |
|---|---|---|---|
| `gameRulesProvider` | `StateNotifier<GameRules>` | `GameRules()` defaults | Active rules being edited or used |
| `activeBoardProvider` | `StateNotifier<BoardModel>` | Programmatic Classic 19 | Board being edited or used for next game |
| `decksProvider` | `StateNotifier<Map<String, DeckModel>>` | `{}` | All known decks keyed by id |
| `gameStateProvider` | `StateNotifier<GameState?>` | `null` | Live game state; null = no game in progress |
| `setupDeckSelectionProvider` | `StateNotifier<({String? p1DeckId, String? p2DeckId})>` | `(null, null)` | Transient deck selection during setup |

### 6.2 GameStateNotifier (`game_state_notifier.dart`)

Critical implementation detail: `GameState` is a mutable Dart object. The notifier overrides `updateShouldNotify` to always return `true`, and the `_notify()` helper temporarily sets state to `null` then back to force a `ChangeNotifier` event — this is because Riverpod's default equality check would skip notification when the object reference is unchanged.

Public API:
- `startGame(board, p1Deck, p2Deck, rules)` — builds players, deals hands, creates fresh `GameState`
- `placeCard(card, coord)` — delegates to `TurnManager.placeCard`, then checks game over
- `endTurn()` — clears flip events, delegates to `TurnManager.endTurn`, checks game over
- `drawCard()` — manually draws cards for current player
- `clearFlipEvents()` — clears pending events after overlay is dismissed
- `resetGame()` — sets state to null

### 6.3 BoardNotifier (`board_notifier.dart`)

Default state is programmatically generated: Classic 19 board (cells where `max(|q|, |r|, |q+r|) <= 2`). This matches the `classic_board.json` asset exactly.

`toggleCell(coord)` adds a new inactive cell if the coord doesn't exist, or toggles existing cell's `isActive`.

### 6.4 DecksNotifier (`decks_notifier.dart`)

Simple map operations. `addOrUpdateDeck` creates a new map spread. `loadDecks` replaces the entire map.

### 6.5 GameRulesNotifier (`game_rules_notifier.dart`)

One setter per field (`setStartingHandSize`, `setCardsDrawnPerTurn`, etc.) plus bulk `update(rules)`. Each setter uses `copyWith` to produce a new `GameRules` instance.

### 6.6 SetupDeckSelectionNotifier (`setup_deck_selection_notifier.dart`)

Dart record `({String? p1DeckId, String? p2DeckId})` as state. `selectP1Deck`, `selectP2Deck`, `reset`.

---

## 7. Screens

All screens are in `/home/bas/HexFlip/lib/screens/`.

### 7.1 HomeScreen (`home_screen.dart`)

Entry screen. Four navigation buttons: New Game → SetupScreen, Card Editor → CardEditorScreen, Board Editor → BoardEditorScreen, Rules Editor → RulesEditorScreen. StatelessWidget.

### 7.2 SetupScreen (`setup_screen.dart`)

`ConsumerStatefulWidget`. Local state tracks `_selectedBoardId`, `_p1DeckId`, `_p2DeckId`. Reads `activeBoardProvider`, `decksProvider`, `gameRulesProvider`. Displays board info, two deck dropdowns, and a rules summary. Start button triggers `gameStateProvider.notifier.startGame(...)` then `Navigator.pushReplacement` to GameScreen.

### 7.3 GameScreen (`game_screen.dart`)

`ConsumerStatefulWidget`. Local state: `_selectedCard`, `_lastComparisons`, `_showComparisonOverlay`.

Layout (Column inside Stack):
1. `_TopBar` — player scores and current-turn indicator
2. `HexBoardWidget` (expanded) — interactive hex grid
3. `_BottomBar` — Draw and End Turn buttons
4. `HandWidget` — scrollable hand for current player

Stack overlays:
- `ComparisonOverlay` — shown after placement if any adjacency comparisons occurred
- `_GameOverOverlay` — shown when `gameState.phase == GamePhase.ended`

**Preview pattern:** Before calling `gameStateProvider.notifier.placeCard(...)` (which mutates), the screen runs `_previewAdjacency(...)` — a read-only mirror of `AdjacencyResolver` that does not call `flip()`. This gives the UI the comparison data to show in the overlay without a double-resolution problem.

### 7.4 CardEditorScreen (`card_editor_screen.dart`)

`ConsumerStatefulWidget`. Two-panel layout: 220px deck list on the left, card editor on the right. Works on a local mutable copy of the selected deck's cards (`_editingCards`). Changes are not pushed to `decksProvider` until Save is pressed. Supports create/rename/delete decks and add/delete/edit cards. Each card row has 6 `_SideEditor` widgets. Colors are chosen from a 12-color preset grid.

### 7.5 BoardEditorScreen (`board_editor_screen.dart`)

`ConsumerStatefulWidget`. Renders a hex grid in range `q,r ∈ [-4,4]` using `CustomPainter`. Tap detection converts pixel → axial via `pixelToHex` and calls `activeBoardProvider.notifier.toggleCell(coord)`. Load board dialog provides Classic 19 and Small 7 presets (built programmatically). Save dialog updates the board name via `setName`.

### 7.6 RulesEditorScreen (`rules_editor_screen.dart`)

`ConsumerWidget`. Form-based list of rule editors. Number fields use `_NumberRuleRow` (text field + increment/decrement buttons). Boolean fields use `_SwitchRuleRow`. Attack eligibility and comparison rules have dedicated compound widgets. Reset button calls `notifier.update(GameRules())`. Save button shows a SnackBar (persistence not yet fully wired here — rules are saved to disk on app load via `StorageService`).

---

## 8. Widgets

All widgets are in `/home/bas/HexFlip/lib/widgets/`.

### 8.1 AppColors (`app_colors.dart`)

All UI colors defined as `static const Color`. Dark purple-navy theme. Key colors:

| Constant | Hex | Usage |
|---|---|---|
| `background` | `#1A1A2E` | Scaffold background |
| `surface` | `#16213E` | Cards, panels |
| `surfaceAlt` | `#0F3460` | Elevated surfaces |
| `redPlayer` | `#8B2020` | P1 card fill |
| `bluePlayer` | `#1A4A8A` | P2 card fill |
| `redPlayerLight` | `#D45555` | P1 borders and highlights |
| `bluePlayerLight` | `#5599DD` | P2 borders and highlights |
| `cellActive` | `#2A2A4A` | Empty active hex |
| `attackHighlight` | `#FFCC00` | Selected cell border |
| `flipHighlight` | `#00FF88` | Flipped cell border/glow |
| `accent` | `#4CC9F0` | Buttons, headings |

### 8.2 HexBoardWidget (`hex_board_widget.dart`)

`ConsumerWidget`. Reads `gameStateProvider`. Uses `InteractiveViewer` for pan/zoom (scale 0.5–3.0). Content is a `CustomPaint` using `_BoardPainter`.

`_BoardPainter` renders each active `HexCell`:
- Fill: `redPlayer` / `bluePlayer` if occupied, `cellActive` if empty
- Border: highlighted yellow if `selectedTarget`, green if in `flipCoords`, else player color
- Card content: 6 side symbols + numbers at `dist = cellSize * 0.58` from center, positioned using `sideRotationRadians(i)` from `hex_math.dart`
- Center dot: colored circle showing owner

Tap detection: `GestureDetector.onTapDown` converts local position → axial coord via `pixelToHex`, then calls `onCellTapped` callback if valid.

### 8.3 HexCardWidget (`hex_card_widget.dart`)

Stateless. Renders a single card in `size * 2 x size * 2` bounding box using `CustomPaint`. Supports `isSelected` (yellow border) and `isSmall` (skips side symbols for compact display). Used in the hand and the comparison overlay's side-info panels.

Shapes rendered by `_drawShape`: circle (drawCircle), square (drawRect), triangle (3-point path), star (10-point alternating outer/inner radius path), diamond (4-point path).

### 8.4 HandWidget (`hand_widget.dart`)

`ConsumerWidget`. Shows current player's hand as a horizontal `ListView.separated`. Highlights the selected card. Displays hand size and deck count. Height is fixed at 120px.

### 8.5 ComparisonOverlay (`comparison_overlay.dart`)

Stateless. Full-screen semi-transparent overlay. Shows a modal panel listing each `AdjacencyComparison` as a row: attacker side info on the left, result icon in the middle, defender side info on the right. Rows colored differently when flipped vs. not. Dismissed by tapping outside the panel or the Continue button.

---

## 9. Persistence Layer

`/home/bas/HexFlip/lib/persistence/storage_service.dart`

`StorageService` uses `path_provider` to find the app documents directory. Data lives at:
```
<appDocDir>/hexflip/
  decks/<id>.json      — one file per DeckModel
  boards/<id>.json     — one file per BoardModel
  rules/<name>.json    — one file per GameRules preset
```

Default assets are loaded via `rootBundle.loadString('assets/configs/<name>')`.

| Method | Description |
|---|---|
| `saveDeck(deck)` | Writes `<appDoc>/hexflip/decks/<id>.json` |
| `loadDeck(id)` | Reads single deck, returns null if missing/broken |
| `loadAllDecks()` | Scans decks dir, skips malformed files |
| `deleteDeck(id)` | Deletes file silently |
| `saveBoard(board)` | Writes `<appDoc>/hexflip/boards/<id>.json` |
| `loadBoard(id)` / `loadAllBoards()` / `deleteBoard(id)` | Analogous |
| `saveRules(rules, name)` | Writes `<appDoc>/hexflip/rules/<name>.json` |
| `loadRules(name)` | Reads rules preset, returns null if missing |
| `loadDefaultDeck(assetName)` | Reads from `assets/configs/` via rootBundle |
| `loadDefaultBoard(assetName)` | Same |
| `loadDefaultRules()` | Loads `assets/configs/default_rules.json` |

**Startup sequence (in `_AppLoader._loadDefaults`):**
1. Load all decks from disk. If none, fall back to `default_deck.json` asset.
2. Load saved rules with key `'last_rules'`. If none, load `default_rules.json` asset.
3. Load saved boards. If any, use the first one as the active board.
4. Set `_loaded = true` to show HomeScreen.

---

## 10. Asset Configuration Files

All under `/home/bas/HexFlip/assets/configs/`.

### default_deck.json
10 cards, each with 6 sides. Sides use all 5 shapes (circle, square, triangle, star, diamond) and numbers 1–9. Colors are hand-chosen muted hex values for visual variety. Cards are named `c1`–`c10`.

### classic_board.json
19 cells in standard hex ring layout. Center (0,0) plus two complete rings. Condition: `max(|q|, |r|, |q+r|) ≤ 2`. Coordinates listed explicitly.

### small_board.json
7 cells: center plus one ring. Condition: `max(|q|, |r|, |q+r|) ≤ 1`. Good for quick test games.

### default_rules.json
```json
{
  "startingHandSize": 5,
  "cardsDrawnPerTurn": 1,
  "handLimit": 7,
  "deckSize": 10,
  "autoDrawEnabled": true,
  "placementRequired": true,
  "attackEligibility": { "mode": "allSides" },
  "comparison": {
    "requireNumberGreater": true,
    "allowEqual": false,
    "requireShapeMatch": false,
    "requireColorMatch": false,
    "requireBothShapeAndColor": false
  }
}
```

---

## 11. Dependencies

### Runtime Dependencies (`pubspec.yaml`)

| Package | Version | Purpose |
|---|---|---|
| `flutter` | SDK | UI framework |
| `flutter_riverpod` | ^2.4.9 | State management — typed providers, no BuildContext threading |
| `riverpod_annotation` | ^2.3.3 | Annotation support (available but not currently used for code-gen) |
| `uuid` | ^4.3.3 | UUID v4 generation for `HexCard.id` and `DeckModel.id` |
| `collection` | ^1.18.0 | Extended collection utilities (available; used implicitly) |
| `path_provider` | ^2.1.2 | Locates app documents directory for JSON persistence |
| `shared_preferences` | ^2.2.2 | Available for key-value storage (not currently used; file JSON is used instead) |

### Dev Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter_test` | SDK | Test framework |
| `flutter_lints` | ^3.0.0 | Linting rules |
| `riverpod_generator` | ^2.3.9 | Code generation for riverpod (available, not used) |
| `build_runner` | ^2.4.8 | Build system for code gen (available, not used) |
| `mocktail` | ^1.0.2 | Mock objects for unit tests (available, not used yet) |

---

## 12. Build Targets

### Linux (`linux/`)
CMake-based runner. `linux/runner/main.cc` is the entry point. `linux/runner/my_application.cc` sets up the GTK window. No custom plugins.

### Windows (`windows/`)
CMake-based runner. Includes the full Flutter Windows C++ wrapper under `windows/flutter/ephemeral/cpp_client_wrapper/`. The wrapper provides `FlutterEngine`, `FlutterViewController`, `MethodChannel`, `EventChannel`, and codec types.

### Web (`web/`)
Standard Flutter web runner. `web/index.html`, `web/manifest.json`, icon assets at 192x512 (standard and maskable). No service worker customization.

### Building
```bash
# Linux
flutter build linux

# Windows (run on Windows)
flutter build windows

# Web
flutter build web

# Run in debug mode
flutter run -d linux
flutter run -d chrome
```

---

## 13. Key Design Constraints

| Constraint | Where enforced |
|---|---|
| Flip = ownership only | `HexCard.flip()` toggles only `owner`; `sides` is final |
| Side positions never change | `sides` is a final `List` set at construction |
| No visual rotation on flip | Color-only change; no transform on card widget |
| Side `i` always faces direction `i` | `AxialCoord.directions[i]` is the canonical direction for side `i` |
| Opposing side formula | `(i + 3) % 6` — used in `oppositeSide()` and all engine code |
| Data-driven rules | `GameRules`, `AttackEligibilityRule`, `ComparisonRule` are plain Dart objects, JSON-serializable |
| No hard-coded shapes | `SymbolShape` enum; comparison logic does not name specific values |
| Board is data-driven | `BoardModel` is a coordinate map loaded from JSON |
| Flat-top hex layout | All geometry uses flat-top formulas throughout (`cos(pi/3 * i)` for corners, `3/2 * q` for x-pixel) |
| Card sides always clockwise from top-right | Index 0 = top-right; this is the contract between model and all rendering code |

---

## 14. Data Flow — Card Placement Sequence

```
User taps a card in HandWidget
  → GameScreen._onCardSelected(card)
  → _selectedCard = card (local state)

User taps a hex cell in HexBoardWidget
  → GameScreen._onCellTapped(coord)
  → if _selectedCard != null && cell.isEmpty:
      1. _previewAdjacency(placedCard, coord, board, rules)
             [read-only mirror of AdjacencyResolver — no flip() calls]
         → comparisons: List<AdjacencyComparison>
      2. ref.read(gameStateProvider.notifier).placeCard(card, coord)
             → TurnManager.placeCard(card, coord, state)
                 a. Remove card from currentPlayer.hand
                 b. card.owner = state.currentTurn
                 c. board.cells[coord].card = card
                 d. FlipEngine.resolve(coord, board, rules)
                     → AdjacencyResolver.resolve(coord, board, rules)
                         for each of 6 directions:
                           check eligibility + comparison
                           if succeeds: neighbor.card.flip()  [mutates in place]
                           record AdjacencyComparison
                     → wrap flipped comparisons into FlipEvent list
                 e. state.pendingFlipEvents.addAll(flipEvents)
             → _checkGameOver() → if over: computeFinalScores, phase = ended
             → _notify() [force Riverpod listeners to rebuild]
      3. if comparisons.isNotEmpty:
           setState(_showComparisonOverlay = true, _lastComparisons = comparisons)

ComparisonOverlay shown → user taps Continue
  → GameScreen._onDismissComparison()
  → _showComparisonOverlay = false
  → gameStateProvider.notifier.clearFlipEvents()
  → HexBoardWidget rebuilds (flipCoords set is now empty → green borders cleared)

User taps End Turn
  → gameStateProvider.notifier.endTurn()
      → state.pendingFlipEvents.clear()
      → TurnManager.endTurn(state)
          → state.switchTurn()
          → if autoDrawEnabled: currentPlayer.draw(cardsDrawnPerTurn, handLimit)
      → _checkGameOver()
      → _notify()
```

---

## 15. Hex Coordinate System

**Axial coordinates (q, r)** — standard flat-top hex grid.

```
Side index → direction:
  0 = top-right     (+1, -1)   angle = 0    (0°)
  1 = right         (+1,  0)   angle = π/3  (60°)
  2 = bottom-right  ( 0, +1)   angle = 2π/3 (120°)
  3 = bottom-left   (-1, +1)   angle = π    (180°)
  4 = left          (-1,  0)   angle = 4π/3 (240°)
  5 = top-left      ( 0, -1)   angle = 5π/3 (300°)

Opposing side of i: (i + 3) % 6
  0 ↔ 3, 1 ↔ 4, 2 ↔ 5
```

**Pixel conversion (flat-top):**
```
x = size * (3/2 * q)
y = size * (sqrt(3)/2 * q + sqrt(3) * r)
```

**Inverse (pixel → axial):** Computed via floating-point cube coordinates, then rounded using the largest-rounding-error correction to maintain `q + r + s == 0`.

---

## 16. Color Palette

All defined in `/home/bas/HexFlip/lib/widgets/app_colors.dart`. Dark purple-navy theme.

```
Background:    #1A1A2E  (deep navy)
Surface:       #16213E  (dark blue)
Surface Alt:   #0F3460  (elevated blue)
Red Player:    #8B2020  (muted red fill)
Blue Player:   #1A4A8A  (muted blue fill)
Red Light:     #D45555  (P1 borders/text)
Blue Light:    #5599DD  (P2 borders/text)
Cell Active:   #2A2A4A  (empty hex fill)
Cell Hover:    #3A3A6A  (hover — available)
Cell Border:   #4A4A7A  (hex outlines)
Cell Inactive: #111128  (board editor — inactive)
Attack Hl:     #FFCC00  (selected cell — yellow)
Defend Hl:     #FF6600  (available)
Flip Hl:       #00FF88  (flipped cell — green)
Text:          #E0E0F0
Text Muted:    #8888AA
Accent:        #4CC9F0  (cyan — buttons, titles)
```

---

## 17. Test Coverage

`/home/bas/HexFlip/test/widget_test.dart` — This file is the default Flutter scaffold test. It references `MyApp` which does not exist in HexFlip. The test is a leftover placeholder and will fail as-is. No custom test cases exist yet.

The `mocktail` and `riverpod_generator` dev dependencies are declared but unused — they are ready for future unit test development.

Engine functions (`hex_math.dart`, `adjacency_resolver.dart`, `flip_engine.dart`, `turn_manager.dart`, `deck_manager.dart`) are all pure/static and highly testable without Flutter infrastructure.
