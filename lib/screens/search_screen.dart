import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/providers/audio_provider.dart';
import 'package:zenify/components/local_cover_image.dart';
import 'package:zenify/components/artist_card.dart';

import 'package:zenify/components/albums_grid.dart';
import 'package:zenify/components/zenify_input.dart';
import 'package:zenify/l10n/app_localizations.dart';
import 'dart:async';
import 'package:zenify/components/group_tab_bar.dart';
import 'package:zenify/router/app_router.dart';
import 'package:zenify/utils/responsive.dart';
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  
  bool _isLoading = false;
  List<dynamic> _artists = [];
  List<dynamic> _albums = [];
  List<dynamic> _songs = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (query.trim().isEmpty) {
      setState(() {
        _artists = [];
        _albums = [];
        _songs = [];
        _isLoading = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
    });

    final api = ref.read(subsonicApiProvider);
    if (api != null) {
      final results = await api.search3(query);
      if (mounted) {
        setState(() {
          _artists = results['artists'] ?? [];
          _albums = results['albums'] ?? [];
          _songs = results['songs'] ?? [];
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final server = ref.watch(activeServerProvider).value;
    final api = ref.watch(subsonicApiProvider);
    final networkState = ref.watch(networkProvider);

    final activeTabs = <Widget>[];
    final activeViews = <Widget>[];

    if (_albums.isNotEmpty) {
      activeTabs.add(
        Tab(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.disc, size: 16),
              const SizedBox(width: 6),
              Text(l10n.navAlbums),
            ],
          ),
        ),
      );
      activeViews.add(
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AlbumsGrid(albums: _albums.toList()),
        ),
      );
    }

    if (_songs.isNotEmpty) {
      activeTabs.add(
        Tab(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.music, size: 16),
              const SizedBox(width: 6),
              Text(l10n.songs),
            ],
          ),
        ),
      );
      activeViews.add(
        ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _songs.length,
          itemBuilder: (context, index) {
            final song = _songs[index];
            final coverId = song['coverArt'] ?? song['albumId'];
            final fallbackUrl = api != null && coverId != null ? api.getCoverArtUrl(coverId, size: 250) : null;
            final duration = _formatDuration(song['duration'] as int? ?? 0);

            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: LocalCoverImage(
                    id: song['albumId']?.toString() ?? coverId ?? '',
                    serverId: server?.id ?? 0,
                    fallbackUrl: fallbackUrl,
                    isThumb: true,
                  ),
                ),
              ),
              title: Text(song['title'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(song['artist'] ?? '', style: TextStyle(color: colorScheme.mutedForeground)),
              trailing: Text(duration, style: TextStyle(color: colorScheme.mutedForeground)),
              onTap: () {
                ref.read(audioProvider.notifier).playQueue(_songs, index);
              },
            );
          },
        ),
      );
    }

    if (_artists.isNotEmpty) {
      activeTabs.add(
        Tab(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.user, size: 16),
              const SizedBox(width: 6),
              Text(l10n.navArtists),
            ],
          ),
        ),
      );
      activeViews.add(
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: _artists.map((artist) {
              final id = artist['id'];
              final coverId = artist['coverArt'] ?? id;
              final fallbackUrl = api?.getCoverArtUrl(coverId, size: 250);
              return SizedBox(
                width: 100,
                child: ArtistCard(
                  name: artist['name'] ?? 'Unknown',
                  artistId: id,
                  coverArtId: coverId,
                  fallbackCoverUrl: fallbackUrl,
                  serverId: server?.id ?? 0,
                  isDisabled: networkState.isOffline,
                  onTap: () {
                    context.pushBranch('artist/', extra: artist['name'] ?? 'Unknown');
                  },
                ),
              );
            }).toList(),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: getResponsiveMaxWidth(context)),
            child: ZenifyInput(
              controller: _searchController,
              placeholder: Text(l10n.searchPlaceholder),
              autofocus: true,
              onChanged: _onSearchChanged,
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: getResponsiveMaxWidth(context)),
          child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchController.text.trim().isEmpty
              ? Center(
                  child: Text(
                    l10n.searchPlaceholder,
                    style: TextStyle(color: colorScheme.mutedForeground),
                  ),
                )
              : activeTabs.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          l10n.searchNoResults,
                          style: TextStyle(color: colorScheme.mutedForeground),
                        ),
                      ),
                    )
                  : DefaultTabController(
                      length: activeTabs.length,
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: GroupTabBar(
                              tabs: activeTabs,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: TabBarView(
                              children: activeViews,
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}
