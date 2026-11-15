// Gambar hasil scan buku di atas kartu putih (juga di mode gelap). FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/content_service/domain/providers/content_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class BookImage extends ConsumerWidget {
  const BookImage(this.relativePath, {super.key, this.semanticLabel, this.padding = Sp.x3});
  final String relativePath; // path dari JSON, mis. "img/L01/kaiwa.webp"
  final String? semanticLabel;
  final double padding;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final env = ref.watch(appEnvProvider);
    final p = context.palette;
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(color: p.imageBg, borderRadius: Radii.lgAll, border: Border.all(color: p.border)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.asset(env.asset(relativePath), fit: BoxFit.contain, width: double.infinity, semanticLabel: semanticLabel),
      ),
    );
  }
}
