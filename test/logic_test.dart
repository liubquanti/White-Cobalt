import 'package:flutter_test/flutter_test.dart';
import 'package:white_cobalt/models/app_settings.dart';
import 'package:white_cobalt/models/changelog_entry.dart';
import 'package:white_cobalt/models/cobalt_response.dart';
import 'package:white_cobalt/models/home_banner.dart';
import 'package:white_cobalt/models/server_config.dart';
import 'package:white_cobalt/services/cobalt_api.dart';
import 'package:white_cobalt/utils/formatters.dart';
import 'package:white_cobalt/utils/media_paths.dart';

void main() {
  group('MediaPaths.sanitize (path traversal)', () {
    test('strips separators and traversal', () {
      for (final evil in ['../../etc/passwd', '..\\..\\x', '/abs/path', 'a/../b', '..', '...']) {
        final out = MediaPaths.sanitize(evil, fallback: 'fb');
        expect(out.contains('/'), isFalse, reason: evil);
        expect(out.contains('\\'), isFalse, reason: evil);
        expect(out.contains('..'), isFalse, reason: evil);
      }
    });
    test('keeps normal names', () {
      expect(MediaPaths.sanitize('youtube_abc.mp4', fallback: 'x'), 'youtube_abc.mp4');
    });
    test('empty / dot fall back', () {
      expect(MediaPaths.sanitize('', fallback: 'x'), 'x');
      expect(MediaPaths.sanitize('.', fallback: 'x'), 'x');
      expect(MediaPaths.sanitize('\x00\x01', fallback: 'x'), 'x');
    });
  });

  group('MediaPaths.serviceFolder', () {
    test('reported service wins and is sanitized', () {
      expect(
        MediaPaths.serviceFolder(reportedService: '../YouTube', filename: 'a.mp4', sourceUrl: '', fallback: 'o'),
        isNot(contains('/')),
      );
    });
    test('filename prefix', () {
      expect(MediaPaths.serviceFolder(reportedService: null, filename: 'tiktok_1.mp4', sourceUrl: '', fallback: 'o'),
          'tiktok');
    });
    test('domain fallback', () {
      expect(
        MediaPaths.serviceFolder(
            reportedService: null, filename: 'cobalt_1.mp4', sourceUrl: 'https://www.instagram.com/p/x', fallback: 'o'),
        'instagram',
      );
      expect(
        MediaPaths.serviceFolder(
            reportedService: null, filename: 'x.mp4', sourceUrl: 'https://m.youtube.com/watch', fallback: 'o'),
        'youtube',
      );
    });
    test('publicDirFor', () {
      expect(MediaPaths.publicDirFor('a.MP4'), MediaPaths.movies);
      expect(MediaPaths.publicDirFor('a.jpg'), MediaPaths.pictures);
      expect(MediaPaths.publicDirFor('a.opus'), MediaPaths.music);
      expect(MediaPaths.publicDirFor('noext'), MediaPaths.download);
    });
  });

  group('ServerConfig.normalizeUrl', () {
    test('adds https and strips slashes', () {
      expect(ServerConfig.normalizeUrl(' api.example.com/// '), 'https://api.example.com');
    });
    test('rejects bad schemes', () {
      expect(ServerConfig.normalizeUrl('javascript://x'), isNull);
      expect(ServerConfig.normalizeUrl('file:///etc'), isNull);
      expect(ServerConfig.normalizeUrl(''), isNull);
    });
    test('toJson never contains the api key', () {
      const s = ServerConfig(url: 'https://a', apiKey: 'secret');
      expect(s.toJson().containsKey('apiKey'), isFalse);
      expect(s.toJson().values, isNot(contains('secret')));
    });
  });

  group('CobaltResponse.fromJson', () {
    test('tunnel', () {
      final r = CobaltResponse.fromJson({'status': 'tunnel', 'url': 'https://x/y', 'filename': 'a.mp4'});
      expect(r.status, CobaltStatus.tunnel);
      expect(r.url, 'https://x/y');
    });
    test('local-processing', () {
      final r = CobaltResponse.fromJson({
        'status': 'local-processing',
        'type': 'merge',
        'tunnel': ['https://t/1', 'https://t/2'],
        'output': {'filename': 'out.mp4'},
      });
      expect(r.status, CobaltStatus.localProcessing);
      expect(r.url, 'https://t/1');
      expect(r.filename, 'out.mp4');
    });
    test('picker skips invalid items', () {
      final r = CobaltResponse.fromJson({
        'status': 'picker',
        'picker': [
          {'type': 'photo', 'url': 'https://p'},
          {'type': 'video'},
          'garbage',
        ],
      });
      expect(r.picker.length, 1);
      expect(r.picker.first.extension, '.jpg');
    });
    test('error + garbage', () {
      final r = CobaltResponse.fromJson({
        'status': 'error',
        'error': {'code': 'error.api.auth.key.missing'},
      });
      expect(r.isAuthKeyMissing, isTrue);
      expect(CobaltResponse.fromJson('nope').status, CobaltStatus.unknown);
      expect(CobaltResponse.fromJson(null).status, CobaltStatus.unknown);
    });
  });

  group('ServerInfo.tryParse', () {
    test('valid / invalid', () {
      expect(ServerInfo.tryParse({'cobalt': {'version': '10.1', 'services': ['a', 'b']}})?.servicesCount, 2);
      expect(ServerInfo.tryParse({'hello': 1}), isNull);
      expect(ServerInfo.tryParse([1]), isNull);
    });
  });

  group('CobaltApi.resolveMediaUrl', () {
    test('rewrites localhost tunnels', () {
      expect(
        CobaltApi.resolveMediaUrl('http://localhost:9000/tunnel?id=1', 'https://api.example.com'),
        'https://api.example.com/tunnel?id=1',
      );
    });
    test('leaves other urls', () {
      expect(CobaltApi.resolveMediaUrl('https://cdn/x', 'https://api'), 'https://cdn/x');
    });
  });

  group('AppSettings.fromJson (migration from old format)', () {
    test('old JSON with downloadDir and bad values', () {
      final s = AppSettings.fromJson({
        'downloadDir': '/storage/emulated/0/Download/Cobalt',
        'useLocalProcessing': false,
        'videoQuality': '9999',
        'audioFormat': 'mp3',
        'shareLinks': 'yes',
      });
      expect(s.useLocalProcessing, isFalse);
      expect(s.videoQuality, 'max');
      expect(s.audioFormat, 'mp3');
      expect(s.shareLinks, isFalse);
    });
    test('roundtrip', () {
      const s = AppSettings(audioBitrate: '128', showBanner: false);
      final back = AppSettings.fromJson(s.toJson());
      expect(back.audioBitrate, '128');
      expect(back.showBanner, isFalse);
    });
  });

  group('formatters', () {
    test('formatBytes', () {
      expect(formatBytes(0), '0 B');
      expect(formatBytes(-5), '0 B');
      expect(formatBytes(1023), '1023 B');
      expect(formatBytes(1536), '1.50 KB');
      expect(formatBytes(1024 * 1024 * 150), '150 MB');
    });
    test('compareVersions', () {
      expect(compareVersions('10.10', '10.2.1') > 0, isTrue);
      expect(compareVersions('1.0', '1'), 0);
      expect(compareVersions('abc', '0.0.1') < 0, isTrue);
    });
  });

  group('ChangelogEntry.parse', () {
    test('front matter with banner and colon in title', () {
      const md = '---\ntitle: "v10: big update"\ndate: "1 Jan 2025"\nbanner:\n    file: "x.webp"\n    alt: "a"\n---\n\nbody here';
      final e = ChangelogEntry.parse('10.0', md)!;
      expect(e.title, 'v10: big update');
      expect(e.bannerFile, 'x.webp');
      expect(e.content, 'body here');
    });
    test('invalid returns null', () {
      expect(ChangelogEntry.parse('1', 'no front matter'), isNull);
    });
  });

  group('HomeBanner.pick', () {
    test('locale fallback', () {
      final b = HomeBanner.pick([
        {
          'link': 'https://l',
          'image': 'https://i',
          'localisations': {
            'en': {'title': 'EN', 'subtitle': 's'},
          },
        },
      ], 'uk');
      expect(b?.title, 'EN');
      expect(HomeBanner.pick({'x': 1}, 'en'), isNull);
    });
  });
}
