import 'package:zenify/l10n/app_localizations.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/components/zenify_input.dart';
import 'package:zenify/models/server.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/api/subsonic_api.dart';
import 'package:zenify/components/zenify_toast.dart';

class ServerManagementScreen extends ConsumerStatefulWidget {
  const ServerManagementScreen({super.key});

  @override
  ConsumerState<ServerManagementScreen> createState() => _ServerManagementScreenState();
}

class _ServerManagementScreenState extends ConsumerState<ServerManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                          l10n.savedServers,
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
        error: (err, stack) => Center(child: Text(l10n.loadFailedErr(err.toString()), style: TextStyle(color: colorScheme.destructive))),
      ),
    );
  }

  Widget _buildAddServerTile(BuildContext context, ShadColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context)!;
    return _AddServerSettingTile(
      onTap: () => _showServerDialog(context, ref),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Server server, ShadColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(LucideIcons.trash2, color: colorScheme.destructive),
            const SizedBox(width: 8),
            Text(l10n.deleteServer, style: TextStyle(color: colorScheme.foreground, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(l10n.confirmDeleteServer, style: TextStyle(color: colorScheme.mutedForeground)),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(l10n.cancel, style: TextStyle(color: colorScheme.mutedForeground, fontWeight: FontWeight.w600)),
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
            child: Text(l10n.confirmDelete, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showServerDialog(BuildContext context, WidgetRef ref, {Server? server}) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => _ServerEditDialog(server: server),
    );
  }
}

class _ServerEditDialog extends ConsumerStatefulWidget {
  final Server? server;

  const _ServerEditDialog({this.server});

  @override
  ConsumerState<_ServerEditDialog> createState() => _ServerEditDialogState();
}

class _ServerEditDialogState extends ConsumerState<_ServerEditDialog> {
  late final TextEditingController _urlController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;

  bool _isConfirmingDelete = false;
  bool _isCheckingConnection = false;
  bool _isConnectionValid = false;
  String? _connectionError;

  bool get _isEditing => widget.server != null;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.server?.url ?? '');
    _usernameController = TextEditingController(text: widget.server?.username ?? '');
    _passwordController = TextEditingController(text: widget.server?.password ?? '');

    _isConnectionValid = _isEditing; // Assume valid if editing, unless changed
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onInputChanged(String _) {
    setState(() {
      _isConnectionValid = false;
      _connectionError = null;
    });
  }

  Future<void> _checkConnection() async {
    final url = _urlController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (url.isEmpty || username.isEmpty || password.isEmpty) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isCheckingConnection = true;
      _connectionError = null;
    });

    try {
      final tempServer = Server()
        ..url = url
        ..username = username
        ..password = password;
      final api = SubsonicApi(tempServer);
      final isValid = await api.ping();

      if (!mounted) return;

      setState(() {
        _isCheckingConnection = false;
        if (isValid) {
          _isConnectionValid = true;
        } else {
          _connectionError = l10n.serverConnectionOrAuthFailed;
          _isConnectionValid = false;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCheckingConnection = false;
        _connectionError = l10n.connectionError;
        _isConnectionValid = false;
      });
    }
  }

  Future<void> _saveServer() async {
    if (_isCheckingConnection || !_isConnectionValid) return;

    final url = _urlController.text.trim();
    final username = _usernameController.text.trim();
    
    final serverToSave = widget.server ?? Server();
    serverToSave
      ..url = url
      ..username = username
      ..password = _passwordController.text;

    if (!_isEditing) {
      serverToSave.isActive = false;
    }

    final db = ref.read(databaseProvider);
    await db.saveServer(serverToSave);
    
    if (!_isEditing) {
      final allServers = await db.getServers();
      if (allServers.length == 1) {
        await db.setActiveServer(allServers.first.id);
        ref.invalidate(activeServerProvider);
      }
    } else if (serverToSave.isActive) {
      ref.invalidate(activeServerProvider);
    }
    
    ref.invalidate(serversListProvider);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    
    final isInputEmpty = _urlController.text.trim().isEmpty || 
                         _usernameController.text.trim().isEmpty || 
                         _passwordController.text.isEmpty;

    return AlertDialog(
      backgroundColor: colorScheme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.all(24).copyWith(bottom: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      actionsPadding: const EdgeInsets.all(24).copyWith(top: 16),
      title: Text(_isEditing ? l10n.editServer : l10n.addServer, style: TextStyle(color: colorScheme.foreground, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.enterServerInfo, style: TextStyle(color: colorScheme.mutedForeground)),
          const SizedBox(height: 20),
          ZenifyInput(
            controller: _urlController,
            placeholder: Text(l10n.serverUrlExample),
            autofocus: true,
            onChanged: _onInputChanged,
          ),
          const SizedBox(height: 16),
          ZenifyInput(
            controller: _usernameController,
            placeholder: Text(l10n.username),
            onChanged: _onInputChanged,
          ),
          const SizedBox(height: 16),
          ZenifyInput(
            controller: _passwordController,
            placeholder: Text(l10n.password),
            obscureText: true,
            onChanged: _onInputChanged,
          ),
          if (_connectionError != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                _connectionError!, 
                style: TextStyle(color: colorScheme.destructive, fontSize: 13)
              ),
            ),
        ],
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_isEditing)
              ShadButton.outline(
                onPressed: () async {
                  if (_isConfirmingDelete) {
                    await ref.read(databaseProvider).deleteServer(widget.server!.id);
                    ref.invalidate(serversListProvider);
                    if (widget.server!.isActive) {
                      ref.invalidate(activeServerProvider);
                    }
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  } else {
                    setState(() {
                      _isConfirmingDelete = true;
                    });
                  }
                },
                child: Text(
                  _isConfirmingDelete ? l10n.confirmDelete : l10n.delete,
                  style: _isConfirmingDelete ? TextStyle(color: colorScheme.destructive) : null,
                ),
              )
            else
              const SizedBox.shrink(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShadButton.outline(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                ShadButton(
                  onPressed: _isCheckingConnection || isInputEmpty
                      ? null
                      : _isConnectionValid
                          ? _saveServer
                          : _checkConnection,
                  child: _isCheckingConnection 
                      ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primaryForeground))
                      : Text(_isConnectionValid ? (_isEditing ? l10n.saveChanges : l10n.save) : l10n.checkServer),
                ),
              ],
            ),
          ],
        ),
      ],
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
  bool _isChecking = false;

  Future<void> _handleTap() async {
    if (_isChecking) return;
    
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isChecking = true;
    });

    try {
      final api = SubsonicApi(widget.server);
      final isAvailable = await api.ping();

      if (!mounted) return;

      if (isAvailable) {
        widget.onTap();
      } else {
        ZenifyToast.showError(context, l10n.cannotConnectCheckSettings);
      }
    } catch (e) {
      if (mounted) {
        ZenifyToast.showError(context, l10n.serverConnectionError);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final isActive = widget.isActive;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: _handleTap,
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
                child: _isChecking
                    ? Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isActive
                              ? colorScheme.primaryForeground
                              : colorScheme.foreground,
                        ),
                      )
                    : Icon(
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
    final l10n = AppLocalizations.of(context)!;
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
                      l10n.addServer,
                      style: TextStyle(
                        color: colorScheme.foreground,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.addNavidromeOrSubsonic,
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
