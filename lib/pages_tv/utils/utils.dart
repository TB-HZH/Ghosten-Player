import 'dart:io';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/user_config.dart';
import '../components/filled_button.dart';
import '../components/text_button.dart';
import '../components/text_field_focus.dart';

class FadeInPageRoute<T> extends PageRoute<T> {
  FadeInPageRoute({required this.builder, super.settings});

  @override
  final Duration transitionDuration = const Duration(milliseconds: 650);

  @override
  final Duration reverseTransitionDuration = const Duration(milliseconds: 650);

  @override
  final bool opaque = true;

  @override
  final bool barrierDismissible = false;

  @override
  final Color? barrierColor = null;

  @override
  final String? barrierLabel = null;

  @override
  final bool maintainState = true;

  final WidgetBuilder builder;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SharedAxisTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      transitionType: SharedAxisTransitionType.horizontal,
      fillColor: Colors.transparent,
      child: child,
    );
  }
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
    final bool useKeypad = Platform.isAndroid; // Android TV

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFieldFocus(
              child: TextField(
                controller: _controller,
                obscureText: true,
                autofocus: !useKeypad,
                readOnly: useKeypad,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onSubmitted: (value) => Navigator.pop(context, value),
              ),
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
          TVTextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TVFilledButton(
            onPressed: () => Navigator.pop(context, _controller.text),
            child: const Text('确认'),
          ),
        ] else
          TVTextButton(
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

Future<T?> navigateToSlideLeft<T extends Object?>(BuildContext context, Widget page) {
  return Navigator.of(context).push(FadeInPageRoute(builder: (context) => page));
}
