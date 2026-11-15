// Ikon Lucide dari assets/icons/<nama>.svg. FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.
// Pemakaian: AppIcon(AppIcons.play), AppIcon(AppIcons.search, size: 20, color: context.palette.inkMuted)

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

abstract final class AppIcons {
  static const arrowLeft = 'arrow-left';
  static const arrowRight = 'arrow-right';
  static const search = 'search';
  static const close = 'x';
  static const check = 'check';
  static const checkCircle = 'circle-check';
  static const xCircle = 'circle-x';
  static const chevronRight = 'chevron-right';
  static const chevronLeft = 'chevron-left';
  static const chevronDown = 'chevron-down';
  static const headphones = 'headphones';
  static const play = 'play';
  static const pause = 'pause';
  static const repeat = 'repeat';
  static const repeatOne = 'repeat-1';
  static const book = 'book-open';
  static const translate = 'languages';
  static const speaker = 'volume-2';
  static const sparkles = 'sparkles';
  static const flag = 'flag';
  static const star = 'star';
  static const settings = 'settings';
  static const more = 'ellipsis';
  static const cards = 'layers';
  static const practice = 'square-check-big';
  static const info = 'info';
  static const hint = 'lightbulb';
  static const reset = 'rotate-ccw';
  static const shuffle = 'shuffle';
  static const trash = 'trash';
  static const download = 'download';
  static const upload = 'upload';
  static const history = 'history';
  static const bookmark = 'bookmark';
  static const help = 'circle-help';
  static const edit = 'pencil';
  static const clock = 'clock';
  static const list = 'list';
  static const key = 'key-round';
  static const offline = 'wifi-off';
  static const alert = 'circle-alert';
  static const home = 'house';
  static const sun = 'sun';
  static const moon = 'moon';
  static const copy = 'copy';
}

class AppIcon extends StatelessWidget {
  const AppIcon(this.name, {super.key, this.size = 24, this.color, this.semanticLabel});
  final String name;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? const Color(0xFF2A272B);
    return SvgPicture.asset(
      'assets/icons/$name.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
    );
  }
}
