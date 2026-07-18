import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shadcn_ui/shadcn_ui.dart';
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('伺服器管理', style: TextStyle(color: colorScheme.foreground)),
        iconTheme: IconThemeData(color: colorScheme.foreground),
      ),
      body: serversAsync.when(
        data: (servers) {
          if (servers.isEmpty) {
            return Center(
              child: Text('目前沒有伺服器，請點擊右下角新增', style: TextStyle(color: colorScheme.mutedForeground)),
            );
          }
          return ListView.builder(
            itemCount: servers.length,
            itemBuilder: (context, index) {
              final server = servers[index];
              return ListTile(
                leading: Icon(LucideIcons.server, color: server.isActive ? Colors.green : colorScheme.mutedForeground),
                title: Text(server.url, style: TextStyle(color: colorScheme.foreground)),
                subtitle: Text(server.username, style: TextStyle(color: colorScheme.mutedForeground)),
                trailing: server.isActive
                    ? const Icon(LucideIcons.check, color: Colors.green)
                    : null,
                onTap: () async {
                  await ref.read(databaseProvider).setActiveServer(server.id);
                  ref.invalidate(serversListProvider);
                  ref.invalidate(activeServerProvider);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                onLongPress: () async {
                  // Show delete confirmation
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: colorScheme.card,
                      title: Text('刪除伺服器', style: TextStyle(color: colorScheme.foreground)),
                      content: Text('確定要刪除這個伺服器嗎？', style: TextStyle(color: colorScheme.mutedForeground)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('取消', style: TextStyle(color: colorScheme.mutedForeground)),
                        ),
                        TextButton(
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
                          child: Text('刪除', style: TextStyle(color: colorScheme.destructive)),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: colorScheme.foreground)),
        error: (err, stack) => Center(child: Text('載入失敗: $err', style: TextStyle(color: colorScheme.destructive))),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: colorScheme.primary,
        onPressed: () {
          _showAddServerDialog(context, ref);
        },
        child: Icon(LucideIcons.plus, color: colorScheme.primaryForeground),
      ),
    );
  }

  void _showAddServerDialog(BuildContext context, WidgetRef ref) {
    final urlController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colorScheme.card,
          title: Text('新增伺服器', style: TextStyle(color: colorScheme.foreground)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('請輸入 Navidrome / Subsonic 伺服器資訊', style: TextStyle(color: colorScheme.mutedForeground)),
              const SizedBox(height: 16),
              ShadInput(
                controller: urlController,
                placeholder: const Text('URL (例如: http://192.168.1.100:4533)'),
              ),
              const SizedBox(height: 16),
              ShadInput(
                controller: usernameController,
                placeholder: const Text('帳號'),
              ),
              const SizedBox(height: 16),
              ShadInput(
                controller: passwordController,
                placeholder: const Text('密碼'),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消', style: TextStyle(color: colorScheme.mutedForeground)),
            ),
            TextButton(
              onPressed: () async {
                final server = Server()
                  ..url = urlController.text.trim()
                  ..username = usernameController.text.trim()
                  ..password = passwordController.text
                  ..isActive = false; // Will be set to active if it's the first one

                final db = ref.read(databaseProvider);
                await db.saveServer(server);
                
                final allServers = await db.getServers();
                if (allServers.length == 1) {
                  await db.setActiveServer(allServers.first.id);
                  ref.invalidate(activeServerProvider);
                }
                
                ref.invalidate(serversListProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: Text('儲存', style: TextStyle(color: colorScheme.primary)),
            ),
          ],
        );
      },
    );
  }
}
