import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sbrai_solutions/models/favorite_item.dart';
import 'package:sbrai_solutions/buyer/screens/home_screen.dart';
import 'package:sbrai_solutions/l10n/app_localizations.dart';
import 'package:sbrai_solutions/mixins/translation_mixin.dart';
import 'package:sbrai_solutions/providers/favorite_provider.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen>
    with TranslationMixin<FavoriteScreen> {
  static const _orange = Color(0xFFE85D22);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFavorites());
  }

  Future<void> _loadFavorites() async {
    try {
      await Provider.of<FavoriteProvider>(
        context,
        listen: false,
      ).fetchFavorites();
      if (mounted) _performTranslation();
    } catch (e) {
      debugPrint('FavoriteScreen load error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load favorites')),
        );
      }
    }
  }

  Future<void> _performTranslation() async {
    final items = Provider.of<FavoriteProvider>(
      context,
      listen: false,
    ).favorites;
    if (items.isEmpty) return;

    await translateIfNeeded(
      items: items,
      onTranslate: (targetLang) async {
        if (!mounted) return;
        setState(() => isTranslating = true);
        final futures = <Future<void>>[];

        for (final item in items) {
          futures.add(
            translateText(item.name, targetLang).then((t) {
              if (t != null && mounted) {
                setState(() => translatedNames[item.id] = t);
              }
            }),
          );
        }

        await Future.wait(futures);
        if (mounted) setState(() => isTranslating = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<FavoriteProvider>(
      builder: (context, provider, _) {
        final items = provider.favorites;

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
                  '${items.length} ${l10n.items}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            actions: [
              if (isTranslating || provider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _orange,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator(color: _orange))
              : items.isEmpty
              ? _buildEmptyState(l10n)
              : RefreshIndicator(
                  color: _orange,
                  onRefresh: _loadFavorites,
                  child: _buildFavoritesList(items, provider),
                ),
        );
      },
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
            l10n.noItemsFound,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Save items you like to view them later',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: 200,
            height: 45,
            child: ElevatedButton(
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Start Shopping',
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

  Widget _buildFavoritesList(
    List<FavoriteItem> items,
    FavoriteProvider provider,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final displayName = translatedNames[item.id] ?? item.name;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.imageUrl.isNotEmpty
                  ? Image.network(
                      item.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
            ),
            title: Text(
              displayName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '₦${_formatPrice(item.price)}',
              style: const TextStyle(
                color: _orange,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.favorite, color: _orange),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await provider.removeFromFavorites(item.id);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('$displayName removed from favorites'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000) return '${(price / 1000000).toStringAsFixed(1)}M';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}K';
    return price.toStringAsFixed(0);
  }
}
