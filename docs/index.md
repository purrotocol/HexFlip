---
title: Home
layout: home
nav_order: 1
---

# HexFlip

A modular hex-based card game playtesting sandbox built with Flutter.

**Targets:** Linux desktop · Windows desktop · Web
{: .fs-5 }

[View on GitHub](https://github.com/YOUR_USER/HexFlip){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }

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

| Feature | Description |
|---|---|
| Hex grid board | Flat-top axial coordinates, pan/zoom support, Classic 19-cell and Small 7-cell layouts |
| Card editor | Create and edit decks with per-side shape, number, and color |
| Board editor | Toggle cells on/off to design custom board shapes (range ±4) |
| Rules editor | Configure hand size, draw rate, attack eligibility mode, and comparison conditions without writing code |
| Comparison overlay | Post-placement breakdown of every attacker/defender matchup |
| Flip highlighting | Green border on flipped cells, yellow on selected target |
| Data-driven persistence | Decks, boards, and rules saved as JSON under the app documents directory |

---

## Architecture overview

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

See [Architecture](architecture) for the full design breakdown and [Code Reference](reference) for per-file documentation.

---

## Building

**Prerequisites:** Flutter 3.10+, Dart 3.0+

```bash
# Get dependencies
flutter pub get

# Run in debug mode
flutter run -d linux       # Linux
flutter run -d chrome      # Web

# Release builds
flutter build linux
flutter build windows      # Windows host required
flutter build web
```

---

## Project status

Active development. Current known gaps:

- Save buttons in the Rules, Board, and Card editors update in-memory state but do not yet write to disk — changes are lost on restart.
- `test/widget_test.dart` is a Flutter scaffold placeholder and will fail.
- `shared_preferences` is declared but unused; all persistence uses JSON files.

---

## License

MIT
