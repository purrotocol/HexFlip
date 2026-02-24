---
title: Architecture
layout: default
nav_order: 2
---

# Architecture
{: .no_toc }

System design and key implementation decisions.
{: .fs-6 .fw-300 }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Layer overview

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

**State management:** Riverpod `StateNotifier` providers. `GameState` is a mutable object; `GameStateNotifier` overrides `updateShouldNotify` to always return `true` and uses a null-swap trick to force listeners to fire even when the object reference is unchanged.

**Navigation:** Simple Flutter `Navigator.push` / `Navigator.pushReplacement`. No named routes, no Router. Screen flow: HomeScreen → SetupScreen → GameScreen. Editors are modal pushes from HomeScreen.

---

## Core data models

### CardSide

The atomic unit of a card's face. Immutable value type.

```dart
class CardSide {
  final SymbolShape shape;   // enum: circle | square | triangle | star | diamond
  final int number;          // 1–9
  final Color shapeColor;    // stored as #RRGGBB hex in JSON
  final Color numberColor;
}
```

### HexCard

A playable card with exactly 6 `CardSide` entries — one per hex edge — indexed clockwise from top-right.

```dart
class HexCard {
  final String id;
  final List<CardSide> sides; // length == 6, index 0 = top-right, clockwise
  PlayerOwner owner;          // THE ONLY MUTABLE FIELD — red | blue
}
```

`flip()` = `owner = owner == red ? blue : red`. Nothing else changes.

### HexCell

A single board position. `isActive` can be toggled in the editor; `card` is set when placed.

```dart
class HexCell {
  final AxialCoord coord;
  bool isActive;   // Is this cell part of the playable board?
  HexCard? card;   // null = empty
}
```

### GameState

The top-level live game container. Mutated in place by the engine.

```dart
class GameState {
  final BoardModel board;
  final Player player1;          // red
  final Player player2;          // blue
  PlayerOwner currentTurn;
  GamePhase phase;               // setup | playing | ended
  final List<FlipEvent> pendingFlipEvents;
  final GameRules rules;
}
```

---

## Hex coordinate system

**Axial coordinates (q, r)** — flat-top layout.

```
Side index → direction:
  0 = top-right     (+1, -1)   angle = 0°
  1 = right         (+1,  0)   angle = 60°
  2 = bottom-right  ( 0, +1)   angle = 120°
  3 = bottom-left   (-1, +1)   angle = 180°
  4 = left          (-1,  0)   angle = 240°
  5 = top-left      ( 0, -1)   angle = 300°

Opposing side of i: (i + 3) % 6
  0 ↔ 3,  1 ↔ 4,  2 ↔ 5
```

**Pixel conversion (flat-top):**

$$x = size \times \frac{3}{2} q$$

$$y = size \times \left(\frac{\sqrt{3}}{2} q + \sqrt{3}\, r\right)$$

Inverse: computed via floating-point cube coordinates, then rounded using the largest-rounding-error correction to maintain `q + r + s = 0`.

---

## Flip engine logic

```
AdjacencyResolver.resolve(placedCoord, board, rules):
  for each of 6 directions d from placedCoord:
    skip if: no cell | inactive | empty | same-owner card
    attackerSide = placed.sides[d]
    defenderSide = neighbor.sides[(d + 3) % 6]

    eligible = rules.attackEligibility.sideCanAttack(attackerSide)
    succeeds = rules.comparisonRule.attackSucceeds(attackerSide, defenderSide)

    if eligible && succeeds:
      neighbor.card.flip()    // mutates owner in place
      record FlipEvent

    record AdjacencyComparison (eligible or not, flipped or not)

Returns List<AdjacencyComparison> → consumed by ComparisonOverlay
```

`FlipEngine.resolve()` wraps this into `FlipResult { comparisons, flipEvents }`.

---

## Card placement data flow

