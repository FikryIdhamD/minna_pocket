import '../../../../routes/app_route.dart';

String routeForRef(String ref) {
  final parts = ref.split('.');
  if (parts.isEmpty) return '/';
  final head = parts[0];
  if (head.startsWith('L') && head.length >= 2 && parts.length >= 2) {
    final n = int.tryParse(head.substring(1));
    if (n != null) {
      final key = parts[1];
      const direct = {'kosakata', 'bunkei', 'reibun', 'kaiwa', 'sankou'};
      if (direct.contains(key)) return sectionRoute(n, key);
      final no = parts.length >= 3 ? int.tryParse(parts[2]) : null;
      return sectionRoute(n, key, no: no);
    }
  }
  if (parts.length >= 2) {
    final ex = int.tryParse(parts[1]) ?? 1;
    return '/ms/$head/ex/$ex';
  }
  return '/';
}
