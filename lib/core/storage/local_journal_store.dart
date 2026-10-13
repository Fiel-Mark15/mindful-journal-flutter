import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/journal_entry.dart';
import '../../models/journal_attachment.dart';
import '../../models/user_profile.dart';

abstract class SettingsStorage {
  Future<String?> read();
  Future<void> write(String value);
}

class DeviceSettingsStorage implements SettingsStorage {
  final _preferences = SharedPreferencesAsync();
  static const key = 'mindful_journal.settings.v1';
  @override
  Future<String?> read() => _preferences.getString(key);
  @override
  Future<void> write(String value) => _preferences.setString(key, value);
}

class StoredJournal {
  StoredJournal(this.entries, this.profile, this.settings, this.experience);
  final List<JournalEntry> entries;
  final UserProfile profile;
  final Map<String, dynamic> settings, experience;
}

class LocalJournalStore {
  LocalJournalStore({required this.directory, required this.settings});
  final Directory directory;
  final SettingsStorage settings;
  final _mediaPaths = Map<Uint8List, String>.identity();
  Future<void> _tail = Future.value();
  int _sequence = 0;
  static Future<LocalJournalStore> open() async => LocalJournalStore(
    directory: Directory(
      '${(await getApplicationDocumentsDirectory()).path}/mindful_journal',
    ),
    settings: DeviceSettingsStorage(),
  );
  File get _journal => File('${directory.path}/journal.json');
  Future<Uint8List> _readMedia(String path) async {
    if (!RegExp(r'^media/[a-zA-Z0-9_.-]+\.png$').hasMatch(path)) {
      throw const FormatException('Invalid saved media path.');
    }
    final bytes = await File('${directory.path}/$path').readAsBytes();
    _mediaPaths[bytes] = path;
    return bytes;
  }

  Future<StoredJournal> load() async {
    await directory.create(recursive: true);
    Map<String, dynamic> data;
    final backup = File('${_journal.path}.bak');
    if (!await _journal.exists() && !await backup.exists()) {
      data = {
        'version': 1,
        'entries': sampleEntries.map((e) => e.toJson()).toList(),
      };
      await _atomic(
        data,
      ); // Seed only once; an intentionally empty saved list stays empty.
    } else {
      try {
        data = await _decode(_journal);
      } catch (_) {
        if (!await backup.exists()) rethrow;
        data = await _decode(backup);
      }
    }
    final raw = await settings.read();
    final prefs = raw == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(raw));
    final records = <JournalEntry>[];
    for (final value in data['entries'] as List) {
      final j = Map<String, dynamic>.from(value);
      final attachments = <JournalAttachment>[];
      for (final a in j['attachments'] as List? ?? []) {
        final json = Map<String, dynamic>.from(a);
        attachments.add(
          JournalAttachment.fromJson(
            json,
            bytes: await _readMedia(json['filePath'] as String),
          ),
        );
      }
      records.add(JournalEntry.fromJson(j, attachments: attachments));
    }
    final profileJson = Map<String, dynamic>.from(prefs['profile'] ?? {});
    final path = profileJson['photoPath'] as String?;
    return StoredJournal(
      records,
      UserProfile.fromJson(
        profileJson,
        photo: path == null ? null : await _readMedia(path),
      ),
      prefs,
      data,
    );
  }

  Future<Map<String, dynamic>> _decode(File file) async {
    final data = Map<String, dynamic>.from(
      jsonDecode(await file.readAsString()),
    );
    if (data['version'] != 1 || data['entries'] is! List) {
      throw const FormatException('Unsupported or damaged saved journal.');
    }
    return data;
  }

  Future<String> _media(Uint8List bytes) async {
    final existing = _mediaPaths[bytes];
    if (existing != null &&
        await File('${directory.path}/$existing').exists()) {
      return existing;
    }
    final path =
        'media/${DateTime.now().microsecondsSinceEpoch}_${_sequence++}.png';
    final file = File('${directory.path}/$path');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    _mediaPaths[bytes] = path;
    return path;
  }

  Future<void> _atomic(Map<String, dynamic> data) async {
    await directory.create(recursive: true);
    final temporary = File('${_journal.path}.tmp');
    await temporary.writeAsString(jsonEncode(data), flush: true);
    if (await _journal.exists()) {
      try {
        await _decode(_journal);
        await _journal.copy('${_journal.path}.bak');
      } on FormatException {
        /* Keep the last valid backup on recovery. */
      }
    }
    await temporary.rename(_journal.path);
  }

  // Capture JSON before queuing so later mutations cannot overwrite an earlier
  // revision. Serial writes prevent rapid edits, favorites or task toggles racing.
  Future<void> save({
    required List<JournalEntry> entries,
    required UserProfile profile,
    required Map<String, dynamic> preferences,
    required Map<String, dynamic> experience,
  }) {
    final data =
        jsonDecode(
              jsonEncode({
                'version': 1,
                ...experience,
                'entries': entries.map((e) => e.toJson()).toList(),
              }),
            )
            as Map<String, dynamic>;
    final prefs =
        jsonDecode(jsonEncode({...preferences, 'profile': profile.toJson()}))
            as Map<String, dynamic>;
    final images = [
      for (final entry in entries) [for (final a in entry.attachments) a.bytes],
    ];
    final photo = profile.photo;
    final operation = _tail.then((_) async {
      for (var i = 0; i < images.length; i++) {
        for (var a = 0; a < images[i].length; a++) {
          data['entries'][i]['attachments'][a]['filePath'] = await _media(
            images[i][a],
          );
        }
      }
      prefs['profile']['photoPath'] = photo == null
          ? null
          : await _media(photo);
      await _atomic(data);
      await settings.write(jsonEncode(prefs));
    });
    _tail = operation.then(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return operation;
  }

  Future<void> purgeClearedMedia() {
    final operation = _tail.then((_) async {
      final saved = await _decode(_journal);
      final raw = await settings.read();
      final prefs = raw == null ? {} : jsonDecode(raw);
      if ((saved['entries'] as List).isNotEmpty ||
          (saved['tasks'] as List? ?? []).isNotEmpty ||
          prefs['profile']?['photoPath'] != null) {
        throw const FileSystemException(
          'Clear must be saved before removing media.',
        );
      }
      final backup = File('${_journal.path}.bak');
      if (await backup.exists()) await backup.delete();
      final media = Directory('${directory.path}/media');
      if (await media.exists()) await media.delete(recursive: true);
      _mediaPaths.clear();
    });
    _tail = operation.then(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return operation;
  }

  Future<void> flush() => _tail;
}
