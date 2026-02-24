# HexFlip — Claude Context

This file gives Claude the context needed to work effectively in this repository.

---

## What this project is

HexFlip is a Flutter/Dart playtesting sandbox for a configurable hexagonal card game. It targets Linux desktop, Windows desktop, and Web. The codebase is a mechanics testbed — not a finished game — built for fast rule iteration without touching code.

**Stack:** Flutter 3.10+ / Dart 3.0+, `flutter_riverpod` state management, `path_provider` + JSON file persistence.

---

## Repository layout

```
lib/
  main.dart                     Entry point — wraps app in ProviderScope
  app.dart                      HexFlipApp + _AppLoader startup widget
  models/                       Pure Dart data classes, JSON-serializable
    card_side.dart              CardSide (shape, number, colors) + SymbolShape enum
    card_model.dart             HexCard (6 sides, mutable owner) + PlayerOwner enum
    deck_model.dart             DeckModel (named list of HexCard templates)
    hex_cell.dart               AxialCoord (q, r) + HexCell (coord, isActive, card?)
    board_model.dart            BoardModel — Map<AxialCoord, HexCell>
    player.dart                 Player — hand, deck, score, draw()
    game_state.dart             GameState — live board + players + phase + events
    rules/
      game_rules.dart           All configurable rule fields
      attack_eligibility.dart   AttackEligibilityRule + AttackMode enum
      comparison_rule.dart      ComparisonRule — flip success conditions
  engine/                       Stateless, Flutter-free business logic
    hex_math.dart               neighborAt, oppositeSide, hexToPixel, pixelToHex, sideRotationRadians
    adjacency_resolver.dart     Core flip logic — 6-direction comparison loop
    flip_engine.dart            Wraps AdjacencyResolver results into FlipResult
    turn_manager.dart           placeCard, endTurn, isGameOver, computeFinalScores
    deck_manager.dart           shuffle, buildPlayer, dealStartingHand
  state/                        Riverpod StateNotifier providers
    providers.dart              All provider declarations
    game_state_notifier.dart    startGame, placeCard, endTurn, drawCard, resetGame
    board_notifier.dart         loadBoard, toggleCell, setName, clearCards
    decks_notifier.dart         addOrUpdateDeck, removeDeck, loadDecks
    game_rules_notifier.dart    Per-field setters + bulk update()
    setup_deck_selection_notifier.dart  Transient P1/P2 deck selection
  screens/                      Full-screen UI pages
    home_screen.dart
    setup_screen.dart
    game_screen.dart
    card_editor_screen.dart
    board_editor_screen.dart
    rules_editor_screen.dart
  widgets/                      Reusable UI components
    app_colors.dart             All colors as static const — dark purple-navy theme
    hex_board_widget.dart       CustomPainter board renderer + InteractiveViewer
    hex_card_widget.dart        Single card renderer
    hand_widget.dart            Horizontal scrollable hand
    comparison_overlay.dart     Post-placement comparison modal
  persistence/
    storage_service.dart        JSON file I/O under <appDocDir>/hexflip/

assets/configs/
  default_deck.json             10 cards, each with 6 sides
  classic_board.json            19-cell hex board
  small_board.json              7-cell hex board
  default_rules.json            Default rule set

docs/                           GitHub Pages site (Jekyll, just-the-docs theme)
```

---

## Core invariants — never break these

| Invariant | Detail |
|---|---|
| Flip = ownership only | `HexCard.owner` is the ONLY mutable field on a card. `sides` is final and never changes. |
| Side positions fixed | `sides[i]` is set at construction. Index 0 = top-right, clockwise to 5 = top-left. |
| Opposing side formula | `(i + 3) % 6` — hardcoded in `HexMath.oppositeSide`. Never use a lookup table. |
| Side `i` always faces direction `i` | `AxialCoord.directions[i]` is the canonical direction for `sides[i]`. |
| Flat-top hexagon | All geometry uses flat-top formulas. Do not mix in pointy-top math. |
| Engine is Flutter-free | Nothing in `lib/engine/` or `lib/models/` may import Flutter widgets. `dart:ui` (for `Color`) and `dart:math` are acceptable. |
| Engine is stateless | All engine methods are `static`. They receive model objects and return results. They do not hold references to state or providers. |

---

## Hex coordinate system

Axial coordinates `(q, r)`, flat-top layout. Side index maps to axial direction:

```
Side 0 = top-right     (+1, -1)
Side 1 = right         (+1,  0)
Side 2 = bottom-right  ( 0, +1)
Side 3 = bottom-left   (-1, +1)
Side 4 = left          (-1,  0)
Side 5 = top-left      ( 0, -1)
```

Pixel from axial (flat-top):
- `x = size * (3/2 * q)`
- `y = size * (sqrt(3)/2 * q + sqrt(3) * r)`

---

## State management pattern

- Providers are in `lib/state/providers.dart`. Do not create providers outside that file.
- `GameState` is a **mutable** Dart object. `GameStateNotifier` overrides `updateShouldNotify` to always return `true`, and uses a null-swap `_notify()` trick to force Riverpod to fire change events.
- All other notifiers use `copyWith` to produce new immutable instances — standard Riverpod pattern.
- UI widgets read state via `ref.watch`; they trigger changes via `ref.read(provider.notifier).method()`.

---

## Coding conventions

- Dart: follow `analysis_options.yaml` (flutter_lints + `prefer_const_constructors`).
- All model classes: provide `fromJson` / `toJson` and `copyWith`.
- New engine functions: `static` methods on a class or module-level functions; no instance state.
- Colors: always use `AppColors` constants from `lib/widgets/app_colors.dart`. Do not inline hex color literals in widget code.
- UUID generation: use the `uuid` package (`const Uuid().v4()`).
- File I/O: all persistence goes through `StorageService`. Do not call `path_provider` or read files directly in screen/widget code.

---

## Key behaviours to be aware of

- **Preview pattern in GameScreen:** `_previewAdjacency(...)` is a read-only run of `AdjacencyResolver` (no `flip()` calls) that collects comparison data for the overlay. The actual mutation happens separately in `TurnManager.placeCard`. Do not merge these two calls.
- **Startup sequence:** `_AppLoader._loadDefaults` in `app.dart` loads decks → rules → boards from disk, falling back to bundled assets if nothing is saved. All providers must be ready before HomeScreen appears.
- **`isActive` vs occupied:** A cell can be `isActive: true` with `card == null` (empty playable cell). A cell with `isActive: false` is off the board and must never receive a card.
- **GamePhase:** `setup → playing → ended`. `TurnManager.placeCard` does not advance the phase — `GameStateNotifier._checkGameOver` does.

---

## What is intentionally not here

- AI opponent — out of scope
- Network multiplayer — out of scope
- Card art, titles, abilities, or asymmetric card faces — out of scope
- Sound effects — out of scope
- `riverpod_generator` code-gen — declared in dev deps but not wired; use manual providers

---

## Current known gaps

- Rules, Board, and Card editors write changes to in-memory state but do not yet persist to disk on save. Changes survive the session but are lost on restart.
- `test/widget_test.dart` is an unmodified Flutter scaffold placeholder — it references `MyApp` and will fail.
- `shared_preferences` is in pubspec but unused. All persistence uses JSON files via `StorageService`.
