import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../config/app_urls.dart';
import '../generated/codegen_loader_keys.g.dart';
import '../models/changelog_entry.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../utils/navigation.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/feedback.dart';
import '../widgets/svg_icon.dart';

class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key, required this.entry});

  final ChangelogEntry entry;

  static final _markdownStyle = MarkdownStyleSheet(
    p: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
    h1: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
    h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
    h3: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
    listBullet: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
    a: const TextStyle(color: Colors.white, decoration: TextDecoration.underline),
  );

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'v${entry.version}',
      actions: [
        IconButton(
          icon: const SvgIcon(AppIcons.externalLink),
          tooltip: LocaleKeys.OpenOnGitHub.tr(),
          onPressed: () => openExternalUrl('${AppUrls.cobaltUpdates}${entry.version}'),
        ),
      ],
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.bannerFile != null) ChangelogBannerImage(entry: entry, height: 200),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.page, 10, AppSpacing.page, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.date, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  Text(
                    entry.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const Divider(height: 16),
                  MarkdownBody(
                    data: entry.content,
                    styleSheet: _markdownStyle,
                    // Links come from a third-party repo; only http(s) opens.
                    onTapLink: (_, href, __) => openExternalUrl(href),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Release banner image with a skeleton while loading and a version fallback.
class ChangelogBannerImage extends StatelessWidget {
  const ChangelogBannerImage({super.key, required this.entry, required this.height});

  final ChangelogEntry entry;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      '${AppUrls.cobaltUpdateBanners}${entry.bannerFile}',
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : Skeleton(height: height, base: AppColors.surfaceRaised, borderRadius: BorderRadius.zero),
      // The old fallback used a single-colour gradient, which throws an
      // assertion, and drew white text on white.
      errorBuilder: (_, __, ___) => Container(
        height: height,
        width: double.infinity,
        color: AppColors.surfaceRaised,
        alignment: Alignment.center,
        child: Text(
          'v${entry.version}',
          style: TextStyle(fontSize: height / 6, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}
