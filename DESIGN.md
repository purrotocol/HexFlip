# HexFlip — System Architecture Design Report

**Project:** Modular Hex-Based Card Game Playtesting App
**Language:** Dart / Flutter
**Status:** Pre-implementation design
**Date:** 2026-02-15

---

## Overview

HexFlip is a Flutter/Dart desktop-web prototype for playtesting a configurable hexagonal card game. It is a flexible sandbox for testing mechanics — not a finished product with art or polish.

**Design priorities:**
- Flexibility and modularity above all else
- Data-driven rule system (no hard-coded assumptions)
- Clean adjacency comparison engine
- Fast iteration for playtesting

---

## 1. Folder Structure

```
HexFlip/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   │
│   ├── models/                    # Pure data, no UI
│   │   ├── card_model.dart
│   │   ├── card_side.dart
│   │   ├── deck_model.dart
│   │   ├── board_model.dart
│   │   ├── hex_cell.dart
│   │   ├── game_state.dart
│   │   ├── player.dart
│   │   └── rules/
│   │       ├── game_rules.dart
│   │       ├── attack_eligibility.dart
│   │       └── comparison_rule.dart
│   │
│   ├── engine/                    # Business logic, stateless
│   │   ├── hex_math.dart
│   │   ├── adjacency_resolver.dart
│   │   ├── flip_engine.dart
│   │   ├── turn_manager.dart
│   │   └── deck_manager.dart
│   │
│   ├── state/                     # App state (Riverpod)
│   │   ├── game_state_notifier.dart
│   │   ├── editor_state_notifier.dart
│   │   └── providers.dart
│   │
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── card_editor_screen.dart
│   │   ├── board_editor_screen.dart
│   │   ├── rules_editor_screen.dart
│   │   ├── game_screen.dart
│   │   └── setup_screen.dart
│   │
│   ├── widgets/
│   │   ├── hex_board_widget.dart
│   │   ├── hex_cell_widget.dart
│   │   ├── hex_card_widget.dart
│   │   ├── card_side_widget.dart
│   │   ├── hand_widget.dart
│   │   ├── flip_animation.dart
│   │   └── comparison_overlay.dart
│   │
│   └── persistence/
│       ├── storage_service.dart
│       └── json_serializer.dart
│
├── assets/
│   └── default_configs/
│       ├── default_deck.json
│       ├── classic_board.json
│       └── default_rules.json
│
└── pubspec.yaml
```

---

## 2. Core Data Models

### CardSide

```dart
class CardSide {
  final SymbolShape shape;   // enum: circle, square, triangle, star, diamond
  final int number;          // 1–9 (configurable range)
  final Color shapeColor;
  final Color numberColor;
}
```

### HexCard

```dart
class HexCard {
  final String id;
  final List<CardSide> sides;  // always length 6, index 0 = top-right edge, clockwise
  PlayerOwner owner;           // red | blue — ONLY mutable field
}
```

**Flip = `owner = owner == red ? blue : red`. Nothing else changes.**

### HexCell (board space)

```dart
class HexCell {
  final AxialCoord coord;   // q, r
  bool isActive;            // part of the playable board?
  HexCard? card;            // null = empty
}
```

### BoardModel

```dart
class BoardModel {
  final String id;
  final String name;
  final Map<AxialCoord, HexCell> cells;
}
```

### GameRules

```dart
class GameRules {
  // Setup
  int startingHandSize;
  int cardsDrawnPerTurn;
  int handLimit;
  int deckSize;
  bool autoDrawEnabled;
  bool placementRequired;

  // Attack eligibility
  AttackEligibilityRule attackEligibility;

  // Comparison
  ComparisonRule comparisonRule;
}
```

### AttackEligibilityRule

```dart
class AttackEligibilityRule {
  AttackMode mode;  // enum: allSides | specificShape | specificColor | shapeAndColor

  // Optional constraints (null = any)
  SymbolShape? requiredShape;
  Color? requiredColor;

  bool sideCanAttack(CardSide side) { ... }
}
```

### ComparisonRule

```dart
class ComparisonRule {
  bool requireNumberGreater;     // attacker.number > defender.number
  bool allowEqual;               // attacker.number >= defender.number
  bool requireShapeMatch;
  bool requireColorMatch;        // shape color must match
  bool requireBothShapeAndColor;

  bool attackSucceeds(CardSide attacker, CardSide defender) { ... }
}
```

---

## 3. Hex Coordinate System

Uses **axial coordinates** (`q`, `r`) — standard for hex grids.

```
AxialCoord(q, r)

Side index → axial direction mapping (flat-top hexagon):
  Side 0 = top-right    (+1, -1)
  Side 1 = right        (+1,  0)
  Side 2 = bottom-right ( 0, +1)
  Side 3 = bottom-left  (-1, +1)
  Side 4 = left         (-1,  0)
  Side 5 = top-left     ( 0, -1)

Opposing side of index i = (i + 3) % 6
```

`adjacency_resolver.dart` uses this to:
1. Find all 6 neighbors of a placed card
2. For each occupied neighbor, determine which side of the placed card faces which side of the neighbor
3. Pass both sides to `flip_engine` for comparison

---

## 4. Flip Engine Logic

```
FlipEngine.resolve(placed: HexCard, board: BoardModel, rules: GameRules):
  for each neighbor card N at direction d:
    attackingSide = placed.sides[d]
    defendingSide = N.sides[(d + 3) % 6]

    if rules.attackEligibility.sideCanAttack(attackingSide):
      if rules.comparisonRule.attackSucceeds(attackingSide, defendingSide):
        if N.owner != placed.owner:
          N.owner = placed.owner   // flip ownership
          yield FlipEvent(cell: N, from: oldOwner, to: placed.owner)
```

