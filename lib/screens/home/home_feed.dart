import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../controllers/changelog_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../generated/codegen_loader_keys.g.dart';
import '../../models/changelog_entry.dart';
import '../../models/home_banner.dart';
import '../../services/remote_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cards.dart';
import '../../widgets/feedback.dart';
import '../../utils/navigation.dart';
import '../changelog_screen.dart';

/// Banner + cobalt changelog list at the bottom of the home screen.
class HomeFeed extends StatefulWidget {
  const HomeFeed({super.key, required this.settings, required this.changelogs});

  final SettingsController settings;
  final ChangelogController changelogs;

  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed> {
  Future<HomeBanner?>? _banner;
  String? _bannerLanguage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = context.locale.languageCode;
    if (language != _bannerLanguage) {
      _bannerLanguage = language;
      _banner = RemoteData.banner(language).catchError((Object _) => null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (settings.showBanner)
          FutureBuilder<HomeBanner?>(
            future: _banner,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const _Divided(child: _BannerSkeleton());
              }
              final banner = snapshot.data;
              return banner == null ? const SizedBox.shrink() : _Divided(child: _BannerCard(banner: banner));
            },
          ),
        if (settings.showChangelogs) ...[
          const Divider(),
          const SizedBox(height: AppSpacing.gap),
          ListenableBuilder(
            listenable: widget.changelogs,
            builder: (context, _) => _ChangelogList(controller: widget.changelogs),
          ),
        ],
      ],
    );
  }
}

/// Divider above, gap below — the separator used between home sections.
class _Divided extends StatelessWidget {
  const _Divided({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        const SizedBox(height: AppSpacing.gap),
        child,
        const SizedBox(height: AppSpacing.gap),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner});

  final HomeBanner banner;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: EdgeInsets.zero,
      borderColor: AppColors.borderSubtle,
      onTap: () => openExternalUrl(banner.link),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              banner.image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(color: AppColors.surface),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x33000000), Color(0xD1000000)],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(banner.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(banner.subtitle, style: AppTextStyles.small),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerSkeleton extends StatelessWidget {
  const _BannerSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SurfaceCard(
      borderColor: AppColors.borderSubtle,
      padding: EdgeInsets.all(11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(height: 16, width: 150),
          SizedBox(height: 10),
          Skeleton(height: 15, width: 220),
          SizedBox(height: 4),
          Skeleton(height: 15, width: 100),
        ],
      ),
    );
  }
}

class _ChangelogList extends StatelessWidget {
  const _ChangelogList({required this.controller});

  final ChangelogController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.initialLoading) {
      return Column(children: separated(const [_ChangelogSkeleton(), _ChangelogSkeleton(), _ChangelogSkeleton()]));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: separated([
        for (final entry in controller.entries) _ChangelogCard(entry: entry),
        if (controller.hasMore)
          SurfaceCard(
            borderColor: AppColors.borderSubtle,
            padding: const EdgeInsets.symmetric(vertical: 12),
            onTap: controller.loadingMore ? null : controller.loadMore,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: controller.loadingMore
                  ? [
                      const AppSpinner(size: 16),
                      const SizedBox(width: 8),
                      Text(LocaleKeys.Loading.tr(), style: _buttonText),
                    ]
                  : [
                      Text(LocaleKeys.LoadMore.tr(), style: _buttonText),
                      const SizedBox(width: 8),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
                    ],
            ),
          ),
      ]),
    );
  }

  static const _buttonText = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white);
}

class _ChangelogCard extends StatelessWidget {
  const _ChangelogCard({required this.entry});

  final ChangelogEntry entry;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: EdgeInsets.zero,
      borderColor: AppColors.borderSubtle,
      onTap: () => pushPage(context, ChangelogScreen(entry: entry)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry.bannerFile != null)
            Stack(
              children: [
                ChangelogBannerImage(entry: entry, height: 120),
                Positioned(top: 10, right: 10, child: Pill(LocaleKeys.APIUpdate.tr())),
              ],
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('v${entry.version}', style: AppTextStyles.cardTitle),
                    Text(entry.date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(entry.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(entry.preview, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangelogSkeleton extends StatelessWidget {
  const _ChangelogSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SurfaceCard(
      padding: EdgeInsets.zero,
      borderColor: AppColors.borderSubtle,
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(height: 120, base: AppColors.surfaceRaised, borderRadius: BorderRadius.zero),
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Skeleton(height: 14, width: 60), Skeleton(height: 12, width: 80)],
                ),
                SizedBox(height: 8),
                Skeleton(height: 13, width: 200),
                SizedBox(height: 10),
                Skeleton(height: 12, width: double.infinity),
                SizedBox(height: 6),
                Skeleton(height: 12, width: double.infinity),
                SizedBox(height: 6),
                Skeleton(height: 12, width: 250),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
