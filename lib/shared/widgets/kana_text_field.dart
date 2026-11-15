// Kotak isian yang mengubah ketikan romaji huruf kecil menjadi hiragana secara langsung.
// FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH. (docs/06_Algoritma.md §3)

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/text_theme.dart';
import '../utils/kana_input.dart';

enum FieldState { normal, correct, wrong }

class KanaTextField extends StatefulWidget {
  const KanaTextField({
    super.key,
    required this.initial,
    required this.onChanged,
    this.width,
    this.enabled = true,
    this.state = FieldState.normal,
    this.hint = '',
    this.multiline = false,
  });
  final String initial;
  final ValueChanged<String> onChanged;
  final double? width; // null = selebar mungkin
  final bool enabled;
  final FieldState state;
  final String hint;
  final bool multiline;

  @override
  State<KanaTextField> createState() => _KanaTextFieldState();
}

class _KanaTextFieldState extends State<KanaTextField> {
  late final TextEditingController _c = TextEditingController(text: widget.initial);

  @override
  void didUpdateWidget(covariant KanaTextField old) {
    super.didUpdateWidget(old);
    if (widget.initial != old.initial && widget.initial != _c.text) _c.text = widget.initial;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    final conv = romajiToHiragana(v);
    if (conv != v) {
      _c.value = TextEditingValue(text: conv, selection: TextSelection.collapsed(offset: conv.length));
    }
    widget.onChanged(conv);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = switch (widget.state) {
      FieldState.correct => p.success,
      FieldState.wrong => p.danger,
      FieldState.normal => p.border,
    };
    final field = TextField(
      controller: _c,
      enabled: widget.enabled,
      onChanged: _onChanged,
      minLines: 1,
      maxLines: widget.multiline ? 3 : 1,
      style: AppText.jpSm(1).copyWith(color: p.ink, height: 1.3),
      decoration: InputDecoration(
        hintText: widget.hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: Sp.x2, vertical: Sp.x2),
        enabledBorder: OutlineInputBorder(borderRadius: Radii.smAll, borderSide: BorderSide(color: color, width: widget.state == FieldState.normal ? 1 : 1.8)),
        disabledBorder: OutlineInputBorder(borderRadius: Radii.smAll, borderSide: BorderSide(color: color, width: widget.state == FieldState.normal ? 1 : 1.8)),
      ),
    );
    return widget.width == null ? field : SizedBox(width: widget.width, child: field);
  }
}
