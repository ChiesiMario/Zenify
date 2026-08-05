// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get settingsTitle => '系統設定與偏好';

  @override
  String get themeAppearance => '主題外觀';

  @override
  String get themeLight => '淺色模式';

  @override
  String get themeDark => '深色模式';

  @override
  String get themeSystem => '自動 (系統)';

  @override
  String get storageAndCache => '儲存與快取';

  @override
  String get accountAndServer => '帳號與伺服器';

  @override
  String get aboutZenify => '關於 ZENIFY';

  @override
  String get languageSetting => '語言';

  @override
  String get languageSystem => '跟隨系統';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTraditionalChinese => '繁體中文';

  @override
  String get languageSimplifiedChinese => '简体中文';

  @override
  String get languageDescription => '選擇您偏好的介面語言';

  @override
  String get navAlbums => '專輯';

  @override
  String get navArtists => '藝術家';

  @override
  String get navFavorites => '最愛';

  @override
  String get navSearch => '搜尋';

  @override
  String get homeConnectionTesting => '連線測試中...';

  @override
  String get homeOffline => 'Offline.';

  @override
  String get homeSyncing => '同步中...';

  @override
  String get homeSyncNow => '立即同步';

  @override
  String get homeStatsTitle => '本地資料統計';

  @override
  String get homeStatsAlbums => '專輯數量';

  @override
  String get homeStatsArtists => '藝術家數量';

  @override
  String get homeStatsCovers => '已下載封面';

  @override
  String get homeSortDefault => '預設排序';

  @override
  String get homeSortNameAsc => '名稱 (A-Z)';

  @override
  String get homeSortNameDesc => '名稱 (Z-A)';

  @override
  String get homeSortYearDesc => '年份 (新到舊)';

  @override
  String get homeSortYearAsc => '年份 (舊到新)';

  @override
  String get homeSortRandom => '隨機排列';

  @override
  String get homeSortAlbumCountDesc => '專輯數量 (多到少)';

  @override
  String get homeSortRecentDownload => '最近下載';

  @override
  String get homeTestConnectionFailed => '連線測試失敗，伺服器仍處於離線狀態';

  @override
  String get homeTestConnectionSuccess => '連線成功！已恢復為正常模式';

  @override
  String get homeAudioPlayerDisposed => '音訊播放器已釋放，可以安全 Shift+R';

  @override
  String get searchPlaceholder => '搜尋歌曲、專輯或藝術家...';

  @override
  String get searchHistory => '近期搜尋';

  @override
  String get searchNoResults => '找不到相關結果';

  @override
  String get searchHistoryClear => '清除所有';

  @override
  String get searchSearching => '搜尋中...';

  @override
  String get playerPlay => '播放';

  @override
  String get playerPause => '暫停';

  @override
  String get playerNext => '下一首';

  @override
  String get playerPrevious => '上一首';

  @override
  String get playerLyrics => '歌詞';

  @override
  String get playerQueue => '播放清單';

  @override
  String get playerShuffle => '隨機播放';

  @override
  String get playerRepeat => '循環播放';

  @override
  String get playerRepeatOne => '單曲循環';

  @override
  String get playerRepeatOff => '關閉循環';

  @override
  String get playerSpeed => '速度';

  @override
  String get playerQuality => '音質';

  @override
  String get playerNoLyrics => '暫無歌詞';

  @override
  String get playerAudioCacheError => '音訊快取錯誤';

  @override
  String get playerVolume => '音量';

  @override
  String get unknownSong => '未知歌曲';

  @override
  String get unknownArtist => '未知藝術家';

  @override
  String get unknownAlbum => '未知專輯';

  @override
  String get noSongPlaying => '無播放中的歌曲';

  @override
  String get songInfo => '歌曲資訊';

  @override
  String get addToFavorites => '加入最愛';

  @override
  String get removeFromFavorites => '取消最愛';

  @override
  String get playQueue => '播放隊列';

  @override
  String get serverOffline => '服務器已離線';

  @override
  String get exportMusicFile => '匯出音樂檔案';

  @override
  String get downloadStarted => '開始下載...';

  @override
  String get downloadComplete => '下載完成！';

  @override
  String get downloadFailed => '下載失敗';

  @override
  String get noCacheOrServer => '無法連接伺服器，且無本機快取';

  @override
  String get songDetails => '歌曲詳細資訊';

  @override
  String get songTitle => '標題';

  @override
  String get songArtist => '藝術家';

  @override
  String get songAlbum => '專輯';

  @override
  String get songYear => '年份';

  @override
  String get songDuration => '時長';

  @override
  String get songFormat => '格式';

  @override
  String get songBitrate => '位元率';

  @override
  String get songFileSize => '檔案大小';

  @override
  String get showHomeScreen => '顯示主畫面';

  @override
  String get exitApp => '退出程式';

  @override
  String get unknownYear => '未知年份';

  @override
  String get unfavorited => '已取消收藏';

  @override
  String get favorited => '已加入收藏';

  @override
  String favoriteFailed(String error) {
    return '收藏失敗：$error';
  }

  @override
  String queueSongCount(String count) {
    return '$count 首歌曲';
  }

  @override
  String get removeFromQueue => '從隊列移除';

  @override
  String get albumInfoNotFound => '找不到專輯資訊';

  @override
  String get cannotGetLocalImage => '無法取得本地圖片檔案';

  @override
  String get imageExportedSuccessfully => '圖片已成功匯出';

  @override
  String exportFailed(String error) {
    return '匯出失敗：$error';
  }

  @override
  String operationFailed(String error) {
    return '操作失敗：$error';
  }

  @override
  String songCount(String count) {
    return '$count 首歌';
  }

  @override
  String loadFailed(String error) {
    return '加載失敗: $error';
  }

  @override
  String get offlineOperationFailed => '離線操作失敗，可能歌曲無法下載或伺服器錯誤';

  @override
  String get offlineStatus => '已離線';

  @override
  String get offline => '離線';

  @override
  String get savedToOfflineMusic => '已儲存至離線音樂';

  @override
  String get offlineAllAlbumSongs => '離線本專輯所有歌曲';

  @override
  String songCountWidget(String count) {
    return '$count 首';
  }

  @override
  String get qqMusic => 'QQ 音樂';

  @override
  String get neteaseMusic => '網易雲音樂';

  @override
  String get searchInOtherPlatforms => '在其他串流平台搜尋';

  @override
  String get cannotLoadArtistData => '無法載入藝術家資料';

  @override
  String albumCountVar(String count) {
    return '$count 張專輯';
  }

  @override
  String songCountVar(String count) {
    return '$count 首歌';
  }

  @override
  String get about => '關於';

  @override
  String get popularSongs => '熱門歌曲';

  @override
  String get showMore => '顯示更多';

  @override
  String loadFailedErr(String error) {
    return '載入失敗: $error';
  }

  @override
  String get readMore => '閱讀更多';

  @override
  String get collapse => '收起';

  @override
  String get serverNotConnectedHint => '未連接伺服器，請先在右上角新增';

  @override
  String get noFavoriteAlbums => '目前沒有任何喜愛的專輯';

  @override
  String get favoriteAlbumsTitle => '收藏的專輯';

  @override
  String totalAlbumsCount(String count) {
    return '共 $count 張專輯';
  }

  @override
  String get shufflePlayAnAlbum => '隨機播放一張專輯';

  @override
  String loadFavoritesFailed(String error) {
    return '加載喜愛項目失敗: $error';
  }

  @override
  String get loadServerStatusFailed => '加載伺服器狀態失敗';

  @override
  String get noFavoriteSongs => '目前沒有任何喜愛的歌曲';

  @override
  String get offlineSyncEnabled => '已開啟離線同步';

  @override
  String totalSongsCountWidget(String count) {
    return '共 $count 首歌曲';
  }

  @override
  String get offlineFavoriteSongs => '離線最愛歌曲';

  @override
  String songCountWidgetShort(String count) {
    return '$count 首';
  }

  @override
  String get playAll => '播放全部';

  @override
  String get startPlayingFavoriteSongs => '開始播放最愛歌曲';

  @override
  String get unknown => '未知';

  @override
  String downloadError(String error) {
    return '下載時發生錯誤：$error';
  }

  @override
  String get songs => '歌曲';

  @override
  String get cannotLoadPlaylist => '無法載入播放清單';

  @override
  String playlistSongCount(String count) {
    return '$count 首歌曲';
  }

  @override
  String get playlistIsEmpty => '播放清單是空的';

  @override
  String get savedServers => '已儲存的伺服器';

  @override
  String get deleteServer => '刪除伺服器';

  @override
  String get confirmDeleteServer => '確定要刪除這個伺服器嗎？此操作無法還原。';

  @override
  String get cancel => '取消';

  @override
  String get confirmDelete => '確認刪除';

  @override
  String get serverConnectionOrAuthFailed => '無法連線至伺服器或驗證失敗，請檢查設定。';

  @override
  String get connectionError => '連線發生錯誤。';

  @override
  String get editServer => '編輯伺服器';

  @override
  String get addServer => '新增伺服器';

  @override
  String get enterServerInfo => '請輸入 Navidrome / Subsonic 伺服器資訊';

  @override
  String get serverUrlExample => 'URL (例如: http://192.168.1.100:4533)';

  @override
  String get username => '帳號';

  @override
  String get password => '密碼';

  @override
  String get delete => '刪除';

  @override
  String get saveChanges => '儲存變更';

  @override
  String get save => '儲存';

  @override
  String get checkServer => '檢查伺服器';

  @override
  String get cannotConnectCheckSettings => '無法連線至該伺服器，請檢查網路或伺服器設定。';

  @override
  String get serverConnectionError => '伺服器連線發生錯誤。';

  @override
  String get addNavidromeOrSubsonic => '新增 Navidrome 或 Subsonic 連線';

  @override
  String get noServerConfigured => '未設定伺服器';

  @override
  String get themeDescription => '切換深色模式、淺色模式或跟隨系統設定';

  @override
  String get selectTheme => '選擇主題';

  @override
  String get playbackCacheManagement => '播放快取管理';

  @override
  String cacheUsed(String size, String count) {
    return '已使用快取: $size ($count 首歌曲)';
  }

  @override
  String get clearCache => '清除快取';

  @override
  String get offlineMusicCacheLocation => '離線音樂與快取儲存位置';

  @override
  String get loading => '載入中...';

  @override
  String get selectThisDirectory => '選擇此目錄';

  @override
  String get preparingToMoveFiles => '準備搬移檔案...';

  @override
  String get movingFiles => '搬移檔案中';

  @override
  String movedFilesProgress(String current, String total) {
    return '已搬移 $current / $total 個檔案';
  }

  @override
  String get updatingDatabase => '更新資料庫中...';

  @override
  String errorOccurred(String error) {
    return '發生錯誤: $error';
  }

  @override
  String get changeDirectory => '變更目錄';

  @override
  String get noLimit => '無上限';

  @override
  String get cacheSizeLimit => '快取容量上限';

  @override
  String get reduceCacheSize => '縮減快取容量';

  @override
  String currentCacheUsedStr(String size) {
    return '目前的快取總共使用了 $size。\\n';
  }

  @override
  String cacheLimitWarning(String limit, String excess) {
    return '如果將上限設定為 $limit GB，系統將會自動清除約 $excess 最久未聽過的音樂來釋放空間。';
  }

  @override
  String get confirmClear => '確定清除';

  @override
  String get serverManagement => '伺服器管理';

  @override
  String connectedToServer(String url, String username) {
    return '已連線至 $url ($username)';
  }

  @override
  String get noSubsonicServerConfigured => '尚未設定 Subsonic 伺服器';

  @override
  String get appSlogan => '極簡現代黑白風 Subsonic 音樂播放器';

  @override
  String get errorCannotConnectServer => '錯誤：無法連線伺服器';

  @override
  String get startSyncingArtists => '開始同步藝術家...';

  @override
  String get startSyncingAlbums => '開始同步專輯...';

  @override
  String syncedAlbumsCount(String count) {
    return '已同步 $count 張專輯';
  }

  @override
  String get preparingToDownloadCovers => '準備下載封面圖片...';

  @override
  String downloadingCoversProgress(String downloaded, String total) {
    return '下載封面圖片中... ($downloaded/$total)';
  }

  @override
  String get syncingFavorites => '同步最愛項目...';

  @override
  String get syncingPlaylists => '同步播放清單...';

  @override
  String get syncingOfflineAlbums => '同步離線專輯資料中...';

  @override
  String syncingOfflineAlbumsProgress(String fetched, String total) {
    return '同步離線專輯資料中... ($fetched/$total)';
  }

  @override
  String syncCompleteAlbumsLoaded(String count) {
    return '同步完成！共載入 $count 張專輯。';
  }

  @override
  String syncFailed(String error) {
    return '同步失敗：$error';
  }

  @override
  String get noAlbumsFound => '沒有找到任何專輯';

  @override
  String loadAlbumsFailed(String error) {
    return '加載專輯失敗: $error';
  }

  @override
  String get noArtistsFound => '沒有找到藝術家';

  @override
  String loadArtistsFailed(String error) {
    return '加載藝術家失敗: $error';
  }

  @override
  String get noOfflineAlbumsYet => '尚無已離線的專輯';

  @override
  String totalSortedAlbumsCount(String count) {
    return '共 $count 張專輯';
  }

  @override
  String get noOfflineSongsYet => '尚無已離線的歌曲';

  @override
  String totalSortedSongsCount(String count) {
    return '共 $count 首歌曲';
  }

  @override
  String get deletedAllOfflineMusic => '已刪除所有手動離線的音樂';

  @override
  String get confirm => '確認';

  @override
  String get finalConfirm => '最終確認';

  @override
  String get deleteAll => '刪除全部';

  @override
  String get favoriteCategories => '珍藏分類';

  @override
  String get favoriteSinglesAndPersonalFavorites => '喜愛單曲與個人最愛';

  @override
  String songsCountOnly(String count) {
    return '$count 首';
  }

  @override
  String get favoritedMusicAlbums => '已收藏的音樂專輯';

  @override
  String albumsCountOnly(String count) {
    return '$count 張';
  }

  @override
  String get customMusicPlaylists => '自訂音樂歌單';

  @override
  String playlistsCountOnly(String count) {
    return '$count 個';
  }

  @override
  String get offlineMusicAndCache => '離線音樂與快取';

  @override
  String validDownloadsCount(String count) {
    return '$count 首';
  }

  @override
  String get appSettings => '應用程式設定';

  @override
  String get settings => '設定';

  @override
  String get personalMusicCollection => '個人音樂珍藏';

  @override
  String songsCountFull(String count) {
    return '$count 首歌曲';
  }

  @override
  String albumsCountVarFull(String count) {
    return '$count 張專輯';
  }

  @override
  String get shuffleFavoriteSongs => '隨機播放最愛歌曲';

  @override
  String get noPlaylistsCurrently => '目前沒有播放清單';

  @override
  String totalPlaylistsCount(String count) {
    return '共 $count 個歌單';
  }

  @override
  String songsCountAndDuration(String songCount, String durationMinutes) {
    return '$songCount 首歌曲 • $durationMinutes 分鐘';
  }

  @override
  String get songListComingSoon => '歌曲清單即將推出';

  @override
  String get navPlaylists => '播放清單';
}

