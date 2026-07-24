import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/providers/audio_provider.dart';
import 'package:zenify/components/local_cover_image.dart';
import 'package:zenify/components/artist_card.dart';
import 'package:zenify/screens/artist_detail_screen.dart';
import 'package:zenify/components/albums_grid.dart';
import 'dart:async';

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
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final server = ref.watch(activeServerProvider).value;
    final api = ref.watch(subsonicApiProvider);

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: ShadInput(
          controller: _searchController,
          placeholder: const Text('搜尋歌手、專輯、歌曲...'),
          onChanged: _onSearchChanged,
          autofocus: true,
          decoration: const ShadDecoration(
            border: ShadBorder.none,
            focusedBorder: ShadBorder.none,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchController.text.trim().isEmpty
              ? Center(
                  child: Text(
                    '輸入關鍵字開始搜尋',
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
                            '找不到相關結果',
                            style: TextStyle(color: colorScheme.mutedForeground),
                          ),
                        ),
                      ),
                    
                    // Artists Section
                    if (_artists.isNotEmpty) ...[
                      Text('歌手', style: theme.textTheme.h4),
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
                            final fallbackUrl = api != null ? api.getCoverArtUrl(coverId, size: 250) : null;
                            
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
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        settings: RouteSettings(name: artist['name'] ?? 'Unknown'),
                                        builder: (context) => ArtistDetailScreen(
                                          artistId: id,
                                          artistName: artist['name'] ?? 'Unknown',
                                        ),
                                      ),
                                    );
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
                      Text('專輯', style: theme.textTheme.h4),
                      AlbumsGrid(albums: _albums.toList()),
                      const SizedBox(height: 24),
                    ],

                    // Songs Section
                    if (_songs.isNotEmpty) ...[
                      Text('歌曲', style: theme.textTheme.h4),
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
                                  id: coverId ?? '',
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
    );
  }
}
