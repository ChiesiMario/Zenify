import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router/go_router.dart';
import 'package:zenify/screens/home_screen.dart';
import 'package:zenify/screens/search_screen.dart';
import 'package:zenify/screens/album_detail_screen.dart';
import 'package:zenify/screens/artist_detail_screen.dart';
import 'package:zenify/screens/settings_screen.dart';
import 'package:zenify/screens/server_management_screen.dart';
import 'package:zenify/views/album_view.dart';
import 'package:zenify/views/artists_view.dart';
import 'package:zenify/views/favorites_view.dart';
import 'package:zenify/screens/favorite_songs_screen.dart';
import 'package:zenify/screens/favorite_albums_screen.dart';
import 'package:zenify/views/playlists_view.dart';
import 'package:zenify/views/downloads_view.dart';

import 'package:zenify/screens/playlist_detail_screen.dart';
import 'package:zenify/components/app_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _topLevelNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'topLevel');
final _shellNavigatorAlbumKey = GlobalKey<NavigatorState>(debugLabel: 'shellAlbum');
final _shellNavigatorArtistKey = GlobalKey<NavigatorState>(debugLabel: 'shellArtist');
final _shellNavigatorFavKey = GlobalKey<NavigatorState>(debugLabel: 'shellFav');

extension BranchNavigation on BuildContext {
  void pushBranch(String subPath, {Object? extra}) {
    final location = GoRouterState.of(this).matchedLocation;
    final uri = Uri.parse(location);
    if (uri.pathSegments.isNotEmpty) {
      final branchPrefix = '/${uri.pathSegments.first}';
      push('$branchPrefix/$subPath', extra: extra);
    } else {
      push('/$subPath', extra: extra);
    }
  }
}

List<RouteBase> _buildBranchRoutes(String prefix) {
  return [
    GoRoute(
      path: '$prefix/search',
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: '$prefix/album/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return AlbumDetailScreen(albumId: id);
      },
    ),
    GoRoute(
      path: '$prefix/playlist/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final name = state.extra as String? ?? 'Playlist';
        return PlaylistDetailScreen(playlistId: id, playlistName: name);
      },
    ),
    GoRoute(
      path: '$prefix/artist/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final name = state.extra as String? ?? 'Artist';
        return ArtistDetailScreen(artistId: id, artistName: name);
      },
    ),
    GoRoute(
      path: '$prefix/songs',
      builder: (context, state) => const FavoriteSongsScreen(),
    ),
    GoRoute(
      path: '$prefix/favorite_albums',
      builder: (context, state) => const FavoriteAlbumsScreen(),
    ),
    GoRoute(
      path: '$prefix/playlists',
      builder: (context, state) => const PlaylistsView(),
    ),
    GoRoute(
      path: '$prefix/downloads',
      builder: (context, state) => const DownloadsView(),
    ),
  ];
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/albums',
    routes: [
      ShellRoute(
        navigatorKey: _topLevelNavigatorKey,
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorAlbumKey,
            routes: [
              GoRoute(
                path: '/albums',
                name: 'Albums',
                builder: (context, state) => const AlbumView(),
              ),
              ..._buildBranchRoutes('/albums'),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorArtistKey,
            routes: [
              GoRoute(
                path: '/artists',
                name: 'Artists',
                builder: (context, state) => const ArtistsView(),
              ),
              ..._buildBranchRoutes('/artists'),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorFavKey,
            routes: [
              GoRoute(
                path: '/favorites',
                name: 'Favorites',
                builder: (context, state) => const FavoritesView(),
              ),
              ..._buildBranchRoutes('/favorites'),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        name: 'Settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/servers',
        name: 'Servers',
        builder: (context, state) => const ServerManagementScreen(),
      ),
        ],
      ),
    ],
  );
});
