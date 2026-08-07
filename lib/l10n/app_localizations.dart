import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('zh', 'TW'),
    Locale('en'),
    Locale('zh', 'CN'),
    Locale('zh'),
  ];

  /// No description provided for @welcomeSubtitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'請選擇伺服器'**
  String get welcomeSubtitle;

  /// No description provided for @settingsTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'系統設定與偏好'**
  String get settingsTitle;

  /// No description provided for @themeAppearance.
  ///
  /// In zh_TW, this message translates to:
  /// **'主題外觀'**
  String get themeAppearance;

  /// No description provided for @themeLight.
  ///
  /// In zh_TW, this message translates to:
  /// **'淺色模式'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In zh_TW, this message translates to:
  /// **'深色模式'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In zh_TW, this message translates to:
  /// **'自動 (系統)'**
  String get themeSystem;

  /// No description provided for @storageAndCache.
  ///
  /// In zh_TW, this message translates to:
  /// **'儲存與快取'**
  String get storageAndCache;

  /// No description provided for @accountAndServer.
  ///
  /// In zh_TW, this message translates to:
  /// **'帳號與伺服器'**
  String get accountAndServer;

  /// No description provided for @aboutZenify.
  ///
  /// In zh_TW, this message translates to:
  /// **'關於 ZENIFY'**
  String get aboutZenify;

  /// No description provided for @languageSetting.
  ///
  /// In zh_TW, this message translates to:
  /// **'語言'**
  String get languageSetting;

  /// No description provided for @languageSystem.
  ///
  /// In zh_TW, this message translates to:
  /// **'跟隨系統'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In zh_TW, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageTraditionalChinese.
  ///
  /// In zh_TW, this message translates to:
  /// **'繁體中文'**
  String get languageTraditionalChinese;

  /// No description provided for @languageSimplifiedChinese.
  ///
  /// In zh_TW, this message translates to:
  /// **'简体中文'**
  String get languageSimplifiedChinese;

  /// No description provided for @languageDescription.
  ///
  /// In zh_TW, this message translates to:
  /// **'選擇您偏好的介面語言'**
  String get languageDescription;

  /// No description provided for @navAlbums.
  ///
  /// In zh_TW, this message translates to:
  /// **'專輯'**
  String get navAlbums;

  /// No description provided for @navArtists.
  ///
  /// In zh_TW, this message translates to:
  /// **'藝術家'**
  String get navArtists;

  /// No description provided for @navFavorites.
  ///
  /// In zh_TW, this message translates to:
  /// **'最愛'**
  String get navFavorites;

  /// No description provided for @navSearch.
  ///
  /// In zh_TW, this message translates to:
  /// **'搜尋'**
  String get navSearch;

  /// No description provided for @homeConnectionTesting.
  ///
  /// In zh_TW, this message translates to:
  /// **'連線測試中...'**
  String get homeConnectionTesting;

  /// No description provided for @homeOffline.
  ///
  /// In zh_TW, this message translates to:
  /// **'Offline.'**
  String get homeOffline;

  /// No description provided for @homeSyncing.
  ///
  /// In zh_TW, this message translates to:
  /// **'同步中...'**
  String get homeSyncing;

  /// No description provided for @homeSyncNow.
  ///
  /// In zh_TW, this message translates to:
  /// **'立即同步'**
  String get homeSyncNow;

  /// No description provided for @homeStatsTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'本地資料統計'**
  String get homeStatsTitle;

  /// No description provided for @homeStatsAlbums.
  ///
  /// In zh_TW, this message translates to:
  /// **'專輯數量'**
  String get homeStatsAlbums;

  /// No description provided for @homeStatsArtists.
  ///
  /// In zh_TW, this message translates to:
  /// **'藝術家數量'**
  String get homeStatsArtists;

  /// No description provided for @homeStatsCovers.
  ///
  /// In zh_TW, this message translates to:
  /// **'已下載封面'**
  String get homeStatsCovers;

  /// No description provided for @homeSortDefault.
  ///
  /// In zh_TW, this message translates to:
  /// **'預設排序'**
  String get homeSortDefault;

  /// No description provided for @homeSortNameAsc.
  ///
  /// In zh_TW, this message translates to:
  /// **'名稱 (A-Z)'**
  String get homeSortNameAsc;

  /// No description provided for @homeSortNameDesc.
  ///
  /// In zh_TW, this message translates to:
  /// **'名稱 (Z-A)'**
  String get homeSortNameDesc;

  /// No description provided for @homeSortYearDesc.
  ///
  /// In zh_TW, this message translates to:
  /// **'年份 (新到舊)'**
  String get homeSortYearDesc;

  /// No description provided for @homeSortYearAsc.
  ///
  /// In zh_TW, this message translates to:
  /// **'年份 (舊到新)'**
  String get homeSortYearAsc;

  /// No description provided for @homeSortRandom.
  ///
  /// In zh_TW, this message translates to:
  /// **'隨機排列'**
  String get homeSortRandom;

  /// No description provided for @homeSortAlbumCountDesc.
  ///
  /// In zh_TW, this message translates to:
  /// **'專輯數量 (多到少)'**
  String get homeSortAlbumCountDesc;

  /// No description provided for @homeSortRecentDownload.
  ///
  /// In zh_TW, this message translates to:
  /// **'最近下載'**
  String get homeSortRecentDownload;

  /// No description provided for @homeTestConnectionFailed.
  ///
  /// In zh_TW, this message translates to:
  /// **'連線測試失敗，伺服器仍處於離線狀態'**
  String get homeTestConnectionFailed;

  /// No description provided for @homeTestConnectionSuccess.
  ///
  /// In zh_TW, this message translates to:
  /// **'連線成功！已恢復為正常模式'**
  String get homeTestConnectionSuccess;

  /// No description provided for @homeAudioPlayerDisposed.
  ///
  /// In zh_TW, this message translates to:
  /// **'音訊播放器已釋放，可以安全 Shift+R'**
  String get homeAudioPlayerDisposed;

  /// No description provided for @searchPlaceholder.
  ///
  /// In zh_TW, this message translates to:
  /// **'搜尋歌曲、專輯或藝術家...'**
  String get searchPlaceholder;

  /// No description provided for @searchHistory.
  ///
  /// In zh_TW, this message translates to:
  /// **'近期搜尋'**
  String get searchHistory;

  /// No description provided for @searchNoResults.
  ///
  /// In zh_TW, this message translates to:
  /// **'找不到相關結果'**
  String get searchNoResults;

  /// No description provided for @searchHistoryClear.
  ///
  /// In zh_TW, this message translates to:
  /// **'清除所有'**
  String get searchHistoryClear;

  /// No description provided for @searchSearching.
  ///
  /// In zh_TW, this message translates to:
  /// **'搜尋中...'**
  String get searchSearching;

  /// No description provided for @playerPlay.
  ///
  /// In zh_TW, this message translates to:
  /// **'播放'**
  String get playerPlay;

  /// No description provided for @playerPause.
  ///
  /// In zh_TW, this message translates to:
  /// **'暫停'**
  String get playerPause;

  /// No description provided for @playerNext.
  ///
  /// In zh_TW, this message translates to:
  /// **'下一首'**
  String get playerNext;

  /// No description provided for @playerPrevious.
  ///
  /// In zh_TW, this message translates to:
  /// **'上一首'**
  String get playerPrevious;

  /// No description provided for @playerLyrics.
  ///
  /// In zh_TW, this message translates to:
  /// **'歌詞'**
  String get playerLyrics;

  /// No description provided for @playerQueue.
  ///
  /// In zh_TW, this message translates to:
  /// **'播放清單'**
  String get playerQueue;

  /// No description provided for @playerShuffle.
  ///
  /// In zh_TW, this message translates to:
  /// **'隨機播放'**
  String get playerShuffle;

  /// No description provided for @playerRepeat.
  ///
  /// In zh_TW, this message translates to:
  /// **'循環播放'**
  String get playerRepeat;

  /// No description provided for @playerRepeatOne.
  ///
  /// In zh_TW, this message translates to:
  /// **'單曲循環'**
  String get playerRepeatOne;

  /// No description provided for @playerRepeatOff.
  ///
  /// In zh_TW, this message translates to:
  /// **'關閉循環'**
  String get playerRepeatOff;

  /// No description provided for @playerSpeed.
  ///
  /// In zh_TW, this message translates to:
  /// **'速度'**
  String get playerSpeed;

  /// No description provided for @playerQuality.
  ///
  /// In zh_TW, this message translates to:
  /// **'音質'**
  String get playerQuality;

  /// No description provided for @playerNoLyrics.
  ///
  /// In zh_TW, this message translates to:
  /// **'暫無歌詞'**
  String get playerNoLyrics;

  /// No description provided for @playerAudioCacheError.
  ///
  /// In zh_TW, this message translates to:
  /// **'音訊快取錯誤'**
  String get playerAudioCacheError;

  /// No description provided for @playerVolume.
  ///
  /// In zh_TW, this message translates to:
  /// **'音量'**
  String get playerVolume;

  /// No description provided for @unknownSong.
  ///
  /// In zh_TW, this message translates to:
  /// **'未知歌曲'**
  String get unknownSong;

  /// No description provided for @unknownArtist.
  ///
  /// In zh_TW, this message translates to:
  /// **'未知藝術家'**
  String get unknownArtist;

  /// No description provided for @unknownAlbum.
  ///
  /// In zh_TW, this message translates to:
  /// **'未知專輯'**
  String get unknownAlbum;

  /// No description provided for @noSongPlaying.
  ///
  /// In zh_TW, this message translates to:
  /// **'無播放中的歌曲'**
  String get noSongPlaying;

  /// No description provided for @songInfo.
  ///
  /// In zh_TW, this message translates to:
  /// **'歌曲資訊'**
  String get songInfo;

  /// No description provided for @addToFavorites.
  ///
  /// In zh_TW, this message translates to:
  /// **'加入最愛'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In zh_TW, this message translates to:
  /// **'取消最愛'**
  String get removeFromFavorites;

  /// No description provided for @playQueue.
  ///
  /// In zh_TW, this message translates to:
  /// **'播放隊列'**
  String get playQueue;

  /// No description provided for @serverOffline.
  ///
  /// In zh_TW, this message translates to:
  /// **'服務器已離線'**
  String get serverOffline;

  /// No description provided for @exportMusicFile.
  ///
  /// In zh_TW, this message translates to:
  /// **'匯出音樂檔案'**
  String get exportMusicFile;

  /// No description provided for @downloadStarted.
  ///
  /// In zh_TW, this message translates to:
  /// **'開始下載...'**
  String get downloadStarted;

  /// No description provided for @downloadComplete.
  ///
  /// In zh_TW, this message translates to:
  /// **'下載完成！'**
  String get downloadComplete;

  /// No description provided for @downloadFailed.
  ///
  /// In zh_TW, this message translates to:
  /// **'下載失敗'**
  String get downloadFailed;

  /// No description provided for @noCacheOrServer.
  ///
  /// In zh_TW, this message translates to:
  /// **'無法連接伺服器，且無本機快取'**
  String get noCacheOrServer;

  /// No description provided for @songDetails.
  ///
  /// In zh_TW, this message translates to:
  /// **'歌曲詳細資訊'**
  String get songDetails;

  /// No description provided for @songTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'標題'**
  String get songTitle;

  /// No description provided for @songArtist.
  ///
  /// In zh_TW, this message translates to:
  /// **'藝術家'**
  String get songArtist;

  /// No description provided for @songAlbum.
  ///
  /// In zh_TW, this message translates to:
  /// **'專輯'**
  String get songAlbum;

  /// No description provided for @songYear.
  ///
  /// In zh_TW, this message translates to:
  /// **'年份'**
  String get songYear;

  /// No description provided for @songDuration.
  ///
  /// In zh_TW, this message translates to:
  /// **'時長'**
  String get songDuration;

  /// No description provided for @songFormat.
  ///
  /// In zh_TW, this message translates to:
  /// **'格式'**
  String get songFormat;

  /// No description provided for @songBitrate.
  ///
  /// In zh_TW, this message translates to:
  /// **'位元率'**
  String get songBitrate;

  /// No description provided for @songFileSize.
  ///
  /// In zh_TW, this message translates to:
  /// **'檔案大小'**
  String get songFileSize;

  /// No description provided for @showHomeScreen.
  ///
  /// In zh_TW, this message translates to:
  /// **'顯示主畫面'**
  String get showHomeScreen;

  /// No description provided for @exitApp.
  ///
  /// In zh_TW, this message translates to:
  /// **'退出程式'**
  String get exitApp;

  /// No description provided for @unknownYear.
  ///
  /// In zh_TW, this message translates to:
  /// **'未知年份'**
  String get unknownYear;

  /// No description provided for @unfavorited.
  ///
  /// In zh_TW, this message translates to:
  /// **'已取消收藏'**
  String get unfavorited;

  /// No description provided for @favorited.
  ///
  /// In zh_TW, this message translates to:
  /// **'已加入收藏'**
  String get favorited;

  /// No description provided for @favoriteFailed.
  ///
  /// In zh_TW, this message translates to:
  /// **'收藏失敗：{error}'**
  String favoriteFailed(String error);

  /// No description provided for @queueSongCount.
  ///
  /// In zh_TW, this message translates to:
  /// **'{count} 首歌曲'**
  String queueSongCount(String count);

  /// No description provided for @removeFromQueue.
  ///
  /// In zh_TW, this message translates to:
  /// **'從隊列移除'**
  String get removeFromQueue;

  /// No description provided for @albumInfoNotFound.
  ///
  /// In zh_TW, this message translates to:
  /// **'找不到專輯資訊'**
  String get albumInfoNotFound;

  /// No description provided for @cannotGetLocalImage.
  ///
  /// In zh_TW, this message translates to:
  /// **'無法取得本地圖片檔案'**
  String get cannotGetLocalImage;

  /// No description provided for @imageExportedSuccessfully.
  ///
  /// In zh_TW, this message translates to:
  /// **'圖片已成功匯出'**
  String get imageExportedSuccessfully;

  /// No description provided for @exportFailed.
  ///
  /// In zh_TW, this message translates to:
  /// **'匯出失敗：{error}'**
  String exportFailed(String error);

  /// No description provided for @operationFailed.
  ///
  /// In zh_TW, this message translates to:
  /// **'操作失敗：{error}'**
  String operationFailed(String error);

  /// No description provided for @songCount.
  ///
  /// In zh_TW, this message translates to:
  /// **'{count} 首歌'**
  String songCount(String count);

  /// No description provided for @loadFailed.
  ///
  /// In zh_TW, this message translates to:
  /// **'加載失敗: {error}'**
  String loadFailed(String error);

  /// No description provided for @offlineOperationFailed.
  ///
  /// In zh_TW, this message translates to:
  /// **'離線操作失敗，可能歌曲無法下載或伺服器錯誤'**
  String get offlineOperationFailed;

  /// No description provided for @offlineStatus.
  ///
  /// In zh_TW, this message translates to:
  /// **'已離線'**
  String get offlineStatus;

  /// No description provided for @offline.
  ///
  /// In zh_TW, this message translates to:
  /// **'離線'**
  String get offline;

  /// No description provided for @savedToOfflineMusic.
  ///
  /// In zh_TW, this message translates to:
  /// **'已儲存至離線音樂'**
  String get savedToOfflineMusic;

  /// No description provided for @offlineAllAlbumSongs.
  ///
  /// In zh_TW, this message translates to:
  /// **'離線本專輯所有歌曲'**
  String get offlineAllAlbumSongs;

  /// No description provided for @songCountWidget.
  ///
  /// In zh_TW, this message translates to:
  /// **'{count} 首'**
  String songCountWidget(String count);

  /// No description provided for @qqMusic.
  ///
  /// In zh_TW, this message translates to:
  /// **'QQ 音樂'**
  String get qqMusic;

  /// No description provided for @neteaseMusic.
  ///
  /// In zh_TW, this message translates to:
  /// **'網易雲音樂'**
  String get neteaseMusic;

  /// No description provided for @searchInOtherPlatforms.
  ///
  /// In zh_TW, this message translates to:
  /// **'在其他串流平台搜尋'**
  String get searchInOtherPlatforms;

  /// No description provided for @cannotLoadArtistData.
  ///
  /// In zh_TW, this message translates to:
  /// **'無法載入藝術家資料'**
  String get cannotLoadArtistData;

  /// No description provided for @albumCountVar.
  ///
  /// In zh_TW, this message translates to:
  /// **'{count} 張專輯'**
  String albumCountVar(String count);

  /// No description provided for @songCountVar.
  ///
  /// In zh_TW, this message translates to:
  /// **'{count} 首歌'**
  String songCountVar(String count);

  /// No description provided for @about.
  ///
  /// In zh_TW, this message translates to:
  /// **'關於'**
  String get about;

  /// No description provided for @popularSongs.
  ///
  /// In zh_TW, this message translates to:
  /// **'熱門歌曲'**
  String get popularSongs;

  /// No description provided for @showMore.
  ///
  /// In zh_TW, this message translates to:
  /// **'顯示更多'**
  String get showMore;

  /// No description provided for @loadFailedErr.
  ///
  /// In zh_TW, this message translates to:
  /// **'載入失敗: {error}'**
  String loadFailedErr(String error);

  /// No description provided for @readMore.
  ///
  /// In zh_TW, this message translates to:
  /// **'閱讀更多'**
  String get readMore;

  /// No description provided for @collapse.
  ///
  /// In zh_TW, this message translates to:
  /// **'收起'**
  String get collapse;

  /// No description provided for @serverNotConnectedHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'未連接伺服器，請先在右上角新增'**
  String get serverNotConnectedHint;

  /// No description provided for @noFavoriteAlbums.
  ///
  /// In zh_TW, this message translates to:
  /// **'目前沒有任何喜愛的專輯'**
  String get noFavoriteAlbums;

  /// No description provided for @favoriteAlbumsTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'收藏的專輯'**
  String get favoriteAlbumsTitle;

  /// No description provided for @totalAlbumsCount.
  ///
  /// In zh_TW, this message translates to:
  /// **'共 {count} 張專輯'**
  String totalAlbumsCount(String count);

  /// No description provided for @shufflePlayAnAlbum.
  ///
  /// In zh_TW, this message translates to:
  /// **'隨機播放一張專輯'**
  String get shufflePlayAnAlbum;

  /// No description provided for @loadFavoritesFailed.
  ///
  /// In zh_TW, this message translates to:
  /// **'加載喜愛項目失敗: {error}'**
  String loadFavoritesFailed(String error);

  /// No description provided for @loadServerStatusFailed.
  ///
  /// In zh_TW, this message translates to:
  /// **'加載伺服器狀態失敗'**
  String get loadServerStatusFailed;

  /// No description provided for @noFavoriteSongs.
  ///
  /// In zh_TW, this message translates to:
  /// **'目前沒有任何喜愛的歌曲'**
  String get noFavoriteSongs;

  /// No description provided for @offlineSyncEnabled.
  ///
  /// In zh_TW, this message translates to:
  /// **'已開啟離線同步'**
  String get offlineSyncEnabled;

  /// No description provided for @totalSongsCountWidget.
  ///
  /// In zh_TW, this message translates to:
  /// **'共 {count} 首歌曲'**
  String totalSongsCountWidget(String count);

  /// No description provided for @offlineFavoriteSongs.
  ///
  /// In zh_TW, this message translates to:
  /// **'離線最愛歌曲'**
  String get offlineFavoriteSongs;

  /// No description provided for @songCountWidgetShort.
  ///
  /// In zh_TW, this message translates to:
  /// **'{count} 首'**
  String songCountWidgetShort(String count);

  /// No description provided for @playAll.
  ///
  /// In zh_TW, this message translates to:
  /// **'播放全部'**
  String get playAll;

  /// No description provided for @startPlayingFavoriteSongs.
  ///
  /// In zh_TW, this message translates to:
  /// **'開始播放最愛歌曲'**
  String get startPlayingFavoriteSongs;

  /// No description provided for @unknown.
  ///
  /// In zh_TW, this message translates to:
  /// **'未知'**
  String get unknown;

  /// No description provided for @downloadError.
  ///
  /// In zh_TW, this message translates to:
  /// **'下載時發生錯誤：{error}'**
  String downloadError(String error);

  /// No description provided for @songs.
  ///
  /// In zh_TW, this message translates to:
  /// **'歌曲'**
  String get songs;

  /// No description provided for @cannotLoadPlaylist.
  ///
  /// In zh_TW, this message translates to:
  /// **'無法載入播放清單'**
  String get cannotLoadPlaylist;

  /// No description provided for @playlistSongCount.
  ///
  /// In zh_TW, this message translates to:
  /// **'{count} 首歌曲'**
  String playlistSongCount(String count);

  /// No description provided for @playlistIsEmpty.
  ///
  /// In zh_TW, this message translates to:
  /// **'播放清單是空的'**
  String get playlistIsEmpty;

  /// No description provided for @savedServers.
  ///
  /// In zh_TW, this message translates to:
  /// **'已儲存的伺服器'**
  String get savedServers;

  /// No description provided for @deleteServer.
  ///
  /// In zh_TW, this message translates to:
  /// **'刪除伺服器'**
  String get deleteServer;

  /// No description provided for @confirmDeleteServer.
  ///
  /// In zh_TW, this message translates to:
  /// **'確定要刪除這個伺服器嗎？此操作無法還原。'**
  String get confirmDeleteServer;

  /// No description provided for @cancel.
  ///
  /// In zh_TW, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @confirmDelete.
  ///
  /// In zh_TW, this message translates to:
  /// **'確認刪除'**
  String get confirmDelete;

  /// No description provided for @serverConnectionOrAuthFailed.
  ///
  /// In zh_TW, this message translates to:
  /// **'無法連線至伺服器或驗證失敗，請檢查設定。'**
  String get serverConnectionOrAuthFailed;

  /// No description provided for @connectionError.
  ///
  /// In zh_TW, this message translates to:
  /// **'連線發生錯誤。'**
  String get connectionError;

  /// No description provided for @editServer.
  ///
  /// In zh_TW, this message translates to:
  /// **'編輯伺服器'**
  String get editServer;

  /// No description provided for @addServer.
  ///
  /// In zh_TW, this message translates to:
  /// **'新增伺服器'**
  String get addServer;

  /// No description provided for @enterServerInfo.
  ///
  /// In zh_TW, this message translates to:
  /// **'請輸入 Navidrome / Subsonic 伺服器資訊'**
  String get enterServerInfo;

  /// No description provided for @serverUrlExample.
  ///
  /// In zh_TW, this message translates to:
  /// **'URL (例如: http://192.168.1.100:4533)'**
  String get serverUrlExample;

  /// No description provided for @username.
  ///
  /// In zh_TW, this message translates to:
  /// **'帳號'**
  String get username;

  /// No description provided for @password.
  ///
  /// In zh_TW, this message translates to:
  /// **'密碼'**
  String get password;

  /// No description provided for @delete.
  ///
  /// In zh_TW, this message translates to:
  /// **'刪除'**
  String get delete;

  /// No description provided for @saveChanges.
  ///
  /// In zh_TW, this message translates to:
  /// **'儲存變更'**
  String get saveChanges;

  /// No description provided for @save.
  ///
  /// In zh_TW, this message translates to:
  /// **'儲存'**
  String get save;

  /// No description provided for @checkServer.
  ///
  /// In zh_TW, this message translates to:
  /// **'測試'**
  String get checkServer;

  /// No description provided for @cannotConnectCheckSettings.
  ///
  /// In zh_TW, this message translates to:
  /// **'無法連線至該伺服器，請檢查網路或伺服器設定。'**
  String get cannotConnectCheckSettings;

  /// No description provided for @serverConnectionError.
  ///
  /// In zh_TW, this message translates to:
  /// **'伺服器連線發生錯誤。'**
  String get serverConnectionError;

  /// No description provided for @addNavidromeOrSubsonic.
  ///
  /// In zh_TW, this message translates to:
  /// **'新增 Navidrome 或 Subsonic 連線'**
  String get addNavidromeOrSubsonic;

  /// No description provided for @noServerConfigured.
  ///
  /// In zh_TW, this message translates to:
  /// **'未設定伺服器'**
  String get noServerConfigured;

  /// No description provided for @themeDescription.
  ///
  /// In zh_TW, this message translates to:
  /// **'切換深色模式、淺色模式或跟隨系統設定'**
  String get themeDescription;

  /// No description provided for @selectTheme.
  ///
  /// In zh_TW, this message translates to:
  /// **'選擇主題'**
  String get selectTheme;

  /// No description provided for @playbackCacheManagement.
  ///
  /// In zh_TW, this message translates to:
  /// **'播放快取管理'**
  String get playbackCacheManagement;

  /// No description provided for @cacheUsed.
  ///
  /// In zh_TW, this message translates to:
  /// **'已使用快取: {size} ({count} 首歌曲)'**
  String cacheUsed(String size, String count);

  /// No description provided for @clearCache.
  ///
  /// In zh_TW, this message translates to:
  /// **'清除快取'**
  String get clearCache;

  /// No description provided for @offlineMusicCacheLocation.
  ///
  /// In zh_TW, this message translates to:
  /// **'離線音樂與快取儲存位置'**
  String get offlineMusicCacheLocation;

  /// No description provided for @loading.
  ///
  /// In zh_TW, this message translates to:
  /// **'載入中...'**
  String get loading;

  /// No description provided for @selectThisDirectory.
  ///
  /// In zh_TW, this message translates to:
  /// **'選擇此目錄'**
  String get selectThisDirectory;

  /// No description provided for @preparingToMoveFiles.
  ///
  /// In zh_TW, this message translates to:
  /// **'準備搬移檔案...'**
  String get preparingToMoveFiles;

  /// No description provided for @movingFiles.
  ///
  /// In zh_TW, this message translates to:
  /// **'搬移檔案中'**
  String get movingFiles;

  /// No description provided for @movedFilesProgress.
  ///
  /// In zh_TW, this message translates to:
  /// **'已搬移 {current} / {total} 個檔案'**
  String movedFilesProgress(String current, String total);

  /// No description provided for @updatingDatabase.
  ///
  /// In zh_TW, this message translates to:
  /// **'更新資料庫中...'**
  String get updatingDatabase;

  /// No description provided for @errorOccurred.
  ///
  /// In zh_TW, this message translates to:
  /// **'發生錯誤: {error}'**
  String errorOccurred(String error);

  /// No description provided for @changeDirectory.
  ///
  /// In zh_TW, this message translates to:
  /// **'變更目錄'**
  String get changeDirectory;

  /// No description provided for @noLimit.
  ///
  /// In zh_TW, this message translates to:
  /// **'無上限'**
  String get noLimit;

  /// No description provided for @cacheSizeLimit.
  ///
  /// In zh_TW, this message translates to:
  /// **'快取容量上限'**
  String get cacheSizeLimit;

  /// No description provided for @reduceCacheSize.
  ///
  /// In zh_TW, this message translates to:
  /// **'縮減快取容量'**
  String get reduceCacheSize;

  /// No description provided for @currentCacheUsedStr.
  ///
  /// In zh_TW, this message translates to:
  /// **'目前的快取總共使用了 {size}。\\n'**
  String currentCacheUsedStr(String size);

  /// No description provided for @cacheLimitWarning.
  ///
  /// In zh_TW, this message translates to:
  /// **'如果將上限設定為 {limit} GB，系統將會自動清除約 {excess} 最久未聽過的音樂來釋放空間。'**
  String cacheLimitWarning(String limit, String excess);

  /// No description provided for @confirmClear.
  ///
  /// In zh_TW, this message translates to:
  /// **'確定清除'**
  String get confirmClear;

  /// No description provided for @serverManagement.
  ///
  /// In zh_TW, this message translates to:
  /// **'伺服器管理'**
  String get serverManagement;

  /// No description provided for @connectedToServer.
  ///
  /// In zh_TW, this message translates to:
  /// **'已連線至 {url} ({username})'**
  String connectedToServer(String url, String username);

  /// No description provided for @noSubsonicServerConfigured.
  ///
  /// In zh_TW, this message translates to:
  /// **'尚未設定 Subsonic 伺服器'**
  String get noSubsonicServerConfigured;

  /// No description provided for @appSlogan.
  ///
  /// In zh_TW, this message translates to:
  /// **'極簡現代黑白風 Subsonic 音樂播放器'**
  String get appSlogan;

  /// No description provided for @errorCannotConnectServer.
  ///
  /// In zh_TW, this message translates to:
  /// **'錯誤：無法連線伺服器'**
  String get errorCannotConnectServer;

  /// No description provided for @startSyncingArtists.
  ///
  /// In zh_TW, this message translates to:
  /// **'開始同步藝術家...'**
  String get startSyncingArtists;

  /// No description provided for @startSyncingAlbums.
  ///
  /// In zh_TW, this message translates to:
  /// **'開始同步專輯...'**
  String get startSyncingAlbums;

  /// No description provided for @syncedAlbumsCount.
  ///
  /// In zh_TW, this message translates to:
  /// **'已同步 {count} 張專輯'**
  String syncedAlbumsCount(String count);

  /// No description provided for @preparingToDownloadCovers.
  ///
  /// In zh_TW, this message translates to:
  /// **'準備下載封面圖片...'**
  String get preparingToDownloadCovers;

  /// No description provided for @downloadingCoversProgress.
  ///
  /// In zh_TW, this message translates to:
  /// **'下載封面圖片中... ({downloaded}/{total})'**
  String downloadingCoversProgress(String downloaded, String total);

  /// No description provided for @syncingFavorites.
  ///
  /// In zh_TW, this message translates to:
  /// **'同步最愛項目...'**
  String get syncingFavorites;

  /// No description provided for @syncingPlaylists.
  ///
  /// In zh_TW, this message translates to:
  /// **'同步播放清單...'**
  String get syncingPlaylists;

  /// No description provided for @syncingOfflineAlbums.
  ///
  /// In zh_TW, this message translates to:
  /// **'同步離線專輯資料中...'**
  String get syncingOfflineAlbums;

  /// No description provided for @syncingOfflineAlbumsProgress.
  ///
  /// In zh_TW, this message translates to:
  /// **'同步離線專輯資料中... ({fetched}/{total})'**
  String syncingOfflineAlbumsProgress(String fetched, String total);

  /// No description provided for @syncCompleteAlbumsLoaded.
  ///
  /// In zh_TW, this message translates to:
  /// **'同步完成！共載入 {count} 張專輯。'**
  String syncCompleteAlbumsLoaded(String count);

  /// No description provided for @syncFailed.
  ///
  /// In zh_TW, this message translates to:
  /// **'同步失敗：{error}'**
  String syncFailed(String error);

  /// No description provided for @noAlbumsFound.
  ///
  /// In zh_TW, this message translates to:
  /// **'沒有找到任何專輯'**
  String get noAlbumsFound;

  /// No description provided for @loadAlbumsFailed.
  ///
  /// In zh_TW, this message translates to:
  /// **'加載專輯失敗: {error}'**
  String loadAlbumsFailed(String error);

  /// No description provided for @noArtistsFound.
  ///
  /// In zh_TW, this message translates to:
  /// **'沒有找到藝術家'**
  String get noArtistsFound;

  /// No description provided for @loadArtistsFailed.
  ///
  /// In zh_TW, this message translates to:
  /// **'加載藝術家失敗: {error}'**
  String loadArtistsFailed(String error);

  /// No description provided for @noOfflineAlbumsYet.
  ///
  /// In zh_TW, this message translates to:
  /// **'尚無已離線的專輯'**
  String get noOfflineAlbumsYet;

  /// No description provided for @totalSortedAlbumsCount.
  ///
  /// In zh_TW, this message translates to:
  /// **'共 {count} 張專輯'**
  String totalSortedAlbumsCount(String count);

  /// No description provided for @noOfflineSongsYet.
  ///
  /// In zh_TW, this message translates to:
  /// **'尚無已離線的歌曲'**
  String get noOfflineSongsYet;

  /// No description provided for @totalSortedSongsCount.
  ///
  /// In zh_TW, this message translates to:
  /// **'共 {count} 首歌曲'**
  String totalSortedSongsCount(String count);

  /// No description provided for @deletedAllOfflineMusic.
  ///
  /// In zh_TW, this message translates to:
  /// **'已刪除所有手動離線的音樂'**
  String get deletedAllOfflineMusic;

  /// No description provided for @confirm.
  ///
  /// In zh_TW, this message translates to:
  /// **'確認'**
  String get confirm;

  /// No description provided for @finalConfirm.
  ///
  /// In zh_TW, this message translates to:
  /// **'最終確認'**
  String get finalConfirm;

  /// No description provided for @deleteAll.
  ///
  /// In zh_TW, this message translates to:
  /// **'刪除全部'**
  String get deleteAll;

  /// No description provided for @favoriteCategories.
  ///
  /// In zh_TW, this message translates to:
  /// **'珍藏分類'**
  String get favoriteCategories;

  /// No description provided for @favoriteSinglesAndPersonalFavorites.
  ///
  /// In zh_TW, this message translates to:
  /// **'喜愛單曲與個人最愛'**
  String get favoriteSinglesAndPersonalFavorites;

  /// No description provided for @songsCountOnly.
  ///
  /// In zh_TW, this message translates to:
  /// **'{count} 首'**
  String songsCountOnly(String count);

  /// No description provided for @favoritedMusicAlbums.
  ///
  /// In zh_TW, this message translates to:
  /// **'已收藏的音樂專輯'**
  String get favoritedMusicAlbums;

  /// No description provided for @albumsCountOnly.
  ///
  /// In zh_TW, this message translates to:
  /// **'{count} 張'**
  String albumsCountOnly(String count);

  /// No description provided for @customMusicPlaylists.
  ///
  /// In zh_TW, this message translates to:
  /// **'自訂音樂歌單'**
  String get customMusicPlaylists;

  /// No description provided for @playlistsCountOnly.
  ///
  /// In zh_TW, this message translates to:
  /// **'{count} 個'**
  String playlistsCountOnly(String count);

  /// No description provided for @offlineMusicAndCache.
  ///
  /// In zh_TW, this message translates to:
  /// **'離線音樂與快取'**
  String get offlineMusicAndCache;

  /// No description provided for @validDownloadsCount.
  ///
  /// In zh_TW, this message translates to:
  /// **'{count} 首'**
  String validDownloadsCount(String count);

  /// No description provided for @appSettings.
  ///
  /// In zh_TW, this message translates to:
  /// **'應用程式設定'**
  String get appSettings;

  /// No description provided for @settings.
  ///
  /// In zh_TW, this message translates to:
  /// **'設定'**
  String get settings;

  /// No description provided for @personalMusicCollection.
  ///
  /// In zh_TW, this message translates to:
  /// **'個人音樂珍藏'**
  String get personalMusicCollection;

  /// No description provided for @songsCountFull.
  ///
  /// In zh_TW, this message translates to:
  /// **'{count} 首歌曲'**
  String songsCountFull(String count);

  /// No description provided for @albumsCountVarFull.
  ///
  /// In zh_TW, this message translates to:
  /// **'{count} 張專輯'**
  String albumsCountVarFull(String count);

  /// No description provided for @shuffleFavoriteSongs.
  ///
  /// In zh_TW, this message translates to:
  /// **'隨機播放最愛歌曲'**
  String get shuffleFavoriteSongs;

  /// No description provided for @noPlaylistsCurrently.
  ///
  /// In zh_TW, this message translates to:
  /// **'目前沒有播放清單'**
  String get noPlaylistsCurrently;

  /// No description provided for @totalPlaylistsCount.
  ///
  /// In zh_TW, this message translates to:
  /// **'共 {count} 個歌單'**
  String totalPlaylistsCount(String count);

  /// No description provided for @songsCountAndDuration.
  ///
  /// In zh_TW, this message translates to:
  /// **'{songCount} 首歌曲 • {durationMinutes} 分鐘'**
  String songsCountAndDuration(String songCount, String durationMinutes);

  /// No description provided for @songListComingSoon.
  ///
  /// In zh_TW, this message translates to:
  /// **'歌曲清單即將推出'**
  String get songListComingSoon;

  /// No description provided for @navPlaylists.
  ///
  /// In zh_TW, this message translates to:
  /// **'播放清單'**
  String get navPlaylists;

  /// No description provided for @playbackSettings.
  ///
  /// In zh_TW, this message translates to:
  /// **'播放'**
  String get playbackSettings;

  /// No description provided for @replayGainTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'開啟音量平衡 (ReplayGain)'**
  String get replayGainTitle;

  /// No description provided for @replayGainSubtitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'自動平衡不同年代歌曲的音量大小，避免忽大忽小'**
  String get replayGainSubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'CN':
            return AppLocalizationsZhCn();
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
