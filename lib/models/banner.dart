class BannerLocalization {
  final String title;
  final String subtitle;

  BannerLocalization({
    required this.title,
    required this.subtitle,
  });

  factory BannerLocalization.fromJson(Map<String, dynamic> json) {
    return BannerLocalization(
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
    );
  }
}

class HomeBanner {
  final String link;
  final String image;
  final BannerLocalization localization;

  HomeBanner({
    required this.link,
    required this.image,
    required this.localization,
  });
}
