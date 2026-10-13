import 'dart:typed_data';
import '../core/media/image_import.dart';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../widgets/profile_avatar.dart';

Future<Uint8List?> chooseProfilePhoto() => chooseJournalImage();

Future<UserProfile?> editProfile(BuildContext context, UserProfile profile) {
  if (MediaQuery.sizeOf(context).width >= 700) {
    return showDialog<UserProfile>(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ProfileEditorSheet(profile: profile),
        ),
      ),
    );
  }
  return showModalBottomSheet<UserProfile>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ProfileEditorSheet(profile: profile),
  );
}

class ProfileEditorSheet extends StatefulWidget {
  const ProfileEditorSheet({
    super.key,
    required this.profile,
    this.pickPhoto = chooseProfilePhoto,
  });
  final UserProfile profile;
  final Future<Uint8List?> Function() pickPhoto;
  @override
  State<ProfileEditorSheet> createState() => _ProfileEditorSheetState();
}

class _ProfileEditorSheetState extends State<ProfileEditorSheet> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _tagline;
  Uint8List? _photo;
  String? _error;
  bool _picking = false;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.displayName);
    _tagline = TextEditingController(text: widget.profile.tagline);
    _photo = widget.profile.photo;
  }

  @override
  void dispose() {
    _name.dispose();
    _tagline.dispose();
    super.dispose();
  }

  Future<void> _choose() async {
    if (_picking) return;
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final photo = await widget.pickPhoto();
      if (mounted && photo != null) setState(() => _photo = photo);
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Photo selection is unavailable or access was denied. Try another image.',
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Make it yours',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            ProfileAvatar(profile: UserProfile(photo: _photo), size: 96),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: _picking ? null : _choose,
                  child: Text(_picking ? 'Opening picker…' : 'Choose photo'),
                ),
                TextButton(
                  onPressed: _photo == null || _picking
                      ? null
                      : () => setState(() => _photo = null),
                  child: const Text('Use default avatar'),
                ),
              ],
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('profile-name'),
              controller: _name,
              maxLength: 30,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Display name'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Please enter your name.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('profile-tagline'),
              controller: _tagline,
              maxLength: 100,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Journal tagline (optional)',
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: _picking
                      ? null
                      : () {
                          if (_form.currentState!.validate()) {
                            Navigator.pop(
                              context,
                              UserProfile(
                                displayName: _name.text.trim(),
                                tagline: _tagline.text.trim(),
                                photo: _photo,
                              ),
                            );
                          }
                        },
                  child: const Text('Save profile'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Profile changes stay in this session.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}
