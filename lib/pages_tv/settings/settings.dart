import 'package:api/api.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../const.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/user_config.dart';
import '../../utils/utils.dart';
import '../components/filled_button.dart';
import '../components/setting.dart';
import '../components/text_button.dart';
import '../components/text_field_focus.dart';
import '../utils/utils.dart';
import 'settings_about.dart';
import 'settings_account.dart';
import 'settings_diagnostics.dart';
import 'settings_downloader.dart';
import 'settings_help.dart';
import 'settings_library.dart';
import 'settings_log.dart';
import 'settings_other.dart';
import 'settings_player_history.dart';
import 'settings_server.dart';
import 'settings_sponsor.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingPage(
      title: AppLocalizations.of(context)!.settingsTitle,
      child: ListView(
        padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 32),
        children: [
          ButtonSettingItem(
            title: Text(AppLocalizations.of(context)!.settingsItemAccount),
            leading: const Icon(Icons.account_box_outlined),
            autofocus: true,
            onTap: () => navigateToSlideLeft(context, const SettingsAccountPage()),
          ),
          ButtonSettingItem(
            title: Text(AppLocalizations.of(context)!.settingsItemTV),
            leading: const Icon(Icons.tv),
            onTap: () async {
              if (await verifyPassword(context)) {
                if (context.mounted) {
                  navigateToSlideLeft(
                    context,
                    LibraryManage(title: AppLocalizations.of(context)!.settingsItemTV, type: LibraryType.tv),
                  );
                }
              }
            },
          ),
          ButtonSettingItem(
            title: Text(AppLocalizations.of(context)!.settingsItemMovie),
            leading: const Icon(Icons.movie_creation_outlined),
            onTap: () async {
              if (await verifyPassword(context)) {
                if (context.mounted) {
                  navigateToSlideLeft(
                    context,
                    LibraryManage(title: AppLocalizations.of(context)!.settingsItemMovie, type: LibraryType.movie),
                  );
                }
              }
            },
          ),
          const DividerSettingItem(),
          ButtonSettingItem(
            title: Text(AppLocalizations.of(context)!.settingsItemPlayerHistory),
            leading: const Icon(Icons.history_rounded),
            onTap: () => navigateToSlideLeft(context, const SystemSettingsPlayerHistory()),
          ),
          ButtonSettingItem(
            title: Text(AppLocalizations.of(context)!.settingsItemDownload),
            leading: const Icon(Icons.download_outlined),
            onTap: () => navigateToSlideLeft(context, const SystemSettingsDownloader()),
          ),
          const DividerSettingItem(),
          ButtonSettingItem(
            title: Text(AppLocalizations.of(context)!.settingsItemServer),
            leading: const Icon(Icons.public_rounded),
            onTap: () => navigateToSlideLeft(context, const SystemSettingsServer()),
          ),
          ButtonSettingItem(
            title: Text(AppLocalizations.of(context)!.settingsItemNetworkDiagnostics),
            leading: const Icon(Icons.rule_rounded),
            onTap: () => navigateToSlideLeft(context, const SettingsDiagnostics()),
          ),
          ButtonSettingItem(
            title: Text(AppLocalizations.of(context)!.settingsItemLog),
            leading: const Icon(Icons.article_outlined),
            onTap: () => navigateToSlideLeft(context, const SettingsLogPage()),
          ),
          ButtonSettingItem(
            title: const Text('修改密码'),
            leading: const Icon(Icons.password_outlined),
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
                              TVTextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('确认'),
                              ),
                              TVFilledButton(
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
          ButtonSettingItem(
            title: Text(AppLocalizations.of(context)!.settingsItemOthers),
            leading: const Icon(Icons.more_horiz_rounded),
            onTap: () => navigateToSlideLeft(context, const SystemSettingsOther()),
          ),
          const DividerSettingItem(),
          ButtonSettingItem(
            title: Text(AppLocalizations.of(context)!.settingsItemHelp),
            leading: const Icon(Icons.help_outline_rounded),
            onTap: () => navigateToSlideLeft(context, const SettingsHelp()),
          ),
          ButtonSettingItem(
            title: Text(AppLocalizations.of(context)!.settingsItemFeedback),
            leading: const Icon(Icons.feedback_outlined),
            onTap:
                () => launchUrlString(
                  'https://github.com/$repoAuthor/$repoName/issues',
                  browserConfiguration: const BrowserConfiguration(showTitle: true),
                ),
          ),
          ButtonSettingItem(
            title: Text(AppLocalizations.of(context)!.settingsItemSponsor),
            leading: const Icon(Icons.card_giftcard_rounded),
            onTap: () => navigateTo(navigatorKey.currentContext!, const SettingsSponsor()),
          ),
          ButtonSettingItem(
            title: Text(AppLocalizations.of(context)!.settingsItemInfo),
            leading: const Icon(Icons.info_outline),
            onTap: () => navigateToSlideLeft(context, const SettingsAboutPage()),
          ),
        ],
      ),
    );
  }
}