/// The translations for Chinese, as used in China (`zh_CN`).
class AppLocalizationsZhCn extends AppLocalizationsZh {
  AppLocalizationsZhCn() : super('zh_CN');

  @override
  String get settingsTitle => '系统设置与偏好';

  @override
  String get themeAppearance => '主题外观';

  @override
  String get themeLight => '浅色模式';

  @override
  String get themeDark => '深色模式';

  @override
  String get themeSystem => '自动 (系统)';

  @override
  String get storageAndCache => '存储与缓存';

  @override
  String get accountAndServer => '账号与服务器';

  @override
  String get aboutZenify => '关于 ZENIFY';

  @override
  String get languageSetting => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTraditionalChinese => '繁体中文';

  @override
  String get languageSimplifiedChinese => '简体中文';

  @override
  String get languageDescription => '选择您偏好的界面语言';

  @override
  String get navAlbums => '专辑';

  @override
  String get navArtists => '艺术家';

  @override
  String get navFavorites => '最爱';

  @override
  String get navSearch => '搜索';

  @override
  String get homeConnectionTesting => '连接测试中...';

  @override
  String get homeOffline => 'Offline.';

  @override
  String get homeSyncing => '同步中...';

  @override
  String get homeSyncNow => '立即同步';

  @override
  String get homeStatsTitle => '本地数据统计';

