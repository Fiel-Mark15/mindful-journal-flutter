import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.profile, this.size = 48});
  final UserProfile profile;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Theme.of(context).colorScheme.primaryContainer,
    ),
    clipBehavior: Clip.antiAlias,
    child: profile.photo == null
        ? Icon(
            CupertinoIcons.person_fill,
            size: size * .42,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          )
        : Image.memory(
            profile.photo!,
            fit: BoxFit.cover,
            errorBuilder: (_, error, stack) =>
                const Icon(CupertinoIcons.person_fill),
          ),
  );
}
