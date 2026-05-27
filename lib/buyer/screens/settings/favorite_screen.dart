import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sbrai_solutions/models/favorite_item.dart';
import 'package:sbrai_solutions/buyer/screens/home_screen.dart';
import 'package:sbrai_solutions/l10n/app_localizations.dart';
import 'package:sbrai_solutions/mixins/translation_mixin.dart';
import 'package:sbrai_solutions/providers/language_provider.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> with TranslationMixin<FavoriteScreen> {
  // Mock list: Once integrated with API, this will be fetched
  List<FavoriteItem> favoriteItems = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _performTranslation();
  }

  Future<void> _performTranslation() async {
    if (favoriteItems.isEmpty) return;

    await translateIfNeeded(
      items: favoriteItems,
      onTranslate: (targetLang) async {
        setState(() => isTranslating = true);
        final futures = <Future<void>>[];

        for (final item in favoriteItems) {
          final key = item.id.toString();
          futures.add(translateText(item.name, targetLang).then((t) {
            if (t != null && mounted) setState(() => translatedNames[key] = t);
          }));
          // If FavoriteItem has a location field, translate it here
        }

        await Future.wait(futures);
        if (mounted) setState(() => isTranslating = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.favorites,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${favoriteItems.length} ${l10n.items}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          if (isTranslating)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
        ],
      ),
      body: favoriteItems.isEmpty ? _buildEmptyState(l10n) : _buildFavoritesList(),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border,
              size: 60,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.noItemsFound, // You can use a more specific key if added to .arb
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Save items you like to view them later', // Recommended to add to .arb
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: 200,
            height: 45,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7043),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Start Shopping', // Recommended to add to .arb
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    return ListView.builder(
      itemCount: favoriteItems.length,
      itemBuilder: (context, index) {
        final item = favoriteItems[index];
        final displayName = translatedNames[item.id.toString()] ?? item.name;

        return ListTile(
          title: Text(displayName),
          subtitle: Text('₦${item.price}'),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              setState(() {
                favoriteItems.removeAt(index);
              });
            },
          ),
        );
      },
    );
  }
}