  @override
  String get homeStatsAlbums => '专辑数量';

  @override
  String get homeStatsArtists => '艺术家数量';

  @override
  String get homeStatsCovers => '已下载封面';

  @override
  String get homeSortDefault => '默认排序';

  @override
  String get homeSortNameAsc => '名称 (A-Z)';

  @override
  String get homeSortNameDesc => '名称 (Z-A)';

  @override
  String get homeSortYearDesc => '年份 (新到旧)';

  @override
  String get homeSortYearAsc => '年份 (旧到新)';

  @override
  String get homeSortRandom => '随机排列';

  @override
  String get homeSortAlbumCountDesc => '专辑数量 (多到少)';

  @override
  String get homeSortRecentDownload => '最近下载';

  @override
  String get homeTestConnectionFailed => '连接测试失败，服务器仍处于离线状态';

  @override
  String get homeTestConnectionSuccess => '连接成功！已恢复为正常模式';

  @override
  String get homeAudioPlayerDisposed => '音频播放器已释放，可以安全 Shift+R';

  @override
  String get searchPlaceholder => '搜索歌曲、专辑或艺术家...';

  @override
  String get searchHistory => '近期搜索';

  @override
  String get searchNoResults => '找不到相关结果';

  @override
  String get searchHistoryClear => '清除所有';