```
User taps a card in HandWidget
  → _selectedCard = card (local GameScreen state)

User taps a hex cell
  → if _selectedCard != null && cell.isEmpty:

      1. _previewAdjacency(...)
            [read-only AdjacencyResolver — no flip() calls]
         → comparisons: List<AdjacencyComparison>

      2. gameStateProvider.notifier.placeCard(card, coord)
            → TurnManager.placeCard(card, coord, state)
                a. Remove card from currentPlayer.hand
                b. card.owner = state.currentTurn
                c. board.cells[coord].card = card
                d. FlipEngine.resolve(coord, board, rules)
                     → AdjacencyResolver loops over 6 directions
                     → eligible + winning sides: neighbor.card.flip()
                     → wrap into FlipEvent list
                e. state.pendingFlipEvents.addAll(flipEvents)
            → _checkGameOver() if needed
            → _notify() — force Riverpod listeners to rebuild

      3. if comparisons.isNotEmpty:
           setState(_showComparisonOverlay = true)

ComparisonOverlay dismissed
  → clearFlipEvents()
  → HexBoardWidget rebuilds (green borders cleared)
```

---

## Screen flow

```
HomeScreen
  ├── [New Game] → SetupScreen
  │     ├── Select/edit board layout
  │     ├── Select decks (P1, P2)
  │     ├── Review rules summary
  │     └── [Start] → GameScreen
  │
  ├── [Card Editor] → CardEditorScreen
  │     └── Two-panel: deck list (left) + 6-side card editor (right)
  │
  ├── [Board Editor] → BoardEditorScreen
  │     └── Click hex grid to toggle active cells
  │
  └── [Rules Editor] → RulesEditorScreen
        └── Toggle/configure all GameRules fields
```

---

## Game screen layout

```
┌─────────────────────────────────────┐
│  [P1 Hand] ─── Score ─── [P2 Hand]  │
│─────────────────────────────────────│
│                                     │
│        HexBoardWidget               │
│   (active cells + placed cards)     │
│                                     │
│─────────────────────────────────────│
│  Turn: P1   [Draw]   [End Turn]     │
└─────────────────────────────────────┘
```

`ComparisonOverlay` appears as a Stack overlay after placement, showing each adjacency matchup with attacker vs. defender values and a flip indicator.

---

## Key design constraints

| Constraint | Implementation |
|---|---|
| Flip = ownership only | `HexCard.owner` is the only mutable field on a card |
| Side positions never change | `sides[i]` is final, set at card creation |
| No rotation on flip | Color-only change; no geometry transform applied |
| Side `i` always faces direction `i` | `side 0 = top-right, clockwise` — contract between model and all rendering code |
| Opposing side formula | `(i + 3) % 6` — deterministic, no lookup table needed |
| Data-driven rules | `GameRules`, `AttackEligibilityRule`, `ComparisonRule` are plain Dart objects, JSON-serializable |
| No hard-coded shapes | `SymbolShape` is an enum; comparison logic does not reference specific values |
| Board is data-driven | `BoardModel` is a coordinate map loaded from JSON |
| Flat-top hex layout | All geometry uses flat-top formulas throughout |

---

## Color palette

Dark purple-navy theme. All constants in `lib/widgets/app_colors.dart`.

| Constant | Hex | Usage |
|---|---|---|
| `background` | `#1A1A2E` | Scaffold background |
| `surface` | `#16213E` | Cards, panels |
| `surfaceAlt` | `#0F3460` | Elevated surfaces |
| `redPlayer` | `#8B2020` | P1 card fill |
| `bluePlayer` | `#1A4A8A` | P2 card fill |
| `redPlayerLight` | `#D45555` | P1 borders and highlights |
| `bluePlayerLight` | `#5599DD` | P2 borders and highlights |
| `attackHighlight` | `#FFCC00` | Selected cell border |
| `flipHighlight` | `#00FF88` | Flipped cell border/glow |
| `accent` | `#4CC9F0` | Buttons, headings |

---

## Out of scope

- AI opponent
- Network multiplayer
- Advanced animations beyond color transitions and highlights
- Card art, titles, abilities, or asymmetric card faces
- Sound effects
