import 'package:flutter/material.dart';
import 'package:sprouts_manager/core/domain_enums.dart';

class EventCategoryPalette {
  final Color primary;
  final Color background;
  final IconData icon;

  const EventCategoryPalette({
    required this.primary,
    required this.background,
    required this.icon,
  });
}

extension EventCategoryUi on EventCategory {
  EventCategoryPalette get palette {
    switch (this) {
      case EventCategory.party:
        return const EventCategoryPalette(
          primary: Color(0xFF8B008B),
          background: Color(0xFF350045),
          icon: Icons.nightlife,
        );
      case EventCategory.concert:
        return const EventCategoryPalette(
          primary: Color(0xFF00008B),
          background: Color(0xFF001F70),
          icon: Icons.music_note,
        );
      case EventCategory.special:
        return const EventCategoryPalette(
          primary: Color(0xFF008000),
          background: Color(0xFF005000),
          icon: Icons.auto_awesome,
        );
      case EventCategory.movie:
        return const EventCategoryPalette(
          primary: Color(0xFFFF0000),
          background: Color(0xFF720000),
          icon: Icons.movie,
        );
      case EventCategory.kids:
        return const EventCategoryPalette(
          primary: Color(0xFF3EB489),
          background: Color(0xFF7A5200),
          icon: Icons.toys,
        );
    }
  }

  Color get color => palette.primary;
  Color get darkColor => palette.background;
  IconData get icon => palette.icon;

  Widget toChip({bool filled = true}) {
    return Chip(
      avatar: Icon(icon, size: 16, color: filled ? Colors.white : color),
      backgroundColor: filled ? color : darkColor.withValues(alpha: 0.14),
      side: BorderSide(color: color),
      label: Text(
        label,
        style: TextStyle(color: filled ? Colors.white : color),
      ),
    );
  }

  Widget toDropdownItem() {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}
