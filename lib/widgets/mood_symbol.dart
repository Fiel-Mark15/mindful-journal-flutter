import 'package:flutter/cupertino.dart';
import '../models/journal_entry.dart';

/// Weather symbols keep mood rendering consistent without relying on emoji fonts.
class MoodSymbol extends StatelessWidget {
  const MoodSymbol({super.key, required this.mood, this.size = 26, this.color});
  final Mood mood;
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) => Icon(
    switch (mood) {
      Mood.great => CupertinoIcons.sun_max,
      Mood.good => CupertinoIcons.cloud_sun,
      Mood.okay => CupertinoIcons.cloud,
      Mood.bad => CupertinoIcons.cloud_drizzle,
      Mood.sad => CupertinoIcons.cloud_rain,
    },
    size: size,
    color: color,
  );
}
