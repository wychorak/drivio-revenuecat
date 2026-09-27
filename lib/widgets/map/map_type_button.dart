import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drivio/theme/app_theme.dart';

/// Map styles offered to users, in the order shown in the picker.
const mapTypeOptions = <MapType, ({String label, IconData icon})>{
  MapType.normal: (label: 'Standardowa', icon: Icons.map_outlined),
  MapType.satellite: (label: 'Satelitarna', icon: Icons.satellite_alt_rounded),
  MapType.hybrid: (label: 'Hybrydowa', icon: Icons.layers_rounded),
  MapType.terrain: (label: 'Terenowa', icon: Icons.terrain_rounded),
};

const _prefsKey = 'map.type';

/// Remembers the last map style between app launches.
class MapTypePreference {
  static Future<MapType> load() async {
    try {
      final name = (await SharedPreferences.getInstance()).getString(_prefsKey);
      return MapType.values.firstWhere(
        (type) => type.name == name && mapTypeOptions.containsKey(type),
        orElse: () => MapType.normal,
      );
    } catch (_) {
      return MapType.normal;
    }
  }

  static Future<void> save(MapType type) async {
    try {
      await (await SharedPreferences.getInstance()).setString(
        _prefsKey,
        type.name,
      );
    } catch (_) {
      // The choice still applies for this session.
    }
  }
}

/// Round floating button that opens the map style picker.
class MapTypeButton extends StatelessWidget {
  const MapTypeButton({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final MapType value;
  final ValueChanged<MapType> onChanged;

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<MapType>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => _MapTypeSheet(selected: value),
    );
    if (picked != null && picked != value) {
      onChanged(picked);
      await MapTypePreference.save(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black38,
      child: IconButton(
        tooltip: 'Typ mapy',
        onPressed: () => _open(context),
        icon: Icon(Icons.layers_rounded, color: colors.onSurface),
      ),
    );
  }
}

class _MapTypeSheet extends StatelessWidget {
  const _MapTypeSheet({required this.selected});

  final MapType selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Typ mapy',
              style: GoogleFonts.poppins(
                color: colors.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              crossAxisSpacing: 10,
              childAspectRatio: 0.82,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final entry in mapTypeOptions.entries)
                  _MapTypeTile(
                    label: entry.value.label,
                    icon: entry.value.icon,
                    selected: entry.key == selected,
                    onTap: () => Navigator.pop(context, entry.key),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MapTypeTile extends StatelessWidget {
  const _MapTypeTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 56,
              width: double.infinity,
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.primary.withAlpha(28)
                    : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? AppTheme.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                color: selected ? AppTheme.primary : colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: selected ? AppTheme.primary : colors.onSurface,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