  @override
  String get searchSearching => '搜索中...';

  @override
  String get playerPlay => '播放';

  @override
  String get playerPause => '暂停';

  @override
  String get playerNext => '下一首';

  @override
  String get playerPrevious => '上一首';

  @override
  String get playerLyrics => '歌词';

  @override
  String get playerQueue => '播放列表';

  @override
  String get playerShuffle => '随机播放';

  @override
  String get playerRepeat => '循环播放';

  @override
  String get playerRepeatOne => '单曲循环';

  @override
  String get playerRepeatOff => '关闭循环';

  @override
  String get playerSpeed => '速度';

  @override
  String get playerQuality => '音质';

  @override
  String get playerNoLyrics => '暂无歌词';

  @override
  String get playerAudioCacheError => '音频缓存错误';

  @override
  String get playerVolume => '音量';

  @override
  String get unknownSong => '未知歌曲';

  @override
  String get unknownArtist => '未知艺术家';

  @override
  String get unknownAlbum => '未知专辑';

  @override
  String get noSongPlaying => '无播放中的歌曲';

  @override
  String get songInfo => '歌曲信息';

  @override
  String get addToFavorites => '加入最爱';

  @override
  String get removeFromFavorites => '取消最爱';

  @override
  String get playQueue => '播放队列';

  @override
  String get serverOffline => '服务器已离线';

  @override
  String get exportMusicFile => '导出音乐文件';

  @override
  String get downloadStarted => '开始下载...';

  @override
  String get downloadComplete => '下载完成！';

  @override
  String get downloadFailed => '下载失败';

  @override
  String get noCacheOrServer => '无法连接服务器，且无本地缓存';

  @override
  String get songDetails => '歌曲详细信息';

  @override
  String get songTitle => '标题';

  @override
  String get songArtist => '艺术家';

  @override
  String get songAlbum => '专辑';

  @override
  String get songYear => '年份';

  @override
  String get songDuration => '时长';

  @override
  String get songFormat => '格式';

  @override
  String get songBitrate => '比特率';

  @override
  String get songFileSize => '文件大小';

  @override
  String get showHomeScreen => '显示主屏幕';

  @override
  String get exitApp => '退出程序';

  @override
  String get unknownYear => '未知年份';

  @override
  String get unfavorited => '已取消收藏';

  @override
  String get favorited => '已加入收藏';

  @override
  String favoriteFailed(String error) {
    return '收藏失败：$error';
  }

  @override
  String queueSongCount(String count) {
    return '$count 首歌曲';
  }

  @override
  String get removeFromQueue => '从队列移除';

  @override
  String get albumInfoNotFound => '找不到专辑信息';

  @override
  String get cannotGetLocalImage => '无法获取本地图片文件';

  @override
  String get imageExportedSuccessfully => '图片已成功导出';

  @override
  String exportFailed(String error) {
    return '导出失败：$error';
  }

  @override
  String operationFailed(String error) {
    return '操作失败：$error';
  }

  @override
  String songCount(String count) {
    return '$count 首歌';
  }

  @override
  String loadFailed(String error) {
    return '加载失败: $error';
  }

  @override
  String get offlineOperationFailed => '离线操作失败，可能歌曲无法下载或服务器错误';

  @override
  String get offlineStatus => '已离线';

  @override
  String get offline => '离线';

  @override
  String get savedToOfflineMusic => '已保存至离线音乐';

  @override
  String get offlineAllAlbumSongs => '离线本专辑所有歌曲';

  @override
  String songCountWidget(String count) {
    return '$count 首';
  }

  @override
  String get qqMusic => 'QQ 音乐';

  @override
  String get neteaseMusic => '网易云音乐';

  @override
  String get searchInOtherPlatforms => '在其他流媒体平台搜索';

  @override
  String get cannotLoadArtistData => '无法加载艺术家数据';

  @override
  String albumCountVar(String count) {
    return '$count 张专辑';
  }

  @override
  String songCountVar(String count) {
    return '$count 首歌';
  }

  @override
  String get about => '关于';

  @override
  String get popularSongs => '热门歌曲';

  @override
  String get showMore => '显示更多';

  @override
  String loadFailedErr(String error) {
    return '加载失败: $error';
  }

  @override
  String get readMore => '阅读更多';

  @override
  String get collapse => '收起';

  @override
  String get serverNotConnectedHint => '未连接服务器，请先在右上角新增';

  @override
  String get noFavoriteAlbums => '目前没有任何喜爱的专辑';

  @override
  String get favoriteAlbumsTitle => '收藏的专辑';

  @override
  String totalAlbumsCount(String count) {
    return '共 $count 张专辑';
  }

  @override
  String get shufflePlayAnAlbum => '随机播放一张专辑';

  @override
  String loadFavoritesFailed(String error) {
    return '加载喜爱项目失败: $error';
  }

  @override
  String get loadServerStatusFailed => '加载服务器状态失败';

  @override
  String get noFavoriteSongs => '目前没有任何喜爱的歌曲';

