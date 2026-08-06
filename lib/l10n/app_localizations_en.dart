// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsTitle => 'Settings & Preferences';

  @override
  String get themeAppearance => 'Appearance';

  @override
  String get themeLight => 'Light Mode';

  @override
  String get themeDark => 'Dark Mode';

  @override
  String get themeSystem => 'System Auto';

  @override
  String get storageAndCache => 'Storage & Cache';

  @override
  String get accountAndServer => 'Account & Server';

  @override
  String get aboutZenify => 'About ZENIFY';

  @override
  String get languageSetting => 'Language';

  @override
  String get languageSystem => 'System Default';

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
  String get homeConnectionTesting => 'Testing connection...';

  @override
  String get homeOffline => 'Offline.';

  @override
  String get homeSyncing => 'Syncing...';

  @override
  String get homeSyncNow => 'Sync Now';

  @override
  String get homeStatsTitle => 'Local Data Stats';

  @override
  String get homeStatsAlbums => 'Albums';

  @override
  String get homeStatsArtists => 'Artists';

  @override
  String get homeStatsCovers => 'Downloaded Covers';

  @override
  String get homeSortDefault => 'Default';

  @override
  String get homeSortNameAsc => 'Name (A-Z)';

  @override
  String get homeSortNameDesc => 'Name (Z-A)';

  @override
  String get homeSortYearDesc => 'Year (Newest)';

  @override
  String get homeSortYearAsc => 'Year (Oldest)';

  @override
  String get homeSortRandom => 'Random';

  @override
  String get homeSortAlbumCountDesc => 'Album Count';

  @override
  String get homeSortRecentDownload => 'Recent Download';

  @override
  String get homeTestConnectionFailed =>
      'Connection test failed. Server is still offline.';

  @override
  String get homeTestConnectionSuccess =>
      'Connection successful! Restored to normal mode.';

  @override
  String get homeAudioPlayerDisposed =>
      'AudioPlayer disposed! Safe to Shift+R now.';

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
  String get playerNoLyrics => 'No lyrics available';

  @override
  String get playerAudioCacheError => 'Audio cache error';

  @override
  String get playerVolume => 'Volume';

  @override
  String get unknownSong => 'Unknown Song';

  @override
  String get unknownArtist => 'Unknown Artist';

  @override
  String get unknownAlbum => 'Unknown Album';

  @override
  String get noSongPlaying => 'No song playing';

  @override
  String get songInfo => 'Song Info';

  @override
  String get addToFavorites => 'Add to Favorites';

  @override
  String get removeFromFavorites => 'Remove from Favorites';

  @override
  String get playQueue => 'Play Queue';

  @override
  String get serverOffline => 'Server is offline';

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
  String get unfavorited => 'Removed from Favorites';

  @override
  String get favorited => 'Added to Favorites';

  @override
  String favoriteFailed(String error) {
    return 'Favorite failed: $error';
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
      'Offline operation failed, song might not be downloadable or server error';

  @override
  String get offlineStatus => 'Offline';

  @override
  String get offline => 'Offline';

  @override
  String get savedToOfflineMusic => 'Saved to offline music';

  @override
  String get offlineAllAlbumSongs => 'Download all songs in album';

  @override
  String songCountWidget(String count) {
    return '$count Songs';
  }

  @override
  String get qqMusic => 'QQ Music';

  @override
  String get neteaseMusic => 'NetEase Music';

  @override
  String get searchInOtherPlatforms => 'Search in other platforms';

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
      'Not connected to server, please add one in the top right';

  @override
  String get noFavoriteAlbums => 'No favorite albums';

  @override
  String get favoriteAlbumsTitle => 'Favorite Albums';

  @override
  String totalAlbumsCount(String count) {
    return '$count Albums in total';
  }

  @override
  String get shufflePlayAnAlbum => 'Shuffle play an album';

  @override
  String loadFavoritesFailed(String error) {
    return 'Load favorites failed: $error';
  }

  @override
  String get loadServerStatusFailed => 'Load server status failed';

  @override
  String get noFavoriteSongs => 'No favorite songs';

  @override
  String get offlineSyncEnabled => 'Offline sync enabled';

  @override
  String totalSongsCountWidget(String count) {
    return '$count Songs in total';
  }

  @override
  String get offlineFavoriteSongs => 'Offline favorite songs';

  @override
  String songCountWidgetShort(String count) {
    return '$count';
  }

  @override
  String get playAll => 'Play All';

  @override
  String get startPlayingFavoriteSongs => 'Start playing favorite songs';

  @override
  String get unknown => 'Unknown';

  @override
  String downloadError(String error) {
    return 'Download error: $error';
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
  String get enterServerInfo => 'Please enter Navidrome / Subsonic server info';

  @override
  String get serverUrlExample => 'URL (e.g. http://192.168.1.100:4533)';

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
  String get checkServer => 'Check';

  @override
  String get cannotConnectCheckSettings =>
      'Cannot connect to this server, please check network or server settings.';

  @override
  String get serverConnectionError => 'Server connection error.';

  @override
  String get addNavidromeOrSubsonic => 'Add Navidrome or Subsonic connection';

  @override
  String get noServerConfigured => 'No server configured';

  @override
  String get themeDescription =>
      'Toggle dark mode, light mode or follow system setting';

  @override
  String get selectTheme => 'Select Theme';

  @override
  String get playbackCacheManagement => 'Playback Cache Management';

  @override
  String cacheUsed(String size, String count) {
    return 'Cache used: $size ($count songs)';
  }

  @override
  String get clearCache => 'Clear Cache';

  @override
  String get offlineMusicCacheLocation =>
      'Offline music and cache storage location';

  @override
  String get loading => 'Loading...';

  @override
  String get selectThisDirectory => 'Select this directory';

  @override
  String get preparingToMoveFiles => 'Preparing to move files...';

  @override
  String get movingFiles => 'Moving files';

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
  String get noLimit => 'No Limit';

  @override
  String get cacheSizeLimit => 'Cache Size Limit';

  @override
  String get reduceCacheSize => 'Reduce Cache Size';

  @override
  String currentCacheUsedStr(String size) {
    return 'Current cache total used: $size.\\n';
  }

  @override
  String cacheLimitWarning(String limit, String excess) {
    return 'If limit is set to $limit GB, system will automatically clear about $excess of oldest unplayed music to free up space.';
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
  String get noSubsonicServerConfigured => 'Subsonic server not configured yet';

  @override
  String get appSlogan => 'Minimalist modern B&W Subsonic music player';

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
  String get preparingToDownloadCovers => 'Preparing to download covers...';

  @override
  String downloadingCoversProgress(String downloaded, String total) {
    return 'Downloading covers... ($downloaded/$total)';
  }

  @override
  String get syncingFavorites => 'Syncing favorites...';

  @override
  String get syncingPlaylists => 'Syncing playlists...';

  @override
  String get syncingOfflineAlbums => 'Syncing offline albums data...';

  @override
  String syncingOfflineAlbumsProgress(String fetched, String total) {
    return 'Syncing offline albums data... ($fetched/$total)';
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
    return 'Load albums failed: $error';
  }

  @override
  String get noArtistsFound => 'No artists found';

  @override
  String loadArtistsFailed(String error) {
    return 'Load artists failed: $error';
  }

  @override
  String get noOfflineAlbumsYet => 'No offline albums yet';

  @override
  String totalSortedAlbumsCount(String count) {
    return 'Total $count albums';
  }

  @override
  String get noOfflineSongsYet => 'No offline songs yet';

  @override
  String totalSortedSongsCount(String count) {
    return 'Total $count songs';
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
  String get favoriteCategories => 'Favorite Categories';

  @override
  String get favoriteSinglesAndPersonalFavorites =>
      'Favorite singles and personal favorites';

  @override
  String songsCountOnly(String count) {
    return '$count Songs';
  }

  @override
  String get favoritedMusicAlbums => 'Favorited music albums';

  @override
  String albumsCountOnly(String count) {
    return '$count Albums';
  }

  @override
  String get customMusicPlaylists => 'Custom music playlists';

  @override
  String playlistsCountOnly(String count) {
    return '$count Playlists';
  }

  @override
  String get offlineMusicAndCache => 'Offline music and cache';

  @override
  String validDownloadsCount(String count) {
    return '$count Songs';
  }

  @override
  String get appSettings => 'App Settings';

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
  String get replayGainTitle => 'ReplayGain (Volume Normalization)';

  @override
  String get replayGainSubtitle =>
      'Automatically normalize volume levels across different tracks.';
}
