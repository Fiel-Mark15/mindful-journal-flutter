import 'dart:typed_data';

class UserProfile {
  const UserProfile({
    this.displayName = 'John Doe',
    this.tagline = 'Reflect. Grow. Become.',
    this.photo,
    this.photoPath,
  });
  final String? photoPath;
  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'tagline': tagline,
    'photoPath': photoPath,
  };
  factory UserProfile.fromJson(Map<String, dynamic> j, {Uint8List? photo}) =>
      UserProfile(
        displayName: j['displayName'] as String? ?? 'John Doe',
        tagline: j['tagline'] as String? ?? 'Reflect. Grow. Become.',
        photoPath: j['photoPath'] as String?,
        photo: photo,
      );
  final String displayName;
  final String tagline;
  final Uint8List? photo;
  String get greetingName => displayName.trim().split(RegExp(r'\s+')).first;
}