  @override
  String get offlineSyncEnabled => '已开启离线同步';

  @override
  String totalSongsCountWidget(String count) {
    return '共 $count 首歌曲';
  }

  @override
  String get offlineFavoriteSongs => '离线最爱歌曲';

  @override
  String songCountWidgetShort(String count) {
    return '$count 首';
  }

  @override
  String get playAll => '播放全部';

  @override
  String get startPlayingFavoriteSongs => '开始播放最爱歌曲';

  @override
  String get unknown => '未知';

  @override
  String downloadError(String error) {
    return '下载时发生错误：$error';
  }

  @override
  String get songs => '歌曲';

  @override
  String get cannotLoadPlaylist => '无法加载播放列表';

  @override
  String playlistSongCount(String count) {
    return '$count 首歌曲';
  }

  @override
  String get playlistIsEmpty => '播放列表是空的';

  @override
  String get savedServers => '已保存的服务器';

  @override
  String get deleteServer => '删除服务器';

  @override
  String get confirmDeleteServer => '确定要删除这个服务器吗？此操作无法还原。';

  @override
  String get cancel => '取消';

  @override
  String get confirmDelete => '确认删除';

  @override
  String get serverConnectionOrAuthFailed => '无法连接至服务器或验证失败，请检查设置。';

  @override
  String get connectionError => '连接发生错误。';

  @override
  String get editServer => '编辑服务器';

  @override
  String get addServer => '新增服务器';

  @override
  String get enterServerInfo => '请输入 Navidrome / Subsonic 服务器信息';

  @override
  String get serverUrlExample => 'URL (例如: http://192.168.1.100:4533)';

  @override
  String get username => '账号';

  @override
  String get password => '密码';

  @override
  String get delete => '删除';

  @override
  String get saveChanges => '保存更改';

  @override
  String get save => '保存';

  @override
  String get checkServer => '检查服务器';

  @override
  String get cannotConnectCheckSettings => '无法连接至该服务器，请检查网络或服务器设置。';

  @override
  String get serverConnectionError => '服务器连接发生错误。';

  @override
  String get addNavidromeOrSubsonic => '新增 Navidrome 或 Subsonic 连接';

  @override
  String get noServerConfigured => '未设置服务器';

  @override
  String get themeDescription => '切换深色模式、浅色模式或跟随系统设置';

  @override
  String get selectTheme => '选择主题';

  @override
  String get playbackCacheManagement => '播放缓存管理';

  @override
  String cacheUsed(String size, String count) {
    return '已使用缓存: $size ($count 首歌曲)';
  }

  @override
  String get clearCache => '清除缓存';

  @override
  String get offlineMusicCacheLocation => '离线音乐与缓存存储位置';

  @override
  String get loading => '加载中...';

  @override
  String get selectThisDirectory => '选择此目录';

  @override
  String get preparingToMoveFiles => '准备搬移文件...';

  @override
  String get movingFiles => '搬移文件中';

  @override
  String movedFilesProgress(String current, String total) {
    return '已搬移 $current / $total 个文件';
  }

  @override
  String get updatingDatabase => '更新数据库中...';

  @override
  String errorOccurred(String error) {
    return '发生错误: $error';
  }

  @override
  String get changeDirectory => '更改目录';

  @override
  String get noLimit => '无上限';

  @override
  String get cacheSizeLimit => '缓存容量上限';

  @override
  String get reduceCacheSize => '缩减缓存容量';

  @override
  String currentCacheUsedStr(String size) {
    return '目前的缓存总共使用了 $size。\\n';
  }

  @override
  String cacheLimitWarning(String limit, String excess) {
    return '如果将上限设置为 $limit GB，系统将会自动清除约 $excess 最久未听过的音乐来释放空间。';
  }

  @override
  String get confirmClear => '确定清除';

  @override
  String get serverManagement => '服务器管理';

  @override
  String connectedToServer(String url, String username) {
    return '已连接至 $url ($username)';
  }

  @override
  String get noSubsonicServerConfigured => '尚未设置 Subsonic 服务器';

  @override
  String get appSlogan => '极简现代黑白风 Subsonic 音乐播放器';

  @override
  String get errorCannotConnectServer => '错误：无法连接服务器';

  @override
  String get startSyncingArtists => '开始同步艺术家...';

  @override
  String get startSyncingAlbums => '开始同步专辑...';

  @override
  String syncedAlbumsCount(String count) {
    return '已同步 $count 张专辑';
  }

  @override
  String get preparingToDownloadCovers => '准备下载封面图片...';

  @override
  String downloadingCoversProgress(String downloaded, String total) {
    return '下载封面图片中... ($downloaded/$total)';
  }

  @override
  String get syncingFavorites => '同步最爱项目...';

  @override
  String get syncingPlaylists => '同步播放列表...';

  @override
  String get syncingOfflineAlbums => '同步离线专辑数据中...';

  @override
  String syncingOfflineAlbumsProgress(String fetched, String total) {
    return '同步离线专辑数据中... ($fetched/$total)';
  }

  @override
  String syncCompleteAlbumsLoaded(String count) {
    return '同步完成！共载入 $count 张专辑。';
  }

  @override
  String syncFailed(String error) {
    return '同步失败：$error';
  }

  @override
  String get noAlbumsFound => '没有找到任何专辑';

  @override
  String loadAlbumsFailed(String error) {
    return '加载专辑失败: $error';
  }

  @override
  String get noArtistsFound => '没有找到艺术家';

  @override
  String loadArtistsFailed(String error) {
    return '加载艺术家失败: $error';
  }

  @override
  String get noOfflineAlbumsYet => '尚无已离线的专辑';

  @override
  String totalSortedAlbumsCount(String count) {
    return '共 $count 张专辑';
  }

  @override
  String get noOfflineSongsYet => '尚无已离线的歌曲';

