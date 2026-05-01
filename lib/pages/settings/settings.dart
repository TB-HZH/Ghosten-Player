import 'package:api/api.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:video_player/player.dart';

import '../../components/logo.dart';
import '../../components/scrollbar.dart';
import '../../const.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/user_config.dart';
import '../../utils/utils.dart';
import '../account/account.dart';
import '../library.dart';
import '../player/singleton_player.dart';
import '../utils/utils.dart';
import 'settings_diagnostics.dart';
import 'settings_downloader.dart';
import 'settings_help.dart';
import 'settings_log.dart';
import 'settings_other.dart';
import 'settings_player_history.dart';
import 'settings_server.dart';
import 'settings_sponsor.dart';
import 'settings_updater.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsTitle),
        leading: isMobile(context) ? const Padding(padding: EdgeInsets.all(12), child: Logo()) : null,
      ),
      body: ScrollbarListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          _buildItem(
            AppLocalizations.of(context)!.settingsItemAccount,
            Icons.account_box_outlined,
            onTap: () => navigateTo(context, const AccountManage()),
          ),
          _buildItem(
            AppLocalizations.of(context)!.settingsItemTV,
            Icons.tv,
            onTap: () async {
              if (await verifyPassword(context)) {
                if (context.mounted) {
                  navigateTo(context, const LibraryManage(type: LibraryType.tv));
                }
              }
            },
          ),
          _buildItem(
            AppLocalizations.of(context)!.settingsItemMovie,
            Icons.movie_creation_outlined,
            onTap: () async {
              if (await verifyPassword(context)) {
                if (context.mounted) {
                  navigateTo(context, const LibraryManage(type: LibraryType.movie));
                }
              }
            },
          ),
          const Divider(),
          _buildItem(
            AppLocalizations.of(context)!.buttonPlay,
            Icons.play_arrow_outlined,
            onTap: () async {
              final data = await showDialog<(Uri?, String?)>(
                context: context,
                builder: (context) => const _UrlDialog(),
              );
              if (data != null && context.mounted) {
                navigateTo(
                  context,
                  SingletonPlayer(playlist: [PlaylistItemDisplay(url: data.$1, fileId: data.$2, source: null)]),
                );
              }
            },
          ),
          _buildItem(
            AppLocalizations.of(context)!.settingsItemPlayerHistory,
            Icons.history_rounded,
            onTap: () => navigateTo(context, const SystemSettingsPlayerHistory()),
          ),
          _buildItem(
            AppLocalizations.of(context)!.settingsItemDownload,
            Icons.download_outlined,
            onTap: () => navigateTo(context, const SystemSettingsDownloader()),
          ),
          const Divider(),
          _buildItem(
            AppLocalizations.of(context)!.settingsItemServer,
            Icons.storage_outlined,
            onTap: () => navigateTo(context, const SystemSettingsServer()),
          ),
          _buildItem(
            AppLocalizations.of(context)!.settingsItemNetworkDiagnostics,
            Icons.rule_rounded,
            onTap: () => navigateTo(context, const SettingsDiagnostics()),
          ),
          _buildItem(
            AppLocalizations.of(context)!.settingsItemLog,
            Icons.article_outlined,
            onTap: () => navigateTo(context, const SettingsLogPage()),
          ),
          _buildItem(
            '修改密码',
            Icons.password_outlined,
            onTap: () async {
              if (await verifyPassword(context)) {
                while (true) {
                  if (!context.mounted) return;
                  final newPwd = await inputPassword(context, title: '请输入新密码');
                  if (newPwd != null && newPwd.isNotEmpty) {
                    if (!context.mounted) return;
                    final confirmPwd = await inputPassword(context, title: '请再次输入新密码');
                    if (confirmPwd == newPwd) {
                      if (context.mounted) {
                        context.read<UserConfig>().setPassword(newPwd);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('密码修改成功')));
                      }
                      break;
                    } else {
                      if (context.mounted) {
                        final retry = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('提示'),
                            content: const Text('两次输入的密码不一致！'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('确认'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('重试'),
                              ),
                            ],
                          ),
                        );
                        if (retry != true) break;
                      } else {
                        break;
                      }
                    }
                  } else {
                    break;
                  }
                }
              }
            },
          ),
          _buildItem(
            AppLocalizations.of(context)!.settingsItemOthers,
            Icons.more_horiz_rounded,
            onTap: () => navigateTo(context, const SystemSettingsOther()),
          ),
          const Divider(),
          _buildItem(
            AppLocalizations.of(context)!.settingsItemHelp,
            Icons.help_outline_rounded,
            onTap: () => navigateTo(context, const SettingsHelp()),
          ),
          _buildItem(
            AppLocalizations.of(context)!.settingsItemFeedback,
            Icons.feedback_outlined,
            onTap: () {
              launchUrlString(
                'https://github.com/$repoAuthor/$repoName/issues',
                browserConfiguration: const BrowserConfiguration(showTitle: true),
              );
            },
          ),
          _buildItem(
            AppLocalizations.of(context)!.settingsItemSponsor,
            Icons.card_giftcard_rounded,
            onTap: () => navigateTo(context, const SettingsSponsor()),
          ),
          _buildItem(
            AppLocalizations.of(context)!.settingsItemInfo,
            Icons.info_outline,
            onTap: () => navigateTo(context, const SystemSettingsUpdater()),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(String title, IconData icon, {Widget? trailing, GestureTapCallback? onTap}) {
    return ListTile(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Expanded(child: Text(title)), if (trailing != null) trailing],
      ),
      leading: Icon(icon),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _UrlDialog extends StatefulWidget {
  const _UrlDialog();

  @override
  State<_UrlDialog> createState() => __UrlDialogState();
}

class __UrlDialogState extends State<_UrlDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController();
  String? fileId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.buttonPlay),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: TextFormField(
            autofocus: true,
            controller: _controller,
            decoration: InputDecoration(
              isDense: true,
              border: const UnderlineInputBorder(),
              labelText: 'Link',
              prefixIcon: const Icon(Icons.link),
              suffixIcon: IconButton(
                icon: const Icon(Icons.folder_open_rounded),
                onPressed: () async {
                  final res = await showDriverFilePicker(context, '', selectableType: FileType.file);
                  if (res != null) {
                    final file = res.$2;
                    _controller.text = file.fileId ?? '';
                    fileId = file.fileId;
                    setState(() {});
                  }
                },
              ),
            ),
            validator: (value) {
              if (_controller.text.trim().isEmpty) {
                return AppLocalizations.of(context)!.formValidatorRequired;
              }
              if (fileId != null) {
                return null;
              }
              final uri = Uri.tryParse(_controller.text);
              if (uri == null || !uri.hasScheme) {
                return AppLocalizations.of(context)!.formValidatorUrl;
              }
              return null;
            },
            onChanged: (_) {
              fileId = null;
            },
          ),
        ),
      ),
      actions: [IconButton(icon: const Icon(Icons.check), onPressed: () => _onSubmit(context))],
    );
  }

  Future<void> _onSubmit(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, (Uri.tryParse(_controller.text), fileId));
    }
  }
}
