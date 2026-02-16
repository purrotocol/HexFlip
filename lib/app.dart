import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hexflip/persistence/storage_service.dart';
import 'package:hexflip/state/state.dart';
import 'package:hexflip/screens/home_screen.dart';
import 'package:hexflip/widgets/app_colors.dart';

class HexFlipApp extends StatelessWidget {
  const HexFlipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HexFlip',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          surface: AppColors.surface,
        ),
        cardColor: AppColors.surface,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: AppColors.text),
        ),
      ),
      home: const _AppLoader(),
    );
  }
}

/// Loads persisted and default data before showing [HomeScreen].
class _AppLoader extends ConsumerStatefulWidget {
  const _AppLoader();

  @override
  ConsumerState<_AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends ConsumerState<_AppLoader> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  Future<void> _loadDefaults() async {
    final storage = StorageService();

    // Load any previously saved decks from disk.
    final savedDecks = await storage.loadAllDecks();
    if (savedDecks.isNotEmpty) {
      final deckMap = {for (final d in savedDecks) d.id: d};
      ref.read(decksProvider.notifier).loadDecks(deckMap);
    } else {
      // Fall back to the bundled default deck asset.
      try {
        final defaultDeck = await storage.loadDefaultDeck('default_deck.json');
        ref.read(decksProvider.notifier).addOrUpdateDeck(defaultDeck);
      } catch (_) {}
    }

    // Load saved rules if any.
    try {
      final savedRules = await storage.loadRules('last_rules');
      if (savedRules != null) {
        ref.read(gameRulesProvider.notifier).update(savedRules);
      } else {
        final defaultRules = await storage.loadDefaultRules();
        ref.read(gameRulesProvider.notifier).update(defaultRules);
      }
    } catch (_) {}

    // Load saved boards if any.
    final savedBoards = await storage.loadAllBoards();
    if (savedBoards.isNotEmpty) {
      ref.read(activeBoardProvider.notifier).loadBoard(savedBoards.first);
    }

    if (mounted) setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'HexFlip',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(color: AppColors.accent),
            ],
          ),
        ),
      );
    }
    return const HomeScreen();
  }
}