  @override
  String totalSortedSongsCount(String count) {
    return '共 $count 首歌曲';
  }

  @override
  String get deletedAllOfflineMusic => '已删除所有手动离线的音乐';

  @override
  String get confirm => '确认';

  @override
  String get finalConfirm => '最终确认';

  @override
  String get deleteAll => '删除全部';

  @override
  String get favoriteCategories => '收藏分类';

  @override
  String get favoriteSinglesAndPersonalFavorites => '喜爱单曲与个人最爱';

  @override
  String songsCountOnly(String count) {
    return '$count 首';
  }

  @override
  String get favoritedMusicAlbums => '已收藏的音乐专辑';

  @override
  String albumsCountOnly(String count) {
    return '$count 张';
  }

  @override
  String get customMusicPlaylists => '自定音乐歌单';

  @override
  String playlistsCountOnly(String count) {
    return '$count 个';
  }

  @override
  String get offlineMusicAndCache => '离线音乐与缓存';

  @override
  String validDownloadsCount(String count) {
    return '$count 首';
  }

  @override
  String get appSettings => '应用程序设置';

  @override
  String get settings => '设置';

  @override
  String get personalMusicCollection => '个人音乐收藏';

  @override
  String songsCountFull(String count) {
    return '$count 首歌曲';
  }

  @override
  String albumsCountVarFull(String count) {
    return '$count 张专辑';
  }

  @override
  String get shuffleFavoriteSongs => '随机播放最爱歌曲';

  @override
  String get noPlaylistsCurrently => '目前没有播放列表';

  @override
  String totalPlaylistsCount(String count) {
    return '共 $count 个歌单';
  }

  @override
  String songsCountAndDuration(String songCount, String durationMinutes) {
    return '$songCount 首歌曲 • $durationMinutes 分钟';
  }

  @override
  String get songListComingSoon => '歌曲清单即将推出';

  @override
  String get navPlaylists => '播放列表';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get settingsTitle => '系統設定與偏好';

  @override
  String get themeAppearance => '主題外觀';

  @override
  String get themeLight => '淺色模式';

  @override
  String get themeDark => '深色模式';

  @override
  String get themeSystem => '自動 (系統)';

  @override
  String get storageAndCache => '儲存與快取';

  @override
  String get accountAndServer => '帳號與伺服器';

  @override
  String get aboutZenify => '關於 ZENIFY';

  @override
  String get languageSetting => '語言';

  @override
  String get languageSystem => '跟隨系統';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTraditionalChinese => '繁體中文';

  @override
  String get languageSimplifiedChinese => '简体中文';

  @override
  String get languageDescription => '選擇您偏好的介面語言';

  @override
  String get navAlbums => '專輯';

  @override
  String get navArtists => '藝術家';

  @override
  String get navFavorites => '最愛';

  @override
  String get navSearch => '搜尋';

  @override
  String get homeConnectionTesting => '連線測試中...';

  @override
  String get homeOffline => 'Offline.';

  @override
  String get homeSyncing => '同步中...';

  @override
  String get homeSyncNow => '立即同步';

  @override
  String get homeStatsTitle => '本地資料統計';

  @override
  String get homeStatsAlbums => '專輯數量';

  @override
  String get homeStatsArtists => '藝術家數量';

  @override
  String get homeStatsCovers => '已下載封面';

  @override
  String get homeSortDefault => '預設排序';

  @override
  String get homeSortNameAsc => '名稱 (A-Z)';

  @override
  String get homeSortNameDesc => '名稱 (Z-A)';

  @override
  String get homeSortYearDesc => '年份 (新到舊)';

  @override
  String get homeSortYearAsc => '年份 (舊到新)';

  @override
  String get homeSortRandom => '隨機排列';

  @override
  String get homeSortAlbumCountDesc => '專輯數量 (多到少)';

  @override
  String get homeSortRecentDownload => '最近下載';

  @override
  String get homeTestConnectionFailed => '連線測試失敗，伺服器仍處於離線狀態';

  @override
  String get homeTestConnectionSuccess => '連線成功！已恢復為正常模式';

  @override
  String get homeAudioPlayerDisposed => '音訊播放器已釋放，可以安全 Shift+R';

  @override
  String get searchPlaceholder => '搜尋歌曲、專輯或藝術家...';

  @override
  String get searchHistory => '近期搜尋';

  @override
  String get searchNoResults => '找不到相關結果';

  @override
  String get searchHistoryClear => '清除所有';

  @override
  String get searchSearching => '搜尋中...';

  @override
  String get playerPlay => '播放';

  @override
  String get playerPause => '暫停';

  @override
  String get playerNext => '下一首';

  @override
  String get playerPrevious => '上一首';

  @override
  String get playerLyrics => '歌詞';

  @override
  String get playerQueue => '播放清單';

  @override
  String get playerShuffle => '隨機播放';

  @override
  String get playerRepeat => '循環播放';

  @override
  String get playerRepeatOne => '單曲循環';

  @override
  String get playerRepeatOff => '關閉循環';

  @override
  String get playerSpeed => '速度';

  @override
  String get playerQuality => '音質';

  @override
  String get playerNoLyrics => '暫無歌詞';

  @override
  String get playerAudioCacheError => '音訊快取錯誤';

  @override
  String get playerVolume => '音量';

  @override
  String get unknownSong => '未知歌曲';

  @override
  String get unknownArtist => '未知藝術家';

  @override
  String get unknownAlbum => '未知專輯';

  @override
  String get noSongPlaying => '無播放中的歌曲';

  @override
  String get songInfo => '歌曲資訊';

  @override
  String get addToFavorites => '加入最愛';

  @override
  String get removeFromFavorites => '取消最愛';

  @override
  String get playQueue => '播放隊列';

  @override
  String get serverOffline => '服務器已離線';

