import 'package:flutter/material.dart';
import 'dart:async';
import '../core/storage/local_journal_store.dart';
import '../core/experience/journal_experience.dart';

import '../core/theme/app_theme.dart';
import '../models/journal_entry.dart';
import '../models/user_profile.dart';
import '../screens/home_screen.dart';
import '../screens/onboarding_screen.dart';

class JournalApp extends StatefulWidget {
  const JournalApp({super.key, this.store, this.persist = true});
  final LocalJournalStore? store;
  final bool persist;

  @override
  State<JournalApp> createState() => _JournalAppState();
}

class _JournalAppState extends State<JournalApp> with WidgetsBindingObserver {
  LocalJournalStore? _store;
  bool _ready = false;
  Object? _loadError;
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.persist) {
      unawaited(_load());
    } else {
      _ready = true;
    }
  }

  Future<void> _load() async {
    try {
      _store = widget.store ?? await LocalJournalStore.open();
      final saved = await _store!.load();
      if (!mounted) return;
      _entries
        ..clear()
        ..addAll(saved.entries);
      _profile = saved.profile;
      _themeMode = ThemeMode.values.byName(
        saved.settings['theme'] as String? ?? 'system',
      );
      _accent = saved.settings['accent'] == null
          ? JournalAccent.indigo
          : JournalAccent.fromJson(
              Map<String, dynamic>.from(saved.settings['accent']),
            );
      _showOnboarding = saved.settings['onboardingComplete'] != true;
      _experience.restore(saved.experience, saved.settings);
      _experience.addListener(_save);
      setState(() {
        _ready = true;
        _loadError = null;
      });
    } catch (error) {
      if (mounted) setState(() => _loadError = error);
    }
  }

  Future<void> _write() async {
    if (!_ready || _store == null) return;
    await _store!.save(
      entries: List.of(_entries),
      profile: _profile,
      preferences: {
        'theme': _themeMode.name,
        'accent': _accent.toJson(),
        'onboardingComplete': !_showOnboarding,
        'viewMode': _experience.viewMode.name,
        'preferences': _experience.preferences.toJson(),
      },
      experience: _experience.toJson(),
    );
  }

  void _save() {
    unawaited(
      _write().catchError((Object error) {
        if (mounted) {
          _messenger.currentState?.showSnackBar(
            SnackBar(
              content: const Text(
                'Could not save to this device. Please retry.',
              ),
              action: SnackBarAction(label: 'Retry', onPressed: _save),
            ),
          );
        }
      }),
    );
  }

  Future<void> _commitEntry(JournalEntry entry) async {
    final previous = _entries.where((e) => e.id == entry.id).firstOrNull;
    setState(() {
      final index = _entries.indexWhere((e) => e.id == entry.id);
      if (index < 0) {
        _entries.insert(0, entry);
      } else {
        _entries[index] = entry;
      }
    });
    try {
      await _write();
    } catch (_) {
      if (mounted) {
        setState(() {
          final index = _entries.indexWhere((e) => identical(e, entry));
          if (index >= 0) {
            if (previous == null) {
              _entries.removeAt(index);
            } else {
              _entries[index] = previous;
            }
          }
        });
      }
      rethrow;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _save();
    }
  }

  final _experience = JournalExperience();
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _experience.removeListener(_save);
    _experience.dispose();
    super.dispose();
  }

  ThemeMode _themeMode = ThemeMode.system;
  JournalAccent _accent = JournalAccent.indigo;
  bool _showOnboarding = true;
  int _sessionGeneration = 0;
  void _clearSession() {
    setState(() {
      _entries.clear();
      _profile = const UserProfile();
      _themeMode = ThemeMode.system;
      _accent = JournalAccent.indigo;
      _sessionGeneration++;
    });
    _experience.reset();
    if (_store != null) {
      unawaited(
        _store!.purgeClearedMedia().catchError((Object error) {
          if (mounted) {
            _messenger.currentState?.showSnackBar(
              const SnackBar(
                content: Text(
                  'Could not remove saved media. Please retry clearing.',
                ),
              ),
            );
          }
        }),
      );
    }
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  UserProfile _profile = const UserProfile();

  // Seeded once when the persisted journal file does not exist.
  final List<JournalEntry> _entries = List<JournalEntry>.from(sampleEntries);

  @override
  Widget build(BuildContext context) {
    return ExperienceScope(
      experience: _experience,
      child: MaterialApp(
        scaffoldMessengerKey: _messenger,
        debugShowCheckedModeBanner: false,
        title: 'Mindful Journal',
        theme: AppTheme.themed(Brightness.light, _accent),
        darkTheme: AppTheme.themed(Brightness.dark, _accent),
        themeAnimationDuration: const Duration(milliseconds: 300),
        themeMode: _themeMode,
        home: !_ready
            ? Scaffold(
                body: Center(
                  child: _loadError == null
                      ? const CircularProgressIndicator()
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Could not load your saved journal.'),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                setState(() => _loadError = null);
                                unawaited(_load());
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                ),
              )
            : _showOnboarding
            ? OnboardingScreen(
                onGetStarted: () {
                  setState(() => _showOnboarding = false);
                  _save();
                },
              )
            : JournalShell(
                key: ValueKey(_sessionGeneration),
                onClearSession: _clearSession,
                onEntryCommitted: widget.persist ? _commitEntry : null,
                entries: _entries,
                profile: _profile,
                accent: _accent,
                onAccentChanged: (accent) {
                  setState(() => _accent = accent);
                  _save();
                },
                onProfileChanged: (profile) {
                  setState(() => _profile = profile);
                  _save();
                },
                themeMode: _themeMode,
                onThemeModeChanged: (mode) {
                  setState(() => _themeMode = mode);
                  _save();
                },
                onEntrySaved: (entry) {
                  setState(() {
                    final index = _entries.indexWhere(
                      (item) => item.id == entry.id,
                    );
                    if (index == -1) {
                      _entries.insert(0, entry);
                    } else {
                      _entries[index] = entry;
                    }
                  });
                  _save();
                },
                onEntryDeleted: (id) {
                  setState(
                    () => _entries.removeWhere((entry) => entry.id == id),
                  );
                  _save();
                },
              ),
      ),
    );
  }
}
