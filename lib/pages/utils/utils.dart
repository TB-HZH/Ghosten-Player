import 'dart:async';
import 'dart:io';

import 'package:api/api.dart' hide PageData;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../components/async_image.dart';
import '../../components/error_message.dart';
import '../../components/focus_card.dart';
import '../../components/future_builder_handler.dart';
import '../../components/gap.dart';
import '../../components/no_data.dart';
import '../../l10n/app_localizations.dart';
import '../../platform_api.dart';
import '../../providers/user_config.dart';
import '../../utils/utils.dart';
import '../account/account_login.dart';

const _lightSystemUiOverlayStyle = SystemUiOverlayStyle(
  systemNavigationBarIconBrightness: Brightness.dark,
  // 设置为全透明时，在某些设备上NavigationBar并不会完全透明
  systemNavigationBarColor: Color(0x01FFFFFF),
  statusBarIconBrightness: Brightness.dark,
  statusBarColor: Colors.transparent,
);

const _darkSystemUiOverlayStyle = SystemUiOverlayStyle(
  systemNavigationBarIconBrightness: Brightness.light,
  // 设置为全透明时，在某些设备上NavigationBar并不会完全透明
  systemNavigationBarColor: Color(0x01000000),
  statusBarIconBrightness: Brightness.light,
  statusBarColor: Colors.transparent,
);

SystemUiOverlayStyle? getSystemUiOverlayStyle(BuildContext context, [ThemeMode mode = ThemeMode.system]) {
  switch (mode) {
    case ThemeMode.system:
      return switch (context.watch<UserConfig>().themeMode) {
        ThemeMode.light => _lightSystemUiOverlayStyle,
        ThemeMode.dark => _darkSystemUiOverlayStyle,
        ThemeMode.system => switch (MediaQuery.platformBrightnessOf(context)) {
          Brightness.light => _lightSystemUiOverlayStyle,
          Brightness.dark => _darkSystemUiOverlayStyle,
        },
      };
    case ThemeMode.light:
      return _lightSystemUiOverlayStyle;
    case ThemeMode.dark:
      return _darkSystemUiOverlayStyle;
  }
}

bool isMobile(BuildContext context) {
  return MediaQuery.of(context).size.aspectRatio < 1;
}

Future<bool> verifyPassword(BuildContext context) async {
  final userConfig = Provider.of<UserConfig>(context, listen: false);
  while (true) {
    final password = await showDialog<String>(
      context: context,
      builder: (context) => const _PasswordDialog(title: '请输入密码'),
    );
    if (password == null) return false;
    if (password == userConfig.password) return true;
    if (context.mounted) {
      final retry = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('提示'),
          content: const Text('密码错误！'),
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
      if (retry != true) return false;
    } else {
      return false;
    }
  }
}

Future<String?> inputPassword(BuildContext context, {String title = '请输入密码'}) async {
  return showDialog<String>(
    context: context,
    builder: (context) => _PasswordDialog(title: title),
  );
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.title});
  final String title;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onKeyPress(String key) {
    if (key == 'DEL') {
      if (_controller.text.isNotEmpty) {
        _controller.text = _controller.text.substring(0, _controller.text.length - 1);
      }
    } else if (key == 'ENTER') {
      Navigator.pop(context, _controller.text);
    } else {
      _controller.text += key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool useKeypad = Platform.isAndroid; // Android

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              obscureText: true,
              autofocus: !useKeypad,
              readOnly: useKeypad,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onSubmitted: (value) => Navigator.pop(context, value),
            ),
            if (useKeypad) ...[
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.5,
                children: [
                  for (var i = 1; i <= 9; i++)
                    _KeypadBtn(
                      label: i.toString(),
                      onPressed: () => _onKeyPress(i.toString()),
                    ),
                  _KeypadBtn(
                    label: 'DEL',
                    icon: Icons.backspace_outlined,
                    onPressed: () => _onKeyPress('DEL'),
                  ),
                  _KeypadBtn(
                    label: '0',
                    onPressed: () => _onKeyPress('0'),
                  ),
                  _KeypadBtn(
                    label: 'ENTER',
                    icon: Icons.keyboard_return,
                    onPressed: () => _onKeyPress('ENTER'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!useKeypad) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _controller.text),
            child: const Text('确认'),
          ),
        ] else
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
      ],
    );
  }
}