Returns a list of `FlipEvent` objects consumed by the UI for animation and highlighting.

---

## 5. Side Orientation & Visual Rotation

Each card side's symbol/number is rotated `60° × sideIndex` so it reads "outward" from its edge:

```dart
double sideRotation(int sideIndex) => sideIndex * 60.0 * (pi / 180);
```

In `HexCardWidget`, each side wedge rotates its content by this angle. This is **purely visual** — the data model is always `sides[0..5]` clockwise from top-right regardless of visual rotation.

Card flip (ownership change) = only the background color changes (`red` muted → `blue` muted). No geometric transformation is applied.

---

## 6. State Management

**Riverpod** — typed, testable, no BuildContext threading. Suitable for Flutter desktop and web.

```
Providers:
  gameRulesProvider        → StateNotifier<GameRules>
  boardModelProvider       → StateNotifier<BoardModel>
  decksProvider            → StateNotifier<Map<String, DeckModel>>
  gameStateProvider        → StateNotifier<GameState>
  editorStateProvider      → StateNotifier<EditorState>
```

`GameState` holds:
- Current board snapshot
- Player 1 & 2 hands and decks
- Whose turn it is
- List of pending `FlipEvent`s (drives animation queue)
- Turn history (for debugging / future undo)

---

## 7. Screen Flow

```
HomeScreen
  ├── [New Game] → SetupScreen
  │     ├── Select/edit board layout
  │     ├── Select/edit decks (P1, P2)
  │     ├── Configure rules
  │     └── [Start] → GameScreen
  │
  ├── [Card Editor] → CardEditorScreen
  │     └── Table of cards, each row = 6 side editors
  │
  ├── [Board Editor] → BoardEditorScreen
  │     └── Click hex grid to toggle active cells
  │
  └── [Rules Editor] → RulesEditorScreen
        └── Toggle/configure all GameRules fields
```

---

## 8. Game Screen Layout

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
│  Comparison overlay (on placement)  │
└─────────────────────────────────────┘
```

**ComparisonOverlay** appears after placement:
- Highlights the placed card's attacking sides
- Highlights affected neighbor sides
- Shows attacker vs. defender values side-by-side
- Animates flipped cards (background color transition)

---

## 9. Persistence — JSON Schema

### deck.json

```json
{
  "id": "deck_001",
  "name": "Default Deck",
  "cards": [
    {
      "id": "c1",
      "sides": [
        { "shape": "square",   "number": 4, "shapeColor": "#000000", "numberColor": "#FFFFFF" },
        { "shape": "circle",   "number": 3, "shapeColor": "#FF0000", "numberColor": "#FFFF00" },
        { "shape": "triangle", "number": 7, "shapeColor": "#0000FF", "numberColor": "#FFFFFF" },
        { "shape": "star",     "number": 2, "shapeColor": "#333333", "numberColor": "#FFFFFF" },
        { "shape": "diamond",  "number": 5, "shapeColor": "#009900", "numberColor": "#000000" },
        { "shape": "square",   "number": 6, "shapeColor": "#FF8800", "numberColor": "#000000" }
      ]
    }
  ]
}
```

### board.json

```json
{
  "id": "classic_19",
  "name": "Classic 19",
  "cells": [
    { "q": 0, "r": 0 },
    { "q": 1, "r": 0 },
    { "q": -1, "r": 0 }
  ]
}
```

### rules.json

```json
{
  "startingHandSize": 5,
  "cardsDrawnPerTurn": 1,
  "handLimit": 7,
  "deckSize": 20,
  "autoDrawEnabled": true,
  "placementRequired": true,
  "attackEligibility": {
    "mode": "allSides"
  },
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

## 10. Key Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.x
  path_provider: ^2.x
  uuid: ^4.x
  collection: ^1.x

dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.x
```

---

## 11. Critical Design Constraints

| Constraint | Implementation |
|---|---|
| Flip = ownership only | `HexCard.owner` is the only mutable field on a card |
| Side positions never change | `sides[i]` is fixed at card creation, never reassigned |
| No rotation on flip | No transform applied to card widget on ownership change |
| Side `i` always faces direction `i` | `side 0 = top-right, clockwise` — hardcoded in coordinate system |
| Opposing side formula | `(i + 3) % 6` — deterministic, no lookup table needed |
| Data-driven rules | `GameRules`, `AttackEligibilityRule`, `ComparisonRule` are plain data objects, JSON-serializable |
| No hard-coded shapes | `SymbolShape` is an enum loaded from config; comparison logic does not reference specific values |
| Board is data-driven | `BoardModel` is a coordinate map loaded from JSON; no hard-coded layouts |

---

## 12. Recommended Implementation Order

1. **Models** (`lib/models/`) — pure Dart, no Flutter dependency, fully unit testable
2. **Engine** (`lib/engine/`) — hex math, adjacency resolver, flip engine; unit tested in isolation
3. **State** (`lib/state/`) — Riverpod providers wiring models to UI layer
4. **Widgets** — `HexCardWidget` → `HexBoardWidget` → `HandWidget` → `ComparisonOverlay`
5. **Screens** — Card editor → Board editor → Rules editor → Setup → Game screen
6. **Persistence** — JSON load/save for decks, boards, and rules configs

---

## 13. Out of Scope (Prototype)

- AI opponent
- Networking / multiplayer over network
- Advanced animations beyond color transitions and side highlights
- Card art, titles, abilities, or asymmetric card faces
- Sound effects