  @override
  String get exportMusicFile => '匯出音樂檔案';

  @override
  String get downloadStarted => '開始下載...';

  @override
  String get downloadComplete => '下載完成！';

  @override
  String get downloadFailed => '下載失敗';

  @override
  String get noCacheOrServer => '無法連接伺服器，且無本機快取';

  @override
  String get songDetails => '歌曲詳細資訊';

  @override
  String get songTitle => '標題';

  @override
  String get songArtist => '藝術家';

  @override
  String get songAlbum => '專輯';

  @override
  String get songYear => '年份';

  @override
  String get songDuration => '時長';

  @override
  String get songFormat => '格式';

  @override
  String get songBitrate => '位元率';

  @override
  String get songFileSize => '檔案大小';

  @override
  String get showHomeScreen => '顯示主畫面';

  @override
  String get exitApp => '退出程式';

  @override
  String get unknownYear => '未知年份';

  @override
  String get unfavorited => '已取消收藏';

  @override
  String get favorited => '已加入收藏';

  @override
  String favoriteFailed(String error) {
    return '收藏失敗：$error';
  }

  @override
  String queueSongCount(String count) {
    return '$count 首歌曲';
  }

  @override
  String get removeFromQueue => '從隊列移除';

  @override
  String get albumInfoNotFound => '找不到專輯資訊';

  @override
  String get cannotGetLocalImage => '無法取得本地圖片檔案';

  @override
  String get imageExportedSuccessfully => '圖片已成功匯出';

  @override
  String exportFailed(String error) {
    return '匯出失敗：$error';
  }

  @override
  String operationFailed(String error) {
    return '操作失敗：$error';
  }

  @override
  String songCount(String count) {
    return '$count 首歌';
  }

  @override
  String loadFailed(String error) {
    return '加載失敗: $error';
  }

  @override
  String get offlineOperationFailed => '離線操作失敗，可能歌曲無法下載或伺服器錯誤';

  @override
  String get offlineStatus => '已離線';

  @override
  String get offline => '離線';

  @override
  String get savedToOfflineMusic => '已儲存至離線音樂';

  @override
  String get offlineAllAlbumSongs => '離線本專輯所有歌曲';

  @override
  String songCountWidget(String count) {
    return '$count 首';
  }

  @override
  String get qqMusic => 'QQ 音樂';

  @override
  String get neteaseMusic => '網易雲音樂';

  @override
  String get searchInOtherPlatforms => '在其他串流平台搜尋';

  @override
  String get cannotLoadArtistData => '無法載入藝術家資料';

  @override
  String albumCountVar(String count) {
    return '$count 張專輯';
  }

  @override
  String songCountVar(String count) {
    return '$count 首歌';
  }

  @override
  String get about => '關於';

  @override
  String get popularSongs => '熱門歌曲';

  @override
  String get showMore => '顯示更多';

  @override
  String loadFailedErr(String error) {
    return '載入失敗: $error';
  }

  @override
  String get readMore => '閱讀更多';

  @override
  String get collapse => '收起';

  @override
  String get serverNotConnectedHint => '未連接伺服器，請先在右上角新增';

  @override
  String get noFavoriteAlbums => '目前沒有任何喜愛的專輯';

  @override
  String get favoriteAlbumsTitle => '收藏的專輯';

  @override
  String totalAlbumsCount(String count) {
    return '共 $count 張專輯';
  }

  @override
  String get shufflePlayAnAlbum => '隨機播放一張專輯';

  @override
  String loadFavoritesFailed(String error) {
    return '加載喜愛項目失敗: $error';
  }

  @override
  String get loadServerStatusFailed => '加載伺服器狀態失敗';

  @override
  String get noFavoriteSongs => '目前沒有任何喜愛的歌曲';

  @override
  String get offlineSyncEnabled => '已開啟離線同步';

  @override
  String totalSongsCountWidget(String count) {
    return '共 $count 首歌曲';
  }

  @override
  String get offlineFavoriteSongs => '離線最愛歌曲';

  @override
  String songCountWidgetShort(String count) {
    return '$count 首';
  }

  @override
  String get playAll => '播放全部';

  @override
  String get startPlayingFavoriteSongs => '開始播放最愛歌曲';

  @override
  String get unknown => '未知';

  @override
  String downloadError(String error) {
    return '下載時發生錯誤：$error';
  }

  @override
  String get songs => '歌曲';

  @override
  String get cannotLoadPlaylist => '無法載入播放清單';

  @override
  String playlistSongCount(String count) {
    return '$count 首歌曲';
  }

  @override
  String get playlistIsEmpty => '播放清單是空的';

  @override
  String get savedServers => '已儲存的伺服器';

  @override
  String get deleteServer => '刪除伺服器';

  @override
  String get confirmDeleteServer => '確定要刪除這個伺服器嗎？此操作無法還原。';

  @override
  String get cancel => '取消';

  @override
  String get confirmDelete => '確認刪除';

  @override
  String get serverConnectionOrAuthFailed => '無法連線至伺服器或驗證失敗，請檢查設定。';

  @override
  String get connectionError => '連線發生錯誤。';

  @override
  String get editServer => '編輯伺服器';

  @override
  String get addServer => '新增伺服器';

  @override
  String get enterServerInfo => '請輸入 Navidrome / Subsonic 伺服器資訊';

  @override
  String get serverUrlExample => 'URL (例如: http://192.168.1.100:4533)';

  @override
  String get username => '帳號';

  @override
  String get password => '密碼';

  @override
  String get delete => '刪除';

  @override
  String get saveChanges => '儲存變更';

  @override
  String get save => '儲存';

  @override
  String get checkServer => '檢查伺服器';

  @override
  String get cannotConnectCheckSettings => '無法連線至該伺服器，請檢查網路或伺服器設定。';

