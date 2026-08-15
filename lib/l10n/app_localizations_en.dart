// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcomeSubtitle => 'Please select a server';

  @override
  String get settingsTitle => 'System Settings and Preferences';

  @override
  String get themeAppearance => 'Theme Appearance';

  @override
  String get themeLight => 'Light Mode';

  @override
  String get themeDark => 'Dark Mode';

  @override
  String get themeSystem => 'Auto (System)';

  @override
  String get storageAndCache => 'Storage & Cache';

  @override
  String get accountAndServer => 'Account & Server';

  @override
  String get aboutZenify => 'About ZENIFY';

  @override
  String get languageSetting => 'Language';

  @override
  String get languageSystem => 'Follow System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTraditionalChinese => '繁體中文';

  @override
  String get languageSimplifiedChinese => '简体中文';

  @override
  String get languageDescription => 'Choose your preferred interface language';

  @override
  String get navAlbums => 'Albums';

  @override
  String get navArtists => 'Artists';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get navSearch => 'Search';

  @override
  String get homeConnectionTesting => 'Testing Connection...';

  @override
  String get homeOffline => 'Offline.';

  @override
  String get homeSyncing => 'Syncing...';

  @override
  String get homeSyncNow => 'Sync Now';

  @override
  String get homeStatsTitle => 'Local Data Statistics';

  @override
  String get homeStatsAlbums => 'Album Count';

  @override
  String get homeStatsArtists => 'Artist Count';

  @override
  String get homeStatsCovers => 'Downloaded Covers';

  @override
  String get homeSortDefault => 'Default Order';

  @override
  String get homeSortNameAsc => 'Name (A-Z)';

  @override
  String get homeSortNameDesc => 'Name (Z-A)';

  @override
  String get homeSortYearDesc => 'Year (New to Old)';

  @override
  String get homeSortYearAsc => 'Year (Old to New)';

  @override
  String get homeSortRandom => 'Random';

  @override
  String get homeSortAlbumCountDesc => 'Album Count (High to Low)';

  @override
  String get homeSortRecentDownload => 'Recent Download';

  @override
  String get homeTestConnectionFailed =>
      'Connection test failed, server is still offline';

  @override
  String get homeTestConnectionSuccess =>
      'Connection successful! Restored to online mode';

  @override
  String get homeAudioPlayerDisposed =>
      'Audio player disposed, safe to Shift+R';

  @override
  String get searchPlaceholder => 'Search songs, albums, or artists...';

  @override
  String get searchHistory => 'Recent Searches';

  @override
  String get searchNoResults => 'No results found';

  @override
  String get searchHistoryClear => 'Clear All';

  @override
  String get searchSearching => 'Searching...';

  @override
  String get playerPlay => 'Play';

  @override
  String get playerPause => 'Pause';

  @override
  String get playerNext => 'Next';

  @override
  String get playerPrevious => 'Previous';

  @override
  String get playerLyrics => 'Lyrics';

  @override
  String get playerQueue => 'Queue';

  @override
  String get playerShuffle => 'Shuffle';

  @override
  String get playerRepeat => 'Repeat';

  @override
  String get playerRepeatOne => 'Repeat One';

  @override
  String get playerRepeatOff => 'Repeat Off';

  @override
  String get playerSpeed => 'Speed';

  @override
  String get playerQuality => 'Quality';

  @override
  String get playerNoLyrics => 'No Lyrics Available';

  @override
  String get playerAudioCacheError => 'Audio Cache Error';

  @override
  String get playerVolume => 'Volume';

  @override
  String get unknownSong => 'Unknown Song';

  @override
  String get unknownArtist => 'Unknown Artist';

  @override
  String get unknownAlbum => 'Unknown Album';

  @override
  String get noSongPlaying => 'No song currently playing';

  @override
  String get songInfo => 'Song Info';

  @override
  String get addToFavorites => 'Add to Favorites';

  @override
  String get removeFromFavorites => 'Remove from Favorites';

  @override
  String get playQueue => 'Play Queue';

  @override
  String get serverOffline => 'Server is Offline';

  @override
  String get exportMusicFile => 'Export Music File';

  @override
  String get downloadStarted => 'Download started...';

  @override
  String get downloadComplete => 'Download complete!';

  @override
  String get downloadFailed => 'Download failed';

  @override
  String get noCacheOrServer =>
      'Cannot connect to server and no local cache available';

  @override
  String get songDetails => 'Song Details';

  @override
  String get songTitle => 'Title';

  @override
  String get songArtist => 'Artist';

  @override
  String get songAlbum => 'Album';

  @override
  String get songYear => 'Year';

  @override
  String get songDuration => 'Duration';

  @override
  String get songFormat => 'Format';

  @override
  String get songBitrate => 'Bitrate';

  @override
  String get songFileSize => 'File Size';

  @override
  String get showHomeScreen => 'Show Home Screen';

  @override
  String get exitApp => 'Exit App';

  @override
  String get unknownYear => 'Unknown Year';

  @override
  String get unfavorited => 'Removed from favorites';

  @override
  String get favorited => 'Added to favorites';

  @override
  String favoriteFailed(String error) {
    return 'Failed to favorite: $error';
  }

  @override
  String queueSongCount(String count) {
    return '$count Songs';
  }

  @override
  String get removeFromQueue => 'Remove from Queue';

  @override
  String get albumInfoNotFound => 'Album info not found';

  @override
  String get cannotGetLocalImage => 'Cannot get local image file';

  @override
  String get imageExportedSuccessfully => 'Image exported successfully';

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String operationFailed(String error) {
    return 'Operation failed: $error';
  }

  @override
  String songCount(String count) {
    return '$count Songs';
  }

  @override
  String loadFailed(String error) {
    return 'Load failed: $error';
  }

  @override
  String get offlineOperationFailed =>
      'Offline operation failed, song could not be downloaded or server error';

  @override
  String get offlineStatus => 'Offline';

  @override
  String get offline => 'Offline';

  @override
  String get savedToOfflineMusic => 'Saved to offline music';

  @override
  String get offlineAllAlbumSongs => 'Download all album songs';

  @override
  String songCountWidget(String count) {
    return '$count songs';
  }

  @override
  String get qqMusic => 'QQ Music';

  @override
  String get neteaseMusic => 'NetEase Cloud Music';

  @override
  String get searchInOtherPlatforms => 'Search on other streaming platforms';

  @override
  String get cannotLoadArtistData => 'Cannot load artist data';

  @override
  String albumCountVar(String count) {
    return '$count Albums';
  }

  @override
  String songCountVar(String count) {
    return '$count Songs';
  }

  @override
  String get about => 'About';

  @override
  String get popularSongs => 'Popular Songs';

  @override
  String get showMore => 'Show More';

  @override
  String loadFailedErr(String error) {
    return 'Load failed: $error';
  }

  @override
  String get readMore => 'Read More';

  @override
  String get collapse => 'Collapse';

  @override
  String get serverNotConnectedHint =>
      'Server not connected, please add one from the top right first';

  @override
  String get noFavoriteAlbums => 'No favorite albums currently';

  @override
  String get favoriteAlbumsTitle => 'Favorite Albums';

  @override
  String totalAlbumsCount(String count) {
    return '$count Albums in total';
  }

  @override
  String get shufflePlayAnAlbum => 'Shuffle Play an Album';

  @override
  String loadFavoritesFailed(String error) {
    return 'Failed to load favorites: $error';
  }

  @override
  String get loadServerStatusFailed => 'Failed to load server status';

  @override
  String get noFavoriteSongs => 'No favorite songs currently';

  @override
  String get offlineSyncEnabled => 'Offline sync enabled';

  @override
  String totalSongsCountWidget(String count) {
    return '$count Songs in total';
  }

  @override
  String get offlineFavoriteSongs => 'Offline Favorite Songs';

  @override
  String songCountWidgetShort(String count) {
    return '$count songs';
  }

  @override
  String get playAll => 'Play All';

  @override
  String get startPlayingFavoriteSongs => 'Start Playing Favorite Songs';

  @override
  String get unknown => 'Unknown';

  @override
  String downloadError(String error) {
    return 'Error during download: $error';
  }

  @override
  String get songs => 'Songs';

  @override
  String get cannotLoadPlaylist => 'Cannot load playlist';

  @override
  String playlistSongCount(String count) {
    return '$count Songs';
  }

  @override
  String get playlistIsEmpty => 'Playlist is empty';

  @override
  String get savedServers => 'Saved Servers';

  @override
  String get deleteServer => 'Delete Server';

  @override
  String get confirmDeleteServer =>
      'Are you sure you want to delete this server? This action cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String get serverConnectionOrAuthFailed =>
      'Cannot connect to server or authentication failed, please check settings.';

  @override
  String get connectionError => 'Connection error.';

  @override
  String get editServer => 'Edit Server';

  @override
  String get addServer => 'Add Server';

  @override
  String get enterServerInfo =>
      'Please enter Navidrome / Subsonic server information';

  @override
  String get serverUrlExample => 'URL (e.g., http://192.168.1.100:4533)';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get delete => 'Delete';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get save => 'Save';

  @override
  String get checkServer => 'Test';

  @override
  String get cannotConnectCheckSettings =>
      'Cannot connect to server, please check network or server settings.';

  @override
  String get serverConnectionError => 'Server connection error.';

  @override
  String get addNavidromeOrSubsonic => 'Add Navidrome or Subsonic connection';

  @override
  String get noServerConfigured => 'No server configured';

  @override
  String get themeDescription =>
      'Switch between Dark Mode, Light Mode, or Follow System';

  @override
  String get selectTheme => 'Select Theme';

  @override
  String get playbackCacheManagement => 'Playback Cache Management';

  @override
  String cacheUsed(String size, String count) {
    return 'Used Cache: $size ($count songs)';
  }

  @override
  String get clearCache => 'Clear Cache';

  @override
  String get offlineMusicCacheLocation => 'Offline Music & Cache Location';

  @override
  String get loading => 'Loading...';

  @override
  String get selectThisDirectory => 'Select This Directory';

  @override
  String get preparingToMoveFiles => 'Preparing to move files...';

  @override
  String get movingFiles => 'Moving files...';

  @override
  String movedFilesProgress(String current, String total) {
    return 'Moved $current / $total files';
  }

  @override
  String get updatingDatabase => 'Updating database...';

  @override
  String errorOccurred(String error) {
    return 'Error occurred: $error';
  }

  @override
  String get changeDirectory => 'Change Directory';

  @override
  String get noLimit => 'Unlimited';

  @override
  String get cacheSizeLimit => 'Cache Size Limit';

  @override
  String get reduceCacheSize => 'Reduce Cache Size';

  @override
  String currentCacheUsedStr(String size) {
    return 'Current cache total usage: $size.\n';
  }

  @override
  String cacheLimitWarning(String limit, String excess) {
    return 'If the limit is set to $limit GB, the system will automatically remove about $excess of oldest unplayed music to free up space.';
  }

  @override
  String get confirmClear => 'Confirm Clear';

  @override
  String get serverManagement => 'Server Management';

  @override
  String connectedToServer(String url, String username) {
    return 'Connected to $url ($username)';
  }

  @override
  String get noSubsonicServerConfigured => 'No Subsonic server configured';

  @override
  String get appSlogan =>
      'Minimalist Modern Black & White Subsonic Music Player';

  @override
  String get errorCannotConnectServer => 'Error: Cannot connect to server';

  @override
  String get startSyncingArtists => 'Start syncing artists...';

  @override
  String get startSyncingAlbums => 'Start syncing albums...';

  @override
  String syncedAlbumsCount(String count) {
    return 'Synced $count albums';
  }

  @override
  String get preparingToDownloadCovers =>
      'Preparing to download cover images...';

  @override
  String downloadingCoversProgress(String downloaded, String total) {
    return 'Downloading cover images... ($downloaded/$total)';
  }

  @override
  String get syncingFavorites => 'Syncing favorites...';

  @override
  String get syncingPlaylists => 'Syncing playlists...';

  @override
  String get syncingOfflineAlbums => 'Syncing offline album data...';

  @override
  String syncingOfflineAlbumsProgress(String fetched, String total) {
    return 'Syncing offline album data... ($fetched/$total)';
  }

  @override
  String syncCompleteAlbumsLoaded(String count) {
    return 'Sync complete! Loaded $count albums.';
  }

  @override
  String syncFailed(String error) {
    return 'Sync failed: $error';
  }

  @override
  String get noAlbumsFound => 'No albums found';

  @override
  String loadAlbumsFailed(String error) {
    return 'Failed to load albums: $error';
  }

  @override
  String get noArtistsFound => 'No artists found';

  @override
  String loadArtistsFailed(String error) {
    return 'Failed to load artists: $error';
  }

  @override
  String get noOfflineAlbumsYet => 'No offline albums yet';

  @override
  String totalSortedAlbumsCount(String count) {
    return '$count Albums in total';
  }

  @override
  String get noOfflineSongsYet => 'No offline songs yet';

  @override
  String totalSortedSongsCount(String count) {
    return '$count Songs in total';
  }

  @override
  String get deletedAllOfflineMusic => 'Deleted all manually offline music';

  @override
  String get confirm => 'Confirm';

  @override
  String get finalConfirm => 'Final Confirm';

  @override
  String get deleteAll => 'Delete All';

  @override
  String get deleteAllConfirmDesc =>
      'This will delete all manually downloaded songs. This action cannot be undone.';

  @override
  String get favoriteCategories => 'Favorite Categories';

  @override
  String get favoriteSinglesAndPersonalFavorites =>
      'Favorite Singles & Personal Favorites';

  @override
  String songsCountOnly(String count) {
    return '$count songs';
  }

  @override
  String get favoritedMusicAlbums => 'Favorited Music Albums';

  @override
  String albumsCountOnly(String count) {
    return '$count albums';
  }

  @override
  String get customMusicPlaylists => 'Custom Music Playlists';

  @override
  String playlistsCountOnly(String count) {
    return '$count playlists';
  }

  @override
  String get offlineMusicAndCache => 'Offline Music & Cache';

  @override
  String validDownloadsCount(String count) {
    return '$count songs';
  }

  @override
  String get appSettings => 'App Settings';

  @override
  String get createPlaylist => 'Create Playlist';

  @override
  String get addToPlaylist => 'Add to Playlist';

  @override
  String get addedToPlaylist => 'Added to playlist';

  @override
  String get createPlaylistDesc => 'Please enter a new playlist name';

  @override
  String get playlistName => 'Playlist Name';

  @override
  String get createPlaylistSuccess => 'Playlist created successfully';

  @override
  String get createPlaylistFailed => 'Failed to create playlist';

  @override
  String get settings => 'Settings';

  @override
  String get personalMusicCollection => 'Personal Music Collection';

  @override
  String songsCountFull(String count) {
    return '$count Songs';
  }

  @override
  String albumsCountVarFull(String count) {
    return '$count Albums';
  }

  @override
  String get shuffleFavoriteSongs => 'Shuffle Favorite Songs';

  @override
  String get noPlaylistsCurrently => 'No playlists currently';

  @override
  String totalPlaylistsCount(String count) {
    return '$count Playlists in total';
  }

  @override
  String songsCountAndDuration(String songCount, String durationMinutes) {
    return '$songCount songs • $durationMinutes min';
  }

  @override
  String get songListComingSoon => 'Song list coming soon';

  @override
  String get navPlaylists => 'Playlists';

  @override
  String get playbackSettings => 'Playback';

  @override
  String get deletePlaylist => 'Delete Playlist';

  @override
  String deletePlaylistConfirm(String name) {
    return 'Are you sure you want to delete playlist \"$name\"? This action cannot be undone.';
  }

  @override
  String get playlistDeleted => 'Playlist deleted';

  @override
  String get playerPlayNext => 'Play Next';

  @override
  String get addedToQueue => 'Added to Queue';

  @override
  String get addToQueue => 'Add to Queue';

  @override
  String get goAlbum => 'Go to Album';

  @override
  String get goArtist => 'Go to Artist';

  @override
  String get download => 'Download';

  @override
  String durationMinutesOnly(String durationMinutes) {
    return '$durationMinutes min';
  }
}
