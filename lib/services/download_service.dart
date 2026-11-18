import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/logger.dart';
import '../utils/media_paths.dart';

const _portName = 'white_cobalt_downloader';

/// Runs in flutter_downloader's background isolate; forwards updates to the
/// UI isolate through a named port.
@pragma('vm:entry-point')
void downloaderCallback(String id, int status, int progress) {
  IsolateNameServer.lookupPortByName(_portName)?.send([id, status, progress]);
}

enum DownloadPhase { queued, running, paused, finalizing }

class DownloadUpdate {
  const DownloadUpdate(this.phase, [this.progress = 0]);

  final DownloadPhase phase;
  final int progress;
}

enum DownloadFailure { failed, canceled, fileMissing, io }

class DownloadException implements Exception {
  const DownloadException(this.reason, [this.detail]);

  final DownloadFailure reason;
  final Object? detail;

  @override
  String toString() => detail == null ? reason.name : '$detail';
}

class _TaskEvent {
  const _TaskEvent(this.id, this.status, this.progress);

  final String id;
  final DownloadTaskStatus status;
  final int progress;
}

/// Downloads a file into the app cache, then moves it to
/// `<public media dir>/Cobalt/<service>/` and registers it with MediaStore.
abstract final class DownloadService {
  static final _port = ReceivePort();
  static final _events = StreamController<_TaskEvent>.broadcast();

  /// Last event per task, so updates that arrive before the caller knows
  /// the task id are not lost.
  static final _lastEvent = <String, _TaskEvent>{};

  static Future<void> initialize() async {
    await FlutterDownloader.initialize(debug: false);
    IsolateNameServer.removePortNameMapping(_portName);
    IsolateNameServer.registerPortWithName(_port.sendPort, _portName);
    _port.listen((message) {
      if (message is! List || message.length != 3) return;
      final event = _TaskEvent(
        message[0] as String,
        DownloadTaskStatus.fromInt(message[1] as int),
        message[2] as int,
      );
      _lastEvent[event.id] = event;
      _events.add(event);
    });
    await FlutterDownloader.registerCallback(downloaderCallback, step: 1);
  }

  static Future<void> requestPermissions() async {
    for (final permission in [Permission.storage, Permission.videos, Permission.photos, Permission.audio]) {
      try {
        await permission.request();
      } catch (e) {
        logDebug('Permission $permission: $e');
      }
    }
  }

  /// Returns the saved file. Throws [DownloadException].
  static Future<File> download({
    required String url,
    required String filename,
    required String serviceFolder,
    required void Function(DownloadUpdate) onUpdate,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$filename');
    // flutter_downloader renames on collision, which made the old code
    // report "file not found" when the same file was downloaded twice.
    if (await tempFile.exists()) await tempFile.delete();

    onUpdate(const DownloadUpdate(DownloadPhase.queued));
    final taskId = await FlutterDownloader.enqueue(
      url: url,
      savedDir: tempDir.path,
      fileName: filename,
      showNotification: false,
      openFileFromNotification: false,
    );
    if (taskId == null) throw const DownloadException(DownloadFailure.failed);

    final DownloadTaskStatus result;
    try {
      result = await _awaitTask(taskId, onUpdate);
    } finally {
      _lastEvent.remove(taskId);
      // Keep the downloader's task database from growing forever.
      unawaited(FlutterDownloader.remove(taskId: taskId, shouldDeleteContent: false));
    }

    switch (result) {
      case DownloadTaskStatus.complete:
        break;
      case DownloadTaskStatus.canceled:
        throw const DownloadException(DownloadFailure.canceled);
      default:
        throw const DownloadException(DownloadFailure.failed);
    }

    onUpdate(const DownloadUpdate(DownloadPhase.finalizing));
    if (!await tempFile.exists()) throw const DownloadException(DownloadFailure.fileMissing);

    try {
      final target = File('${await _targetDir(filename, serviceFolder)}/$filename');
      if (await target.exists()) await target.delete();
      await tempFile.copy(target.path);
      await tempFile.delete();
      try {
        await MediaScanner.loadMedia(path: target.path);
      } catch (e) {
        logDebug('Media scan failed: $e');
      }
      return target;
    } on FileSystemException catch (e) {
      throw DownloadException(DownloadFailure.io, e.message);
    }
  }

  static Future<DownloadTaskStatus> _awaitTask(String taskId, void Function(DownloadUpdate) onUpdate) {
    final completer = Completer<DownloadTaskStatus>();

    void handle(DownloadTaskStatus status, int progress) {
      if (completer.isCompleted) return;
      switch (status) {
        case DownloadTaskStatus.enqueued:
          onUpdate(const DownloadUpdate(DownloadPhase.queued));
        case DownloadTaskStatus.running:
          onUpdate(DownloadUpdate(DownloadPhase.running, progress < 0 ? 0 : (progress > 100 ? 100 : progress)));
        case DownloadTaskStatus.paused:
          onUpdate(const DownloadUpdate(DownloadPhase.paused));
        case DownloadTaskStatus.complete:
        case DownloadTaskStatus.failed:
        case DownloadTaskStatus.canceled:
          completer.complete(status);
        default:
          break;
      }
    }

    final subscription = _events.stream.where((e) => e.id == taskId).listen((e) => handle(e.status, e.progress));
    final cached = _lastEvent[taskId];
    if (cached != null) handle(cached.status, cached.progress);

    // Safety net in case a callback is dropped: poll the task state slowly.
    final poll = Timer.periodic(const Duration(seconds: 3), (_) async {
      final task = await _loadTask(taskId);
      if (task != null) handle(task.status, task.progress);
    });

    return completer.future.whenComplete(() {
      poll.cancel();
      subscription.cancel();
    });
  }

  static final _taskIdPattern = RegExp(r'^[A-Za-z0-9-]+$');

  static Future<DownloadTask?> _loadTask(String taskId) async {
    // The id is interpolated into SQL, so only accept the UUID shape the
    // plugin generates.
    if (!_taskIdPattern.hasMatch(taskId)) return null;
    try {
      final tasks = await FlutterDownloader.loadTasksWithRawQuery(
        query: "SELECT * FROM task WHERE task_id = '$taskId'",
      );
      return (tasks == null || tasks.isEmpty) ? null : tasks.first;
    } catch (e) {
      logDebug('loadTasks failed: $e');
      return null;
    }
  }

  static Future<String> _targetDir(String filename, String serviceFolder) async {
    final base = MediaPaths.publicDirFor(filename);
    final dir = Directory('$base/${MediaPaths.appFolder}/$serviceFolder');
    try {
      await dir.create(recursive: true);
      return dir.path;
    } on FileSystemException catch (e) {
      logDebug('Cannot create ${dir.path}: ${e.message}');
      return base;
    }
  }
}
