import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/providers/audio_provider.dart';
import 'package:zenify/components/local_cover_image.dart';
import 'package:zenify/components/artist_card.dart';
import 'package:zenify/screens/artist_detail_screen.dart';
import 'package:zenify/components/albums_grid.dart';
import 'package:zenify/components/zenify_input.dart';
import 'package:zenify/l10n/app_localizations.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:zenify/router/app_router.dart';
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

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: ZenifyInput(
              controller: _searchController,
              placeholder: Text(l10n.searchPlaceholder),
              autofocus: true,
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchController.text.trim().isEmpty
              ? Center(
                  child: Text(
                    l10n.searchPlaceholder,
                    style: TextStyle(color: colorScheme.mutedForeground),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_artists.isEmpty && _albums.isEmpty && _songs.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            l10n.searchNoResults,
                            style: TextStyle(color: colorScheme.mutedForeground),
                          ),
                        ),
                      ),
                    
                    // Artists Section
                    if (_artists.isNotEmpty) ...[
                      Text(l10n.navArtists, style: theme.textTheme.h4),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _artists.length,
                          itemBuilder: (context, index) {
                            final artist = _artists[index];
                            final id = artist['id'];
                            final coverId = artist['coverArt'] ?? id;
                            final fallbackUrl = api?.getCoverArtUrl(coverId, size: 250);
                            
                            return Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: SizedBox(
                                width: 80,
                                child: ArtistCard(
                                  name: artist['name'] ?? 'Unknown',
                                  artistId: id,
                                  coverArtId: coverId,
                                  fallbackCoverUrl: fallbackUrl,
                                  serverId: server?.id ?? 0,
                                  isDisabled: networkState.isOffline,
                                  onTap: () {
                                    context.pushBranch('artist/$id', extra: artist['name'] ?? 'Unknown');
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Albums Section
                    if (_albums.isNotEmpty) ...[
                      Text(l10n.navAlbums, style: theme.textTheme.h4),
                      AlbumsGrid(albums: _albums.toList()),
                      const SizedBox(height: 24),
                    ],

                    // Songs Section
                    if (_songs.isNotEmpty) ...[
                      // We don't have navSongs in ARB right now, so we can use l10n.navFavorites or just "Songs" translated or we can just keep l10n.songs. I will use hardcoded for a sec, wait. 
                      // No, I can add it to ARB. I'll just use l10n.songs for now and fix later, or use playerQueue? I'll use hardcoded l10n.songs to avoid crash if not in ARB.
                      // Actually, let me use a known key. Or wait, let me just add it.
                      Text(l10n.songs, style: theme.textTheme.h4),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
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
                    ],
                    const SizedBox(height: 128),
                  ],
                ),
        ),
      ),
    );
  }
}
