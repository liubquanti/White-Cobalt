import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../config/app_urls.dart';
import '../../generated/codegen_loader_keys.g.dart';
import '../../services/remote_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../utils/formatters.dart';
import '../../utils/navigation.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/cards.dart';

class _Link {
  const _Link(this.icon, this.url);

  final String icon;
  final String url;
}

/// A person or project credited on the About page.
class _Credit {
  const _Credit({
    required this.avatar,
    required this.title,
    required this.subtitle,
    required this.links,
    this.description,
  });

  final String avatar;
  final String title;
  final String subtitle;
  final String? description;
  final List<_Link> links;
}

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  // Created once — the old screen called PackageInfo.fromPlatform() four
  // times on every rebuild.
  final Future<PackageInfo> _packageInfo = RemoteData.packageInfo();
  final Future<String?> _latestVersion = RemoteData.latestAppVersion().catchError((Object _) => null);

  List<_Credit> get _creators => [
        _Credit(
          avatar: 'assets/photos/liubquanti.png',
          title: LocaleKeys.liubquanti.tr(),
          subtitle: LocaleKeys.UIAndUXAndCoding.tr(),
          links: const [
            _Link(AppIcons.telegram, 'https://t.me/liubquanti'),
            _Link(AppIcons.instagram, 'https://instagram.com/liubquanti'),
            _Link(AppIcons.figma, 'https://www.figma.com/@liubquanti'),
            _Link(AppIcons.github, 'https://github.com/liubquanti'),
          ],
        ),
        _Credit(
          avatar: 'assets/photos/ffastffox.jpg',
          title: LocaleKeys.ffastffox.tr(),
          subtitle: LocaleKeys.Artworking.tr(),
          links: const [
            _Link(AppIcons.instagram, 'https://instagram.com/ffastffox'),
            _Link(AppIcons.pinterest, 'https://pinterest.com/ffastffox/'),
          ],
        ),
      ];

  List<_Credit> get _apis => [
        _Credit(
          avatar: 'assets/photos/cobalt.png',
          title: LocaleKeys.imputnetsCobalt.tr(),
          subtitle: LocaleKeys.MediaDownloadingAPI.tr(),
          description: LocaleKeys.CobaltDescription.tr(),
          links: const [
            _Link(AppIcons.world, 'https://cobalt.tools/'),
            _Link(AppIcons.github, 'https://github.com/imputnet/cobalt'),
            _Link(AppIcons.discord, 'https://discord.com/invite/pQPt8HBUPu'),
          ],
        ),
        _Credit(
          avatar: 'assets/photos/kwiat.png',
          title: LocaleKeys.kwiatsCobaltInstances.tr(),
          subtitle: LocaleKeys.InstancesProviderAPI.tr(),
          description: LocaleKeys.ASimpleToUseAndConvenientListOfCobaltInstances.tr(),
          links: const [
            _Link(AppIcons.world, 'https://instances.cobalt.best/'),
            _Link(AppIcons.pyramid, 'https://codeberg.org/kwiat/instances'),
          ],
        ),
        _Credit(
          avatar: 'assets/photos/hyper.png',
          title: LocaleKeys.hypersCobaltDirectory.tr(),
          subtitle: LocaleKeys.InstancesProviderAPI.tr(),
          description: LocaleKeys.HyperCommunityTrackingDescription.tr(),
          links: const [
            _Link(AppIcons.world, 'https://cobalt.directory/'),
            _Link(AppIcons.pyramid, 'https://codeberg.org/hyperdefined/cobalt.directory'),
          ],
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: LocaleKeys.About.tr(),
      body: PageScrollView(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Section(
            first: true,
            title: LocaleKeys.Creators.tr(),
            children: [for (final c in _creators) _CreditCard(credit: c)],
          ),
          Section(
            title: LocaleKeys.API.tr(),
            children: [for (final c in _apis) _CreditCard(credit: c)],
          ),
          Section(
            title: LocaleKeys.SupportApp.tr(),
            children: [
              SurfaceCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _WideLinkButton(
                      icon: AppIcons.googlePlay,
                      label: LocaleKeys.LeaveAReview.tr(),
                      url: AppUrls.playStore,
                    ),
                    const SizedBox(height: AppSpacing.gap),
                    _WideLinkButton(
                      icon: AppIcons.github,
                      label: LocaleKeys.GiveAStar.tr(),
                      url: AppUrls.repository,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Section(
            title: LocaleKeys.AppInfo.tr(),
            children: [
              SurfaceCard(
                padding: const EdgeInsets.all(16),
                child: FutureBuilder<PackageInfo>(
                  future: _packageInfo,
                  builder: (context, snapshot) {
                    final info = snapshot.data;
                    final loading = LocaleKeys.Loading.tr();
                    return Column(
                      children: separated([
                        _InfoRow(
                          label: LocaleKeys.Version.tr(),
                          value: info == null ? Text(loading, style: _valueStyle) : _VersionValue(info.version, _latestVersion),
                        ),
                        _InfoRow(label: LocaleKeys.Build.tr(), value: Text(info?.buildNumber ?? loading, style: _valueStyle)),
                        _InfoRow(label: LocaleKeys.Package.tr(), value: Text(info?.packageName ?? loading, style: _valueStyle)),
                        _InfoRow(
                          label: LocaleKeys.Installer.tr(),
                          value: Text(
                            info == null ? loading : (info.installerStore ?? LocaleKeys.Unknown.tr()),
                            style: _valueStyle,
                          ),
                        ),
                      ]),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const _valueStyle = TextStyle(fontSize: 14, color: AppColors.textSecondary);
}

class _CreditCard extends StatelessWidget {
  const _CreditCard({required this.credit});

  final _Credit credit;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.black,
                backgroundImage: AssetImage(credit.avatar),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(credit.title, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 4),
                    Text(credit.subtitle, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          if (credit.description != null) ...[
            const SizedBox(height: AppSpacing.gap),
            Text(credit.description!, style: AppTextStyles.caption),
          ],
          const SizedBox(height: AppSpacing.gap),
          Wrap(
            spacing: AppSpacing.gap,
            runSpacing: AppSpacing.gap,
            children: [
              for (final link in credit.links)
                BorderedIconButton(icon: link.icon, onTap: () => openExternalUrl(link.url)),
            ],
          ),
        ],
      ),
    );
  }
}

class _WideLinkButton extends StatelessWidget {
  const _WideLinkButton({required this.icon, required this.label, required this.url});

  final String icon;
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: BorderedIconButton(
        icon: icon,
        label: label,
        labelStyle: const TextStyle(fontSize: 14),
        onTap: () => openExternalUrl(url),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.body),
        const SizedBox(width: AppSpacing.gap),
        Flexible(child: Align(alignment: AlignmentDirectional.centerEnd, child: value)),
      ],
    );
  }
}

/// Installed version, highlighted red when a newer release exists.
class _VersionValue extends StatelessWidget {
  const _VersionValue(this.installed, this.latest);

  final String installed;
  final Future<String?> latest;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: latest,
      builder: (context, snapshot) {
        final remote = snapshot.data;
        // Only "outdated" when the published version is actually newer —
        // the old `!=` check also flagged development builds.
        final outdated = remote != null && compareVersions(remote, installed) > 0;
        const red = TextStyle(fontSize: 14, color: AppColors.error, fontWeight: FontWeight.bold);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(installed, style: outdated ? red : const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            if (outdated) ...[const SizedBox(width: 8), Text(LocaleKeys.outdated.tr(), style: red)],
          ],
        );
      },
    );
  }
}
