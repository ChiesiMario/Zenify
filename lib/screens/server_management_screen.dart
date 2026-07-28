import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/components/zenify_input.dart';
import 'package:zenify/models/server.dart';
import 'package:zenify/providers/app_providers.dart';

class ServerManagementScreen extends ConsumerStatefulWidget {
  const ServerManagementScreen({super.key});

  @override
  ConsumerState<ServerManagementScreen> createState() => _ServerManagementScreenState();
}

class _ServerManagementScreenState extends ConsumerState<ServerManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final serversAsync = ref.watch(serversListProvider);
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: serversAsync.when(
        data: (servers) {
          return ListView(
            padding: const EdgeInsets.only(top: 24, bottom: 128),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '已儲存的伺服器',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.mutedForeground,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        ...servers.map((server) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _ServerSettingTile(
                              server: server,
                              isActive: server.isActive,
                              onTap: () async {
                                await ref.read(databaseProvider).setActiveServer(server.id);
                                ref.invalidate(serversListProvider);
                                ref.invalidate(activeServerProvider);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                              onEdit: () {
                                _showServerDialog(context, ref, server: server);
                              },
                              onLongPress: () {
                                _showDeleteConfirmationDialog(context, server, colorScheme);
                              },
                            ),
                          );
                        }).toList(),

                        _buildAddServerTile(context, colorScheme),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: colorScheme.foreground)),
        error: (err, stack) => Center(child: Text('載入失敗: $err', style: TextStyle(color: colorScheme.destructive))),
      ),
    );
  }

  Widget _buildAddServerTile(BuildContext context, ShadColorScheme colorScheme) {
    return _AddServerSettingTile(
      onTap: () => _showServerDialog(context, ref),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Server server, ShadColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(LucideIcons.trash2, color: colorScheme.destructive),
            const SizedBox(width: 8),
            Text('刪除伺服器', style: TextStyle(color: colorScheme.foreground, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('確定要刪除這個伺服器嗎？此操作無法還原。', style: TextStyle(color: colorScheme.mutedForeground)),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('取消', style: TextStyle(color: colorScheme.mutedForeground, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(databaseProvider).deleteServer(server.id);
              ref.invalidate(serversListProvider);
              if (server.isActive) {
                ref.invalidate(activeServerProvider);
              }
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.destructive,
              foregroundColor: colorScheme.destructiveForeground,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('確認刪除', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showServerDialog(BuildContext context, WidgetRef ref, {Server? server}) {
    final isEditing = server != null;
    final urlController = TextEditingController(text: server?.url ?? '');
    final usernameController = TextEditingController(text: server?.username ?? '');
    final passwordController = TextEditingController(text: server?.password ?? '');
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colorScheme.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.all(24).copyWith(bottom: 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          actionsPadding: const EdgeInsets.all(24).copyWith(top: 16),
          title: Text(isEditing ? '編輯伺服器' : '新增伺服器', style: TextStyle(color: colorScheme.foreground, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('請輸入 Navidrome / Subsonic 伺服器資訊', style: TextStyle(color: colorScheme.mutedForeground)),
              const SizedBox(height: 20),
              ZenifyInput(
                controller: urlController,
                placeholder: const Text('URL (例如: http://192.168.1.100:4533)'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              ZenifyInput(
                controller: usernameController,
                placeholder: const Text('帳號'),
              ),
              const SizedBox(height: 16),
              ZenifyInput(
                controller: passwordController,
                placeholder: const Text('密碼'),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('取消', style: TextStyle(color: colorScheme.mutedForeground, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () async {
                final url = urlController.text.trim();
                final username = usernameController.text.trim();
                if (url.isEmpty || username.isEmpty) {
                  return;
                }
                
                final serverToSave = server ?? Server();
                serverToSave
                  ..url = url
                  ..username = username
                  ..password = passwordController.text;

                if (!isEditing) {
                  serverToSave.isActive = false;
                }

                final db = ref.read(databaseProvider);
                await db.saveServer(serverToSave);
                
                if (!isEditing) {
                  final allServers = await db.getServers();
                  if (allServers.length == 1) {
                    await db.setActiveServer(allServers.first.id);
                    ref.invalidate(activeServerProvider);
                  }
                } else if (serverToSave.isActive) {
                  // If we edited the active server, we should invalidate the active provider
                  ref.invalidate(activeServerProvider);
                }
                
                ref.invalidate(serversListProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.primaryForeground,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(isEditing ? '儲存變更' : '儲存', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}

class _ServerSettingTile extends StatefulWidget {
  final Server server;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onLongPress;

  const _ServerSettingTile({
    required this.server,
    required this.isActive,
    required this.onTap,
    required this.onEdit,
    required this.onLongPress,
  });

  @override
  State<_ServerSettingTile> createState() => _ServerSettingTileState();
}

class _ServerSettingTileState extends State<_ServerSettingTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final isActive = widget.isActive;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: colorScheme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? colorScheme.foreground.withValues(alpha: 0.4)
                  : colorScheme.border,
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isActive
                      ? colorScheme.primary
                      : (_isHovered
                          ? colorScheme.foreground
                          : colorScheme.muted.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive
                        ? colorScheme.primary
                        : (_isHovered
                            ? colorScheme.foreground
                            : colorScheme.border.withValues(alpha: 0.5)),
                    width: 1,
                  ),
                ),
                child: Icon(
                  LucideIcons.server,
                  size: 19,
                  color: isActive
                      ? colorScheme.primaryForeground
                      : (_isHovered
                          ? colorScheme.background
                          : colorScheme.foreground),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.server.url,
                      style: TextStyle(
                        color: colorScheme.foreground,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.server.username,
                      style: TextStyle(
                        color: colorScheme.mutedForeground,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 4.0),
                  child: Icon(LucideIcons.check, color: colorScheme.primary, size: 20),
                ),
              IconButton(
                icon: Icon(LucideIcons.pencil, size: 16),
                onPressed: widget.onEdit,
                color: colorScheme.mutedForeground,
                hoverColor: colorScheme.foreground.withValues(alpha: 0.1),
                splashRadius: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddServerSettingTile extends StatefulWidget {
  final VoidCallback onTap;

  const _AddServerSettingTile({required this.onTap});

  @override
  State<_AddServerSettingTile> createState() => _AddServerSettingTileState();
}

class _AddServerSettingTileState extends State<_AddServerSettingTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: colorScheme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? colorScheme.foreground.withValues(alpha: 0.4)
                  : colorScheme.border,
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _isHovered
                      ? colorScheme.foreground
                      : colorScheme.muted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isHovered
                        ? colorScheme.foreground
                        : colorScheme.border.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Icon(
                  LucideIcons.plus,
                  size: 19,
                  color: _isHovered
                      ? colorScheme.background
                      : colorScheme.foreground,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '新增伺服器',
                      style: TextStyle(
                        color: colorScheme.foreground,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '新增 Navidrome 或 Subsonic 連線',
                      style: TextStyle(
                        color: colorScheme.mutedForeground,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
