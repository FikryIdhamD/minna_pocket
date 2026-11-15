// Konfigurasi flavor buku. FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

enum BookFlavor { book1, book2 }

class AppEnv {
  const AppEnv._(this.flavor, this.book, this.appName, this.assetBase);
  final BookFlavor flavor;
  final int book;
  final String appName;

  /// Awalan path aset, mis. 'assets/book1/'. Path di JSON digabung: assetBase + path.
  final String assetBase;

  static const book1 = AppEnv._(BookFlavor.book1, 1, 'Minna Pocket', 'assets/book1/');
  static const book2 = AppEnv._(BookFlavor.book2, 2, 'Minna Pocket II', 'assets/book2/');

  String asset(String relative) => '$assetBase$relative';
}
