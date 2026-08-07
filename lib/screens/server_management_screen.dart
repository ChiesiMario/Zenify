import 'package:zenify/l10n/app_localizations.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/components/zenify_input.dart';
import 'package:zenify/models/server.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/api/subsonic_api.dart';
import 'package:zenify/components/zenify_toast.dart';
import 'package:zenify/components/zenify_button.dart';
import 'package:zenify/providers/audio_provider.dart';
import 'package:zenify/services/image_service.dart';

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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final hasActive = ref.read(activeServerProvider).value != null;
        if (!hasActive) {
          ZenifyToast.showError(context, '請選擇一個伺服器以繼續');
          return;
        }
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          context.go('/settings');
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.background,
        body: serversAsync.when(
        data: (servers) {
          return ListView(
            padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.1, bottom: 128),
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/icon/app_icon.png',
                      width: 80,
                      height: 80,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Zenify',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.foreground,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.welcomeSubtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
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
                                  if (Navigator.of(context).canPop()) {
                                    Navigator.of(context).pop();
                                  } else {
                                    context.go('/albums');
                                  }
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
                        }),

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
    ));
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
          ZenifyButton(
            text: l10n.cancel,
            variant: ZenifyButtonVariant.ghost,
            onPressed: () => Navigator.pop(context),
          ),
          ZenifyButton(
            text: l10n.confirmDelete,
            variant: ZenifyButtonVariant.destructive,
            onPressed: () async {
              if (server.isActive) {
                ref.read(audioProvider.notifier).stop();
              }
              await ImageService().deleteServerCache(server.id);
              await ref.read(databaseProvider).deleteServer(server.id);
              
              ref.invalidate(serversListProvider);
              if (server.isActive) {
                ref.invalidate(activeServerProvider);
              }
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
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
  late final FocusNode _urlFocusNode;

  bool _isConfirmingDelete = false;
  Timer? _deleteTimer;
  bool _isCheckingConnection = false;
  bool _isConnectionValid = false;
  String? _connectionError;
  bool _urlHasError = false;

  bool get _isEditing => widget.server != null;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.server?.url ?? '');
    _usernameController = TextEditingController(text: widget.server?.username ?? '');
    _passwordController = TextEditingController(text: widget.server?.password ?? '');

    _urlFocusNode = FocusNode();
    _urlFocusNode.addListener(_onUrlFocusChange);

    _isConnectionValid = _isEditing; // Assume valid if editing, unless changed
  }

  @override
  void dispose() {
    _deleteTimer?.cancel();
    _urlFocusNode.removeListener(_onUrlFocusChange);
    _urlFocusNode.dispose();
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onUrlFocusChange() {
    if (!_urlFocusNode.hasFocus) {
      final url = _urlController.text.trim();
      if (url.isEmpty) {
        if (_urlHasError) {
          setState(() {
            _urlHasError = false;
          });
        }
        return;
      }
      final uri = Uri.tryParse(url);
      final isInvalid = uri == null || (!uri.isScheme('http') && !uri.isScheme('https')) || uri.host.isEmpty;
      if (_urlHasError != isInvalid) {
        setState(() {
          _urlHasError = isInvalid;
        });
      }
    }
  }

  void _onInputChanged(String _) {
    setState(() {
      _isConnectionValid = false;
      _connectionError = null;
      _urlHasError = false;
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

    final uri = Uri.tryParse(url);
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https')) || uri.host.isEmpty) {
      setState(() {
        _urlHasError = true;
      });
      ZenifyToast.showError(context, '無效的 URL 格式 (需包含 http:// 或 https://)');
      return;
    }

    setState(() {
      _isCheckingConnection = true;
      _connectionError = null;
      _urlHasError = false;
    });

    final startTime = DateTime.now();

    try {
      final tempServer = Server()
        ..url = url
        ..username = username
        ..password = password;
      final api = SubsonicApi(tempServer);
      final isValid = await api.ping();

      final elapsed = DateTime.now().difference(startTime);
      if (elapsed.inMilliseconds < 1000) {
        await Future.delayed(Duration(milliseconds: 1000 - elapsed.inMilliseconds));
      }

      if (!mounted) return;

      setState(() {
        _isCheckingConnection = false;
        if (isValid) {
          _isConnectionValid = true;
          ZenifyToast.show(context: context, message: '連線成功');
        } else {
          _connectionError = l10n.serverConnectionOrAuthFailed;
          _isConnectionValid = false;
          ZenifyToast.show(context: context, message: _connectionError!);
        }
      });
    } catch (e) {
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed.inMilliseconds < 1000) {
        await Future.delayed(Duration(milliseconds: 1000 - elapsed.inMilliseconds));
      }

      if (!mounted) return;
      setState(() {
        _isCheckingConnection = false;
        _connectionError = l10n.connectionError;
        _isConnectionValid = false;
        ZenifyToast.show(context: context, message: _connectionError!);
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
    
    final urlText = _urlController.text.trim();
    final uri = Uri.tryParse(urlText);
    final isUrlFormatValid = uri != null && (uri.isScheme('http') || uri.isScheme('https')) && uri.host.isNotEmpty;

    final isInputEmpty = urlText.isEmpty || 
                         _usernameController.text.trim().isEmpty || 
                         _passwordController.text.isEmpty;
                         
    final canSubmit = !isInputEmpty && isUrlFormatValid;

    return AlertDialog(
      backgroundColor: colorScheme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.all(24).copyWith(bottom: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      actionsPadding: const EdgeInsets.all(24).copyWith(top: 16),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_isEditing ? l10n.editServer : l10n.addServer, style: TextStyle(color: colorScheme.foreground, fontWeight: FontWeight.bold)),
          if (_isEditing)
            SizedBox(
              height: 40,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: _isConfirmingDelete
                    ? ZenifyButton(
                        key: const ValueKey('confirm_delete'),
                        variant: ZenifyButtonVariant.destructive,
                        text: l10n.confirm,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        onPressed: () async {
                          _deleteTimer?.cancel();
                          if (widget.server!.isActive) {
                            ref.read(audioProvider.notifier).stop();
                          }
                          await ImageService().deleteServerCache(widget.server!.id);
                          await ref.read(databaseProvider).deleteServer(widget.server!.id);
                          
                          ref.invalidate(serversListProvider);
                          if (widget.server!.isActive) {
                            ref.invalidate(activeServerProvider);
                          }
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                      )
                    : IconButton(
                        key: const ValueKey('delete_icon'),
                        icon: Icon(LucideIcons.trash2, size: 18),
                        color: colorScheme.mutedForeground,
                        hoverColor: colorScheme.destructive.withValues(alpha: 0.1),
                        splashRadius: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            _isConfirmingDelete = true;
                          });
                          _deleteTimer?.cancel();
                          _deleteTimer = Timer(const Duration(seconds: 5), () {
                            if (mounted) {
                              setState(() {
                                _isConfirmingDelete = false;
                              });
                            }
                          });
                        },
                      ),
              ),
            ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.enterServerInfo, style: TextStyle(color: colorScheme.mutedForeground)),
          const SizedBox(height: 20),
          ZenifyInput(
            controller: _urlController,
            focusNode: _urlFocusNode,
            placeholder: Text(l10n.serverUrlExample),
            autofocus: true,
            hasError: _urlHasError,
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
        ],
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ZenifyButton(
              variant: ZenifyButtonVariant.ghost,
              text: l10n.cancel,
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 8),
            ZenifyButton(
              key: const ValueKey('action_btn'),
              width: 100,
              text: _isCheckingConnection
                  ? ''
                  : (_isConnectionValid ? l10n.save : l10n.checkServer),
              isLoading: _isCheckingConnection,
              onPressed: canSubmit
                  ? (_isConnectionValid ? _saveServer : _checkConnection)
                  : null,
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
