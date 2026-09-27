import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:drivio/theme/app_theme.dart';
import 'package:drivio/widgets/map/map_type_button.dart';

String formatLatLng(LatLng position) =>
    '${position.latitude.toStringAsFixed(6)}, '
    '${position.longitude.toStringAsFixed(6)}';

/// Static map preview for forms. A map inside a scrolling form fights the
/// scroll gesture, so the preview ignores touches and opens
/// [LocationPickerScreen] for the actual choice.
class LocationPreview extends StatelessWidget {
  const LocationPreview({
    super.key,
    required this.position,
    required this.onChanged,
    this.title = 'Wybierz lokalizację',
    this.height = 200,
  });

  final LatLng position;
  final ValueChanged<LatLng> onChanged;
  final String title;
  final double height;

  Future<void> _open(BuildContext context) async {
    final picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => LocationPickerScreen(initial: position, title: title),
      ),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: 'Zmień lokalizację na mapie',
          child: GestureDetector(
            onTap: () => _open(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: height,
                child: Stack(
                  children: [
                    IgnorePointer(
                      child: GoogleMap(
                        // Rebuilt with the new camera whenever the pin moves.
                        key: ValueKey(position),
                        initialCameraPosition: CameraPosition(
                          target: position,
                          zoom: 16,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('preview'),
                            position: position,
                          ),
                        },
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                        mapToolbarEnabled: false,
                        compassEnabled: false,
                      ),
                    ),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: FilledButton.icon(
                        onPressed: () => _open(context),
                        icon: const Icon(Icons.edit_location_alt_rounded),
                        label: const Text('Zmień'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.place_rounded, size: 14, color: colors.onSurfaceVariant),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                formatLatLng(position),
                style: GoogleFonts.poppins(
                  color: colors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Full-screen picker: the pin stays in the centre and the map moves under
/// it, which is far more precise than dropping a pin with a finger.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    required this.initial,
    this.title = 'Wybierz lokalizację',
  });

  final LatLng initial;
  final String title;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _controller;
  late LatLng _center = widget.initial;
  MapType _mapType = MapType.normal;
  bool _moving = false;

  @override
  void initState() {
    super.initState();
    MapTypePreference.load().then((type) {
      if (mounted) setState(() => _mapType = type);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _zoom(bool zoomIn) {
    _controller?.animateCamera(
      zoomIn ? CameraUpdate.zoomIn() : CameraUpdate.zoomOut(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.initial,
              zoom: 17,
            ),
            mapType: _mapType,
            onMapCreated: (controller) => _controller = controller,
            onCameraMoveStarted: () => setState(() => _moving = true),
            onCameraMove: (camera) => _center = camera.target,
            onCameraIdle: () => setState(() => _moving = false),
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
          ),
          // Fixed centre pin; its tip marks the chosen point.
          IgnorePointer(
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, -22),
                child: AnimatedScale(
                  scale: _moving ? 1.12 : 1,
                  duration: const Duration(milliseconds: 150),
                  child: const Icon(
                    Icons.location_on_rounded,
                    size: 48,
                    color: AppTheme.primary,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black45)],
                  ),
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: Column(
              children: [
                MapTypeButton(
                  value: _mapType,
                  onChanged: (type) => setState(() => _mapType = type),
                ),
                const SizedBox(height: 12),
                _RoundButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Przybliż',
                  onTap: () => _zoom(true),
                ),
                const SizedBox(height: 8),
                _RoundButton(
                  icon: Icons.remove_rounded,
                  tooltip: 'Oddal',
                  onTap: () => _zoom(false),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(blurRadius: 16, color: Colors.black26),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Przesuń mapę, aby ustawić pinezkę dokładnie w miejscu. '
                      'Przybliż, żeby trafić precyzyjnie.',
                      style: GoogleFonts.poppins(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatLatLng(_center),
                      style: GoogleFonts.poppins(
                        color: colors.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _moving
                          ? null
                          : () => Navigator.pop(context, _center),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Zatwierdź lokalizację'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black38,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon, color: colors.onSurface),
      ),
    );
  }
}
