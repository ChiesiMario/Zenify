import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

import 'package:zenify/screens/playlist_detail_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorAlbumKey = GlobalKey<NavigatorState>(debugLabel: 'shellAlbum');
final _shellNavigatorArtistKey = GlobalKey<NavigatorState>(debugLabel: 'shellArtist');
final _shellNavigatorFavKey = GlobalKey<NavigatorState>(debugLabel: 'shellFav');

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/albums',
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
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/search',
        name: 'Search',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/album/:id',
        name: 'AlbumDetail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AlbumDetailScreen(albumId: id);
        },
      ),
      GoRoute(
        path: '/playlist/:id',
        name: 'PlaylistDetail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final name = state.extra as String? ?? 'Playlist';
          return PlaylistDetailScreen(playlistId: id, playlistName: name);
        },
      ),
      GoRoute(
        path: '/artist/:id',
        name: 'ArtistDetail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final name = state.extra as String? ?? 'Artist';
          return ArtistDetailScreen(artistId: id, artistName: name);
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'Settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/servers',
        name: 'Servers',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ServerManagementScreen(),
      ),
    ],
  );
});
