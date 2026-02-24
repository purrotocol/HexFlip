---
title: Rules Configuration
layout: default
nav_order: 4
---

# Rules Configuration
{: .no_toc }

Every aspect of gameplay is driven by data. Rules can be changed at runtime in the Rules Editor and are persisted as JSON.
{: .fs-6 .fw-300 }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## GameRules fields

| Field | Type | Default | Description |
|---|---|---|---|
| `startingHandSize` | int | 5 | Cards dealt to each player at game start |
| `cardsDrawnPerTurn` | int | 1 | Cards drawn when auto-draw fires or Draw is pressed |
| `handLimit` | int | 7 | Maximum cards in hand at any time |
| `deckSize` | int | 10 | How many cards to take from the deck template |
| `autoDrawEnabled` | bool | true | Draw automatically at the start of each turn |
| `placementRequired` | bool | true | Player must place a card each turn |
| `attackEligibility` | AttackEligibilityRule | allSides | Which card sides can initiate a comparison |
| `comparisonRule` | ComparisonRule | numberGreater | How flip success is determined |

---

## Attack eligibility

`AttackEligibilityRule.sideCanAttack(side)` returns true/false for each attacking side.

### Modes (`AttackMode`)

| Mode | Description |
|---|---|
| `allSides` | Every side can attack — default |
| `specificShape` | Only sides whose shape matches `requiredShape` |
| `specificColor` | Only sides whose shape color matches `requiredColor` |
| `shapeAndColor` | Only sides matching both `requiredShape` **and** `requiredColor` |

### JSON structure

```json
{
  "attackEligibility": {
    "mode": "specificShape",
    "requiredShape": "star"
  }
}
```

With `allSides`, only `mode` is required.

---

## Comparison rule

Given two eligible sides, `ComparisonRule.attackSucceeds(attacker, defender)` checks all **enabled conditions in order**. All enabled conditions must pass for the flip to succeed.

| Field | Type | Default | Effect when `true` |
|---|---|---|---|
| `requireNumberGreater` | bool | true | `attacker.number > defender.number` |
| `allowEqual` | bool | false | `attacker.number >= defender.number` (only meaningful with `requireNumberGreater: true`) |
| `requireShapeMatch` | bool | false | `attacker.shape == defender.shape` |
| `requireColorMatch` | bool | false | `attacker.shapeColor == defender.shapeColor` |
| `requireBothShapeAndColor` | bool | false | Both shape and color must match simultaneously |

Setting all boolean fields to `false` means every eligible comparison succeeds automatically.

### JSON structure

```json
{
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

## Default rules (complete JSON)

This is the content of `assets/configs/default_rules.json`:

```json
{
  "startingHandSize": 5,
  "cardsDrawnPerTurn": 1,
  "handLimit": 7,
  "deckSize": 10,
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

## Example rule variations

### Pure number game (default)

Every side attacks. A side flips a neighbor only if its number is strictly higher.

```json
{
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

### Shape-locked combat

Only sides with a matching shape can flip each other. Numbers are ignored.

```json
{
  "attackEligibility": { "mode": "allSides" },
  "comparison": {
    "requireNumberGreater": false,
    "allowEqual": false,
    "requireShapeMatch": true,
    "requireColorMatch": false,
    "requireBothShapeAndColor": false
  }
}
```

### Star-side sniper

Only star-shaped sides can attack, and still require a number advantage.

```json
{
  "attackEligibility": {
    "mode": "specificShape",
    "requiredShape": "star"
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

### Tie-allowed combat

Numbers must be greater-or-equal (attacker can tie and still flip).

```json
{
  "attackEligibility": { "mode": "allSides" },
  "comparison": {
    "requireNumberGreater": true,
    "allowEqual": true,
    "requireShapeMatch": false,
    "requireColorMatch": false,
    "requireBothShapeAndColor": false
  }
}
```

---

## Persistence

Rules are stored at:

```
<appDocDir>/hexflip/rules/<name>.json
```

The in-session rules are saved with the key `last_rules` and restored on next launch. The Rules Editor's Save button currently updates in-memory state and shows a confirmation SnackBar; full disk persistence is wired at startup via `StorageService.loadRules('last_rules')`.