class _KeypadBtn extends StatefulWidget {
  const _KeypadBtn({required this.label, this.icon, required this.onPressed});
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  @override
  State<_KeypadBtn> createState() => _KeypadBtnState();
}

class _KeypadBtnState extends State<_KeypadBtn> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: _focused ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: TextStyle(
        color: _focused ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      child: InkWell(
        onFocusChange: (f) => setState(() => _focused = f),
        onTap: widget.onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Center(
          child: widget.icon != null
              ? Icon(
                  widget.icon,
                  color: _focused ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                )
              : Text(widget.label),
        ),
      ),
    );
  }
}

Future<void> setPreferredOrientations(bool fullscreen) {
  if (PlatformApi.isAndroidPhone()) {
    if (fullscreen) {
      return SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      return SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  } else {
    return Future.value();
  }
}

Future<T?> navigateToSlideUp<T extends Object?>(BuildContext context, Widget page) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOut;
        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    ),
  );
}

Future<(int, DriverFile)?> showDriverFilePicker(
  BuildContext context,
  String title, {
  FileType? fileType,
  FileType? selectableType,
}) {
  Future<void> openFilePicker(String defaultPath) async {
    final file = await _showFilePicker(
      context,
      title: title,
      type: FilePickerType.local,
      driverId: 0,
      defaultPath: defaultPath,
      fileType: fileType,
      selectableType: selectableType,
    );
    if (file != null) {
      if (context.mounted) Navigator.of(context).pop((0, file));
    }
  }

  return showModalBottomSheet<(int, DriverFile)>(
    context: context,
    elevation: 0,
    constraints: const BoxConstraints(minWidth: double.infinity),
    builder:
        (context) => SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16, left: 32, right: 32),
                child: Text(
                  AppLocalizations.of(context)!.titleSelectAnAccount,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              SizedBox(
                height: 250,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return Scrollbar(
                      child: CustomScrollView(
                        scrollDirection: Axis.horizontal,
                        slivers: [
                          FutureBuilderSliverHandler(
                            future: Api.driverQueryAll(),
                            builder:
                                (context, snapshot) => SliverPadding(
                                  padding:
                                      snapshot.requireData.isNotEmpty
                                          ? const EdgeInsets.only(left: 32, right: 32, bottom: 12)
                                          : const EdgeInsets.only(left: 12),
                                  sliver: SliverList.builder(
                                    itemCount: snapshot.requireData.length,
                                    itemBuilder: (context, index) {
                                      final item = snapshot.requireData[index];
                                      return _buildAccountCard(context, item, () async {
                                        final file = await _showFilePicker(
                                          context,
                                          title: title,
                                          type: FilePickerType.remote,
                                          driverId: item.id,
                                          defaultPath: '/',
                                          fileType: fileType,
                                          selectableType: selectableType,
                                        );
                                        if (file != null) {
                                          if (context.mounted) Navigator.of(context).pop((item.id, file));
                                        }
                                      });
                                    },
                                  ),
                                ),
                          ),
                          FutureBuilderSliverHandler(
                            future: FilePicker.externalUsbStorages(),
                            builder: (context, snapshot) {
                              return SliverList.builder(
                                itemCount: snapshot.requireData!.length,
                                itemBuilder: (context, index) {
                                  final item = snapshot.requireData![index];
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        spacing: 4,
                                        children: [
                                          const Text(''),
                                          IconButton.filledTonal(
                                            onPressed: () async {
                                              await FilePicker.requestStorageManagePermission();
                                              if (!context.mounted) return;
                                              openFilePicker(item.path);
                                            },
                                            icon: Icon(_guessStorageTypeByDesc(item.desc)),
                                          ),
                                          Text(item.desc, style: Theme.of(context).textTheme.labelMedium),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: IconButton.filledTonal(
                                  onPressed: () async {
                                    final defaultPath = await FilePicker.externalStoragePath ?? '/';
                                    await FilePicker.requestStoragePermission();
                                    if (!context.mounted) return;
                                    openFilePicker(defaultPath);
                                  },
                                  icon: const Icon(Icons.folder_open),
                                ),
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: IconButton.filledTonal(
                                  onPressed: () async {
                                    final flag = await navigateTo<bool>(context, const AccountLoginPage());
                                    if (flag ?? false) setState(() {});
                                  },
                                  icon: const Icon(Icons.add),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
    isScrollControlled: true,
  );
}

IconData _guessStorageTypeByDesc(String desc) {
  final d = desc.toLowerCase();
  if (d.contains('usb')) {
    return Icons.usb_outlined;
  } else if (d.contains('sd')) {
    return Icons.sd_card_outlined;
  } else {
    return Icons.usb_outlined;
  }
}

Widget _buildAccountCard(BuildContext context, DriverAccount item, GestureTapCallback? onTap) {
  return FocusCard(
    width: 160,
    onTap: onTap,
    child: Column(
      children: [
        if (item.avatar == null)
          const Padding(padding: EdgeInsets.all(20), child: Icon(Icons.account_circle, size: 120))
        else
          AsyncImage(item.avatar!, ink: true, width: 160, height: 160),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.name, overflow: TextOverflow.ellipsis),
                Text(AppLocalizations.of(context)!.driverType(item.type.name)),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Future<DriverFile?> _showFilePicker(
  BuildContext context, {
  required String title,
  required FilePickerType type,
  required int driverId,
  required String defaultPath,
  FileType? fileType,
  FileType? selectableType,
}) async {
  final controller = FileViewerController<DriverFile>();
  Future<void> submit(DriverFile? file) async {
    if (file == null) return;
    Navigator.of(context).pop(file);
  }

  final file = await FilePicker.showFilePicker(
    context,
    controller: controller,
    type: type,
    defaultTitle: Text(AppLocalizations.of(context)!.pageTitleFileViewer),
    titleBuilder: (item) => Text(item?.name ?? 'Home'),
    actions: [],
    firstPageErrorIndicatorBuilder: (_) => Center(child: ErrorMessage(error: controller.error)),
    noItemsFoundIndicatorBuilder: (_) => const NoData(),
    fetchData: (index) async {
      final items = await Api.fileList(driverId, controller.currentItem.value?.id ?? defaultPath, type: fileType);
      return PageData(items: items, count: items.length, limit: 99999999);
    },
    itemBuilder: (context, item, index) {
      return Focus(
        onKeyEvent:
            item.type == FileType.folder
                ? (FocusNode node, KeyEvent event) {
                  if (event is KeyUpEvent) {
                    switch (event.logicalKey) {
                      case LogicalKeyboardKey.arrowRight:
                        controller.nextPage(item);
                        return KeyEventResult.handled;
                      case LogicalKeyboardKey.select:
                      case LogicalKeyboardKey.enter:
                        submit(item);
                        return KeyEventResult.handled;
                    }
                  }
                  return KeyEventResult.ignored;
                }
                : null,
        child: ListTile(
          leading: Radio<DriverFile>(
            value: item,
            onChanged: (selectableType == null || item.type == selectableType) ? submit : null,
            groupValue: null,
          ),
          title: Text(item.name),
          subtitle: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodySmall,
              children: [
                if (item.updatedAt != null) TextSpan(text: item.updatedAt!.formatFull()),
                if (item.updatedAt != null) const WidgetSpan(child: Gap.hMD),
                if (item.size != null) TextSpan(text: item.size!.toSizeDisplay()),
              ],
            ),
          ),
          trailing:
              item.type == FileType.folder
                  ? IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => controller.nextPage(item))
                  : null,
          onTap: item.type == FileType.folder ? () => controller.nextPage(item) : null,
        ),
      );
    },
  );
  controller.dispose();
  return file;
}
