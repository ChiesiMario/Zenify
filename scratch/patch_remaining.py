import os
import re

files_to_update = {
    'lib/components/albums_grid.dart': {
        r"'未知專輯'": "l10n.unknownAlbum",
        r"'未知藝術家'": "l10n.unknownArtist",
    },
    'lib/components/artists_grid.dart': {
        r"'未知藝術家'": "l10n.unknownArtist",
    },
    'lib/components/play_queue_sheet.dart': {
        r"'未知歌曲'": "l10n.unknownSong",
        r"'未知藝術家'": "l10n.unknownArtist",
    },
    'lib/screens/album_detail_screen.dart': {
        r"'服務器已離線'": "l10n.serverOffline",
        r"'未知專輯'": "l10n.unknownAlbum",
        r"'未知藝術家'": "l10n.unknownArtist",
        r"'未知歌曲'": "l10n.unknownSong",
        r"'加入最愛'": "l10n.addToFavorites",
        r"'取消最愛'": "l10n.removeFromFavorites",
        r"'播放'": "l10n.playerPlay",
        r"'隨機播放'": "l10n.playerShuffle",
    },
    'lib/screens/artist_detail_screen.dart': {
        r"'服務器已離線'": "l10n.serverOffline",
        r"'未知歌曲'": "l10n.unknownSong",
        r"'加入最愛'": "l10n.addToFavorites",
        r"'取消最愛'": "l10n.removeFromFavorites",
        r"Text\('播放'": "Text(l10n.playerPlay",
        r"Text\('隨機播放'\)": "Text(l10n.playerShuffle)",
    },
    'lib/screens/favorite_songs_screen.dart': {
        r"'服務器已離線'": "l10n.serverOffline",
        r"'未知歌曲'": "l10n.unknownSong",
        r"'未知藝術家'": "l10n.unknownArtist",
        r"'加入最愛'": "l10n.addToFavorites",
        r"'取消最愛'": "l10n.removeFromFavorites",
    },
    'lib/screens/home_screen.dart': {
        r"== '專輯'": "== AppLocalizations.of(context)!.navAlbums",
        r"== '播放清單'": "== AppLocalizations.of(context)!.navPlaylists",
        r"name: '搜尋'": "name: AppLocalizations.of(context)!.navSearch",
        r"subTitle == '專輯'": "subTitle == AppLocalizations.of(context)!.navAlbums",
        r"'服務器已離線'": "AppLocalizations.of(context)!.serverOffline",
    },
    'lib/views/downloads_view.dart': {
        r"Text\('專輯'\)": "Text(l10n.navAlbums)",
        r"'未知專輯'": "l10n.unknownAlbum",
    },
    'lib/views/favorites_view.dart': {
        r"title: '專輯'": "title: l10n.navAlbums",
        r"name: '專輯'": "name: l10n.navAlbums",
        r"title: '播放清單'": "title: l10n.navPlaylists",
        r"name: '播放清單'": "name: l10n.navPlaylists",
    },
    'lib/views/playlists_view.dart': {
        r"'播放清單'": "l10n.navPlaylists",
    },
    'lib/components/album_card.dart': {
        r"'服務器已離線'": "l10n.serverOffline",
    },
    'lib/components/artist_card.dart': {
        r"'服務器已離線'": "l10n.serverOffline",
    }
}

for filepath, replacements in files_to_update.items():
    if not os.path.exists(filepath):
        continue
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    for pattern, replacement in replacements.items():
        content = re.sub(pattern, replacement, content)
        
    if content != original_content:
        # Add l10n definition if needed
        if 'l10n.' in content and 'final l10n = ' not in content:
            # simple inject after build(BuildContext context)
            content = re.sub(r'build\(BuildContext context.*?\)\s*{', r'build(BuildContext context) {\n    final l10n = AppLocalizations.of(context)!;', content)
            
            # import if needed
            if 'AppLocalizations' not in content:
                content = "import 'package:zenify/l10n/app_localizations.dart';\n" + content
                
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")
