# HexFlip — Agent Instructions

Instructions for AI coding agents (Codex, etc.) working in this repository.

---

## Project summary

HexFlip is a Flutter/Dart desktop and web app for playtesting a configurable hex-based card game. It is a mechanics testbed — not a finished product. Everything gameplay-relevant (card values, board shape, attack logic, comparison rules) is configured via JSON data files. No hard-coded game logic.

**Language:** Dart 3.0+ / Flutter 3.10+  
**State:** `flutter_riverpod` (manual `StateNotifier` — no code generation)  
**Persistence:** JSON files via `path_provider` + bundled assets  
**Targets:** Linux desktop, Windows desktop, Web

---

## Repo structure

| Path | Contents |
|---|---|
| `lib/models/` | Pure Dart data classes. No Flutter widgets, no state. |
| `lib/engine/` | Stateless business logic. No Flutter, no Riverpod. |
| `lib/state/` | Riverpod `StateNotifier` providers. |
| `lib/screens/` | Full-screen UI pages. |
| `lib/widgets/` | Reusable Flutter widgets and `AppColors`. |
| `lib/persistence/` | `StorageService` — all file I/O. |
| `assets/configs/` | Bundled JSON defaults for deck, boards, rules. |
| `docs/` | GitHub Pages site (Jekyll, just-the-docs). |

---

## Before making any change

1. Read the relevant source file(s) fully before editing.
2. Check `DESIGN.md` for original architectural intent.
3. Check `INDEX.md` for per-file documentation.
4. Run `flutter analyze` after any Dart change and fix all warnings before finishing.

---

## Absolute rules

### Never violate these

- **`HexCard.sides` is immutable.** Never reassign or mutate a card's `sides` list after construction. `owner` is the only field that may change after a card is created.
- **`(i + 3) % 6` is the opposing side formula.** Do not replace it with a map or switch.
- **Engine code has no Flutter dependency.** Nothing in `lib/engine/` or `lib/models/` may import `package:flutter`. `dart:ui` (Color) and `dart:math` are acceptable.
- **All engine methods are static.** No instance state in the engine layer.
- **All colors come from `AppColors`.** Do not hardcode `Color(0xFF...)` literals in widget files.
- **All file I/O goes through `StorageService`.** Do not call `path_provider` directly from screens or widgets.
- **Providers are declared only in `lib/state/providers.dart`.** Do not scatter `Provider(...)` declarations elsewhere.

---

## Hex geometry

Flat-top axial coordinates `(q, r)`. Side index = direction index:

```
0 = top-right     (+1, -1)
1 = right         (+1,  0)
2 = bottom-right  ( 0, +1)
3 = bottom-left   (-1, +1)
4 = left          (-1,  0)
5 = top-left      ( 0, -1)
```

All hex geometry lives in `lib/engine/hex_math.dart`. Do not duplicate pixel↔axial conversion logic elsewhere.

---

## Adding a new rule field

1. Add the field to `GameRules` in `lib/models/rules/game_rules.dart` with a default value.
2. Update `GameRules.fromJson`, `toJson`, and `copyWith`.
3. Add a setter to `GameRulesNotifier` in `lib/state/game_rules_notifier.dart`.
4. Wire it into the relevant engine method (`AttackEligibilityRule.sideCanAttack` or `ComparisonRule.attackSucceeds`).
5. Add a control for it in `lib/screens/rules_editor_screen.dart`.

---

## Adding a new screen

1. Create `lib/screens/<name>_screen.dart`.
2. Use `ConsumerStatefulWidget` if local state is needed, `ConsumerWidget` if not.
3. Navigate to it via `Navigator.push` from `HomeScreen` or `SetupScreen`.
4. Do not introduce named routes.

---

## Testing guidance

- Engine classes (`HexMath`, `AdjacencyResolver`, `FlipEngine`, `TurnManager`, `DeckManager`) are pure/static — test them without Flutter infrastructure using `dart test`.
- Use `mocktail` (already in dev deps) for mocking `StorageService` in tests.
- Do not modify `test/widget_test.dart` — it is a known-failing scaffold placeholder.
- New test files go in `test/` following the pattern `<source_file_stem>_test.dart`.

---

## Formatting and linting

```bash
dart format lib/ test/
flutter analyze
```

Both must pass with zero issues before a change is considered complete. The linter enforces `prefer_const_constructors` and all standard `flutter_lints` rules.

---

## Building

```bash
flutter pub get          # install dependencies

flutter run -d linux     # Linux debug
flutter run -d chrome    # Web debug

flutter build linux      # Linux release
flutter build windows    # Windows release (Windows host required)
flutter build web        # Web release
```

---

## Out of scope — do not implement

- AI opponent
- Network multiplayer
- Sound effects
- Card art, titles, or asymmetric card faces
- `riverpod_generator` code-gen (declared in deps but intentionally unused)
