import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

/// Handles all file-system and asset I/O for HexFlip.
///
/// Persisted data lives under `<appDoc>/hexflip/` in three subdirectories:
///   - `decks/`   – one JSON file per [DeckModel]
///   - `boards/`  – one JSON file per [BoardModel]
///   - `rules/`   – one JSON file per named [GameRules]
///
/// Default assets are loaded from `assets/configs/` via [rootBundle].
class StorageService {
  static const String _root = 'hexflip';
  static const String _decksDir = 'decks';
  static const String _boardsDir = 'boards';
  static const String _rulesDir = 'rules';

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Returns the absolute path to the app's documents directory.
  Future<String> get _appDocPath async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  /// Ensures the target directory exists and returns a [File] handle for
  /// `<appDoc>/<root>/<subDir>/<id>.json`.
  Future<File> _fileFor(String subDir, String id) async {
    final basePath = await _appDocPath;
    final dir = Directory('$basePath/$_root/$subDir');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File('${dir.path}/$id.json');
  }

  // ---------------------------------------------------------------------------
  // Decks
  // ---------------------------------------------------------------------------

  /// Serialises [deck] and writes it to `<appDoc>/hexflip/decks/<id>.json`.
  Future<void> saveDeck(DeckModel deck) async {
    final file = await _fileFor(_decksDir, deck.id);
    await file.writeAsString(jsonEncode(deck.toJson()), flush: true);
  }

  /// Reads and deserialises the deck with [id].
  ///
  /// Returns `null` if the file does not exist or fails to parse.
  Future<DeckModel?> loadDeck(String id) async {
    try {
      final file = await _fileFor(_decksDir, id);
      if (!await file.exists()) return null;
      final contents = await file.readAsString();
      return DeckModel.fromJson(
          jsonDecode(contents) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Loads every `.json` file from the decks directory.
  ///
  /// Files that fail to parse are silently skipped.
  Future<List<DeckModel>> loadAllDecks() async {
    final basePath = await _appDocPath;
    final dir = Directory('$basePath/$_root/$_decksDir');
    if (!await dir.exists()) return [];

    final decks = <DeckModel>[];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        try {
          final contents = await entity.readAsString();
          decks.add(DeckModel.fromJson(
              jsonDecode(contents) as Map<String, dynamic>));
        } catch (_) {
          // Skip malformed files.
        }
      }
    }
    return decks;
  }

  /// Deletes the persisted deck file for [id].
  ///
  /// No-ops silently if the file does not exist.
  Future<void> deleteDeck(String id) async {
    try {
      final file = await _fileFor(_decksDir, id);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Boards
  // ---------------------------------------------------------------------------

  /// Serialises [board] and writes it to `<appDoc>/hexflip/boards/<id>.json`.
  Future<void> saveBoard(BoardModel board) async {
    final file = await _fileFor(_boardsDir, board.id);
    await file.writeAsString(jsonEncode(board.toJson()), flush: true);
  }

  /// Reads and deserialises the board with [id].
  ///
  /// Returns `null` if the file does not exist or fails to parse.
  Future<BoardModel?> loadBoard(String id) async {
    try {
      final file = await _fileFor(_boardsDir, id);
      if (!await file.exists()) return null;
      final contents = await file.readAsString();
      return BoardModel.fromJson(
          jsonDecode(contents) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Loads every `.json` file from the boards directory.
  ///
  /// Files that fail to parse are silently skipped.
  Future<List<BoardModel>> loadAllBoards() async {
    final basePath = await _appDocPath;
    final dir = Directory('$basePath/$_root/$_boardsDir');
    if (!await dir.exists()) return [];

    final boards = <BoardModel>[];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        try {
          final contents = await entity.readAsString();
          boards.add(BoardModel.fromJson(
              jsonDecode(contents) as Map<String, dynamic>));
        } catch (_) {
          // Skip malformed files.
        }
      }
    }
    return boards;
  }

  /// Deletes the persisted board file for [id].
  ///
  /// No-ops silently if the file does not exist.
  Future<void> deleteBoard(String id) async {
    try {
      final file = await _fileFor(_boardsDir, id);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Rules
  // ---------------------------------------------------------------------------

  /// Serialises [rules] and writes it to
  /// `<appDoc>/hexflip/rules/<name>.json`.
  Future<void> saveRules(GameRules rules, String name) async {
    final file = await _fileFor(_rulesDir, name);
    await file.writeAsString(jsonEncode(rules.toJson()), flush: true);
  }

  /// Reads and deserialises the rules preset called [name].
  ///
  /// Returns `null` if the file does not exist or fails to parse.
  Future<GameRules?> loadRules(String name) async {
    try {
      final file = await _fileFor(_rulesDir, name);
      if (!await file.exists()) return null;
      final contents = await file.readAsString();
      return GameRules.fromJson(
          jsonDecode(contents) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Asset defaults
  // ---------------------------------------------------------------------------

  /// Loads a [BoardModel] from `assets/configs/<assetName>.json`.
  ///
  /// Throws if the asset does not exist or cannot be parsed.
  Future<BoardModel> loadDefaultBoard(String assetName) async {
    final raw = await rootBundle
        .loadString('assets/configs/$assetName');
    return BoardModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Loads a [DeckModel] from `assets/configs/<assetName>.json`.
  ///
  /// Throws if the asset does not exist or cannot be parsed.
  Future<DeckModel> loadDefaultDeck(String assetName) async {
    final raw = await rootBundle
        .loadString('assets/configs/$assetName');
    return DeckModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Loads the built-in [GameRules] from `assets/configs/default_rules.json`.
  ///
  /// Throws if the asset does not exist or cannot be parsed.
  Future<GameRules> loadDefaultRules() async {
    final raw = await rootBundle
        .loadString('assets/configs/default_rules.json');
    return GameRules.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
  }
}