  @override
  String get serverConnectionError => '伺服器連線發生錯誤。';

  @override
  String get addNavidromeOrSubsonic => '新增 Navidrome 或 Subsonic 連線';

  @override
  String get noServerConfigured => '未設定伺服器';

  @override
  String get themeDescription => '切換深色模式、淺色模式或跟隨系統設定';

  @override
  String get selectTheme => '選擇主題';

  @override
  String get playbackCacheManagement => '播放快取管理';

  @override
  String cacheUsed(String size, String count) {
    return '已使用快取: $size ($count 首歌曲)';
  }

  @override
  String get clearCache => '清除快取';

  @override
  String get offlineMusicCacheLocation => '離線音樂與快取儲存位置';

  @override
  String get loading => '載入中...';

  @override
  String get selectThisDirectory => '選擇此目錄';

  @override
  String get preparingToMoveFiles => '準備搬移檔案...';

  @override
  String get movingFiles => '搬移檔案中';

  @override
  String movedFilesProgress(String current, String total) {
    return '已搬移 $current / $total 個檔案';
  }

  @override
  String get updatingDatabase => '更新資料庫中...';

  @override
  String errorOccurred(String error) {
    return '發生錯誤: $error';
  }

  @override
  String get changeDirectory => '變更目錄';

  @override
  String get noLimit => '無上限';

  @override
  String get cacheSizeLimit => '快取容量上限';

  @override
  String get reduceCacheSize => '縮減快取容量';

  @override
  String currentCacheUsedStr(String size) {
    return '目前的快取總共使用了 $size。\\n';
  }

  @override
  String cacheLimitWarning(String limit, String excess) {
    return '如果將上限設定為 $limit GB，系統將會自動清除約 $excess 最久未聽過的音樂來釋放空間。';
  }

  @override
  String get confirmClear => '確定清除';

  @override
  String get serverManagement => '伺服器管理';

  @override
  String connectedToServer(String url, String username) {
    return '已連線至 $url ($username)';
  }

  @override
  String get noSubsonicServerConfigured => '尚未設定 Subsonic 伺服器';

  @override
  String get appSlogan => '極簡現代黑白風 Subsonic 音樂播放器';

  @override
  String get errorCannotConnectServer => '錯誤：無法連線伺服器';

  @override
  String get startSyncingArtists => '開始同步藝術家...';

  @override
  String get startSyncingAlbums => '開始同步專輯...';

  @override
  String syncedAlbumsCount(String count) {
    return '已同步 $count 張專輯';
  }

  @override
  String get preparingToDownloadCovers => '準備下載封面圖片...';

  @override
  String downloadingCoversProgress(String downloaded, String total) {
    return '下載封面圖片中... ($downloaded/$total)';
  }

  @override
  String get syncingFavorites => '同步最愛項目...';

  @override
  String get syncingPlaylists => '同步播放清單...';

  @override
  String get syncingOfflineAlbums => '同步離線專輯資料中...';

  @override
  String syncingOfflineAlbumsProgress(String fetched, String total) {
    return '同步離線專輯資料中... ($fetched/$total)';
  }

  @override
  String syncCompleteAlbumsLoaded(String count) {
    return '同步完成！共載入 $count 張專輯。';
  }

  @override
  String syncFailed(String error) {
    return '同步失敗：$error';
  }

  @override
  String get noAlbumsFound => '沒有找到任何專輯';

  @override
  String loadAlbumsFailed(String error) {
    return '加載專輯失敗: $error';
  }

  @override
  String get noArtistsFound => '沒有找到藝術家';

  @override
  String loadArtistsFailed(String error) {
    return '加載藝術家失敗: $error';
  }

  @override
  String get noOfflineAlbumsYet => '尚無已離線的專輯';

  @override
  String totalSortedAlbumsCount(String count) {
    return '共 $count 張專輯';
  }

  @override
  String get noOfflineSongsYet => '尚無已離線的歌曲';

  @override
  String totalSortedSongsCount(String count) {
    return '共 $count 首歌曲';
  }

  @override
  String get deletedAllOfflineMusic => '已刪除所有手動離線的音樂';

  @override
  String get confirm => '確認';

  @override
  String get finalConfirm => '最終確認';

  @override
  String get deleteAll => '刪除全部';

  @override
  String get favoriteCategories => '珍藏分類';

  @override
  String get favoriteSinglesAndPersonalFavorites => '喜愛單曲與個人最愛';

  @override
  String songsCountOnly(String count) {
    return '$count 首';
  }

  @override
  String get favoritedMusicAlbums => '已收藏的音樂專輯';

  @override
  String albumsCountOnly(String count) {
    return '$count 張';
  }

  @override
  String get customMusicPlaylists => '自訂音樂歌單';

  @override
  String playlistsCountOnly(String count) {
    return '$count 個';
  }

  @override
  String get offlineMusicAndCache => '離線音樂與快取';

  @override
  String validDownloadsCount(String count) {
    return '$count 首';
  }

  @override
  String get appSettings => '應用程式設定';

  @override
  String get settings => '設定';

  @override
  String get personalMusicCollection => '個人音樂珍藏';

  @override
  String songsCountFull(String count) {
    return '$count 首歌曲';
  }

  @override
  String albumsCountVarFull(String count) {
    return '$count 張專輯';
  }

  @override
  String get shuffleFavoriteSongs => '隨機播放最愛歌曲';

  @override
  String get noPlaylistsCurrently => '目前沒有播放清單';

  @override
  String totalPlaylistsCount(String count) {
    return '共 $count 個歌單';
  }

  @override
  String songsCountAndDuration(String songCount, String durationMinutes) {
    return '$songCount 首歌曲 • $durationMinutes 分鐘';
  }

  @override
  String get songListComingSoon => '歌曲清單即將推出';

  @override
  String get navPlaylists => '播放清單';
}
