import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';

/// The six boxes a verification code is typed into.
///
/// Six separate one-character fields rather than one text input: the digits are
/// what the driver is copying off a screen, and boxes let him check them one by
/// one against the email without counting characters.
///
/// The three behaviours that make or break it, and are easy to leave out:
/// typing advances by itself, backspace on an empty box steps back (otherwise
/// fixing the third digit means tapping precisely on it), and pasting the whole
/// code fills every box — people copy the code from the mail app, they do not
/// memorise it.
class CodeInputField extends StatefulWidget {
  const CodeInputField({
    super.key,
    required this.onCompleted,
    this.onChanged,
    this.length = 6,
    this.hasError = false,
    this.enabled = true,
  });

  /// Fires as soon as the last box is filled. The screen submits from here, so
  /// nobody has to reach for a button after typing the sixth digit.
  final ValueChanged<String> onCompleted;

  /// Every keystroke, for the screen to enable/disable its button.
  final ValueChanged<String>? onChanged;

  final int length;
  final bool hasError;
  final bool enabled;

  @override
  State<CodeInputField> createState() => CodeInputFieldState();
}

class CodeInputFieldState extends State<CodeInputField> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;

  /// Separate nodes for the key listeners. They are built ONCE here, never in
  /// `build`: a FocusNode created during a rebuild leaks and is silently
  /// replaced on the next frame, which is how OTP fields end up "sometimes"
  /// ignoring backspace.
  late final List<FocusNode> _keyNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _nodes = List.generate(widget.length, (_) => FocusNode());
    _keyNodes = List.generate(widget.length, (_) => FocusNode(skipTraversal: true));
    // Every node repaints its own box (focus ring), so the listener is what
    // keeps the border in sync without a setState on each keystroke.
    for (final n in _nodes) {
      n.addListener(_onFocusChange);
    }
    // The screen exists for one purpose, so the keyboard comes up on its own
    // instead of asking for a tap first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nodes.first.requestFocus();
    });
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.removeListener(_onFocusChange);
      n.dispose();
    }
    for (final n in _keyNodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get value => _controllers.map((c) => c.text).join();

  /// Empties the boxes and returns to the first one. Called after a wrong code:
  /// making him delete six digits to retype them is a punishment for a typo.
  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    widget.onChanged?.call('');
    _nodes.first.requestFocus();
  }

  void _handleChange(int index, String raw) {
    // A paste lands entirely in one box: spread it across the rest instead of
    // keeping the first character and dropping the code on the floor.
    if (raw.length > 1) {
      final digits = raw.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < widget.length; i++) {
        final at = index + i;
        if (at >= widget.length || i >= digits.length) break;
        _controllers[at].text = digits[i];
      }
      final filled = (index + digits.length).clamp(0, widget.length - 1);
      _nodes[filled].requestFocus();
      _emit();
      return;
    }

    if (raw.isNotEmpty && index < widget.length - 1) {
      _nodes[index + 1].requestFocus();
    }
    // Deleting the digit that is here steps back too, so holding backspace
    // walks the whole code instead of stopping at each box. The hardware-key
    // path below covers the box that is ALREADY empty.
    if (raw.isEmpty && index > 0) {
      _nodes[index - 1].requestFocus();
    }
    _emit();
  }

  void _emit() {
    final code = value;
    widget.onChanged?.call(code);
    if (code.length == widget.length) {
      // Dismiss the keyboard first: the confirmation lands on a screen the
      // driver can actually see.
      FocusScope.of(context).unfocus();
      widget.onCompleted(code);
    }
  }

  /// Backspace on an ALREADY empty box: move back and clear that digit. Without
  /// this the caret sits in an empty box and the key does nothing.
  void _handleKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey != LogicalKeyboardKey.backspace) return;
    if (_controllers[index].text.isNotEmpty || index == 0) return;

    _controllers[index - 1].clear();
    _nodes[index - 1].requestFocus();
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, _box),
    );
  }

  Widget _box(int index) {
    final focused = _nodes[index].hasFocus;
    final border = widget.hasError
        ? AppColors.primary600
        : focused
            ? AppColors.primary700
            : Colors.transparent;

    return SizedBox(
      width: 48,
      height: 56,
      child: KeyboardListener(
        focusNode: _keyNodes[index],
        onKeyEvent: (e) => _handleKey(index, e),
        child: TextField(
          controller: _controllers[index],
          focusNode: _nodes[index],
          enabled: widget.enabled,
          keyboardType: TextInputType.number,
          textInputAction:
              index == widget.length - 1 ? TextInputAction.done : TextInputAction.next,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (v) => _handleChange(index, v),
          decoration: InputDecoration(
            // The box IS the character: no counter under it, no hint inside it.
            counterText: '',
            filled: true,
            fillColor: widget.hasError
                ? AppColors.primary50
                : focused
                    ? AppColors.surface
                    : const Color(0xFFF3F4F6),
            contentPadding: EdgeInsets.zero,
            enabledBorder: _border(border),
            focusedBorder: _border(widget.hasError ? AppColors.primary600 : AppColors.primary700),
            disabledBorder: _border(Colors.transparent),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: 1.5),
      );
}
