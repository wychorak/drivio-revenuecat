import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drivio/config/app_config.dart';
import 'package:drivio/models/trap_model.dart';
import 'package:drivio/models/school_model.dart';
import 'package:drivio/providers/auth_provider.dart';
import 'package:drivio/providers/traps_provider.dart';
import 'package:drivio/providers/schools_provider.dart';
import 'package:drivio/providers/user_provider.dart';
import 'package:drivio/theme/app_theme.dart';
import 'package:drivio/widgets/trap/difficulty_stars.dart';
import 'package:drivio/widgets/ads/premium_aware_banner_ad.dart';
import 'package:drivio/services/admin_access_service.dart';
import 'package:drivio/services/ad_service.dart';
import 'package:drivio/widgets/common/drivio_brand.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  // ignore: unused_field
  GoogleMapController? _mapController;
  String _selectedCity = AppConfig.defaultCity;

  @override
  void initState() {
    super.initState();
    _loadCity();
  }

  Future<void> _loadCity() async {
    final prefs = await SharedPreferences.getInstance();
    final city = prefs.getString('selectedCity') ?? AppConfig.defaultCity;
    if (mounted) setState(() => _selectedCity = city);
  }

  Set<Marker> _buildMarkers(List<TrapModel> traps, List<SchoolModel> schools) {
    final markers = <Marker>{};

    for (final trap in traps) {
      markers.add(
        Marker(
          markerId: MarkerId('trap_${trap.id}'),
          position: LatLng(trap.lat, trap.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: trap.title),
          onTap: () => _showTrapBottomSheet(trap),
        ),
      );
    }

    for (final school in schools) {
      markers.add(
        Marker(
          markerId: MarkerId('school_${school.id}'),
          position: LatLng(school.lat, school.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(title: school.name),
          onTap: () => context.push('/school/${school.id}'),
        ),
      );
    }

    return markers;
  }

  void _showTrapBottomSheet(TrapModel trap) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _TrapBottomSheet(
        trap: trap,
        onDetails: () async {
          Navigator.pop(ctx);
          final authState = ref.read(authStateProvider);
          final user = authState.value;
          if (user == null && !ref.read(devLoginProvider)) {
            context.push('/login');
            return;
          }
          if (mounted) context.push('/trap/${trap.id}');
        },
      ),
    );
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        break;
      case 1:
        context.push('/schools');
      case 2:
        context.push('/exam');
      case 3:
        context.push('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final trapsAsync = ref.watch(trapsProvider(_selectedCity));
    final schoolsAsync = ref.watch(schoolsProvider(_selectedCity));
    final isPremium = ref.watch(isPremiumProvider);
    final isAdmin = ref.watch(adminAccessProvider).value?.isAdmin ?? false;
    final remainingAsync = ref.watch(remainingViewsProvider);

    final traps = trapsAsync.value ?? [];
    final schools = schoolsAsync.value ?? [];
    final markers = _buildMarkers(traps, schools);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(AppConfig.szczecin_lat, AppConfig.szczecin_lng),
              zoom: 13,
            ),
            onMapCreated: (ctrl) => _mapController = ctrl,
            markers: markers,
            mapType: MapType.normal,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            style: isDark ? _darkMapStyle : null,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(
                children: [
                  Builder(
                    builder: (ctx) => _MapActionButton(
                      icon: Icons.menu_rounded,
                      tooltip: 'Otwórz menu',
                      onTap: () => Scaffold.of(ctx).openDrawer(),
                      colors: colors,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: colors.surface.withAlpha(245),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: colors.outline.withAlpha(160),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x26000000),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withAlpha(22),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: AppTheme.primary,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mapa egzaminacyjna',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    color: colors.onSurface,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  _selectedCity,
                                  style: GoogleFonts.poppins(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: colors.onSurfaceVariant,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 76,
            left: 12,
            child: Row(
              children: [
                _MapPill(
                  icon: Icons.warning_amber_rounded,
                  label: '${traps.length} pułapek',
                  color: AppTheme.primary,
                  colors: colors,
                ),
                const SizedBox(width: 8),
                _MapPill(
                  icon: Icons.school_rounded,
                  label: '${schools.length} szkół',
                  color: AppTheme.successColor,
                  colors: colors,
                ),
              ],
            ),
          ),
          if (!isPremium)
            Positioned(
              bottom: 82,
              left: 0,
              right: 0,
              child: Center(
                child: remainingAsync.when(
                  data: (status) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface.withAlpha(245),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colors.outline.withAlpha(150)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x26000000),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.remove_red_eye_outlined,
                          color: AppTheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          status.freeRemaining == 1
                              ? '1 darmowa pułapka dziś'
                              : status.freeRemaining > 1
                              ? '${status.freeRemaining} darmowe pułapki dziś'
                              : status.canWatchAd &&
                                    AdService.instance.isSupported
                              ? 'Kolejna pułapka za reklamę'
                              : status.totalRemaining > 0
                              ? '1 pułapka po reklamie'
                              : 'Limit pułapek wykorzystany',
                          style: GoogleFonts.poppins(
                            color: colors.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              tooltip: 'Dodaj pułapkę',
              onPressed: () => context.push('/trap/add'),
              icon: const Icon(Icons.add_location_alt_rounded),
              label: Text(
                'Dodaj pułapkę',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PremiumAwareBannerAd(),
          NavigationBar(
            // MapScreen stays mounted below pushed destinations, therefore
            // its own destination must be selected again after returning.
            selectedIndex: 0,
            onDestinationSelected: _onNavTap,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map_rounded),
                label: 'Mapa',
              ),
              NavigationDestination(
                icon: Icon(Icons.school_outlined),
                selectedIcon: Icon(Icons.school_rounded),
                label: 'Szkoły',
              ),
              NavigationDestination(
                icon: Icon(Icons.fact_check_outlined),
                selectedIcon: Icon(Icons.fact_check_rounded),
                label: 'Egzamin',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profil',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final colors = Theme.of(context).colorScheme;
    final isAdmin = ref.watch(adminAccessProvider).value?.isAdmin ?? false;
    final isPremium = ref.watch(isPremiumProvider);
    final user = ref.watch(currentUserProvider).value;
    return Drawer(
      width: MediaQuery.sizeOf(context).width.clamp(280, 348).toDouble(),
      backgroundColor: colors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Row(
                children: [
                  const DrivioLogo(size: 48),
                  const SizedBox(width: 12),
                  Text(
                    'drivio',
                    style: GoogleFonts.poppins(
                      color: AppTheme.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'NAUKA JAZDY',
                      style: GoogleFonts.poppins(
                        color: colors.onSurfaceVariant,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .7,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (user != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/profile');
                  },
                  child: Ink(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withAlpha(150),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colors.outline.withAlpha(90)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.primary,
                          child: Text(
                            user.displayName.isEmpty
                                ? 'U'
                                : user.displayName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: colors.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                user.isGuest ? 'Tryb gościa' : user.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: colors.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (!isPremium)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/premium');
                  },
                  child: Ink(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.premiumGold.withAlpha(38),
                          AppTheme.primary.withAlpha(18),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppTheme.premiumGold.withAlpha(100),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.workspace_premium_rounded,
                          color: AppTheme.premiumGold,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Odblokuj Drivio Premium',
                                style: GoogleFonts.poppins(
                                  color: colors.onSurface,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Bez limitów i reklam',
                                style: GoogleFonts.poppins(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: AppTheme.premiumGold,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Divider(color: colors.outline.withAlpha(100), height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                children: [
                  const _DrawerSectionLabel('NAUKA I EGZAMIN'),
                  _drawerItem(
                    icon: Icons.school_outlined,
                    title: 'Wyszukaj szkołę jazdy',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/schools');
                    },
                  ),
                  _drawerItem(
                    icon: Icons.person_outline,
                    title: 'Mój profil',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/profile');
                    },
                  ),
                  _drawerItem(
                    icon: Icons.settings_outlined,
                    title: 'Ustawienia',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/settings');
                    },
                  ),
                  _drawerItem(
                    icon: Icons.assignment_outlined,
                    title: 'WORD i egzamin',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/exam');
                    },
                  ),
                  _drawerItem(
                    icon: Icons.local_parking_outlined,
                    title: 'Parkowanie',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/parking');
                    },
                  ),
                  _drawerItem(
                    icon: Icons.directions_car_outlined,
                    title: 'Samochód',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/car');
                    },
                  ),
                  const _DrawerSectionLabel('SPOŁECZNOŚĆ'),
                  if (isAdmin)
                    _drawerItem(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Moderacja',
                      iconColor: Colors.orangeAccent,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/admin');
                      },
                    ),
                  _drawerItem(
                    icon: Icons.emoji_events_outlined,
                    title: 'Pro tipy',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/pro-tips');
                    },
                  ),
                  _drawerItem(
                    icon: Icons.star_outline_rounded,
                    title: 'Premium',
                    iconColor: AppTheme.premiumGold,
                    titleColor: AppTheme.premiumGold,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/premium');
                    },
                  ),
                  _drawerItem(
                    icon: Icons.leaderboard_outlined,
                    title: 'Ranking',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/ranking');
                    },
                  ),
                  Divider(color: colors.outline.withAlpha(100)),
                  const _DrawerSectionLabel('INFORMACJE'),
                  _drawerItem(
                    icon: Icons.description_outlined,
                    title: 'Regulamin',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/terms');
                    },
                  ),
                  _drawerItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Polityka prywatności',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/privacy');
                    },
                  ),
                ],
              ),
            ),
            Divider(color: colors.outline.withAlpha(100), height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              child: _drawerItem(
                icon: Icons.logout_rounded,
                title: 'Wyloguj',
                iconColor: AppTheme.primary,
                titleColor: AppTheme.primary,
                onTap: () async {
                  Navigator.pop(context);
                  ref.read(devLoginProvider.notifier).state = false;
                  await ref.read(authServiceProvider).signOut();
                  await Future<void>.delayed(const Duration(milliseconds: 100));
                  if (mounted) context.go('/login');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: (iconColor ?? colors.onSurfaceVariant).withAlpha(18),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: iconColor ?? colors.onSurfaceVariant,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: titleColor ?? colors.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: colors.onSurfaceVariant.withAlpha(150),
          size: 19,
        ),
        onTap: onTap,
        horizontalTitleGap: 10,
      ),
    );
  }

  static const String _darkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#1d2c4d"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#8ec3b9"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#1a3646"}]},
  {"featureType": "administrative.country", "elementType": "geometry.stroke", "stylers": [{"color": "#4b6878"}]},
  {"featureType": "administrative.land_parcel", "elementType": "labels.text.fill", "stylers": [{"color": "#64779e"}]},
  {"featureType": "administrative.province", "elementType": "geometry.stroke", "stylers": [{"color": "#4b6878"}]},
  {"featureType": "landscape.man_made", "elementType": "geometry.stroke", "stylers": [{"color": "#334e87"}]},
  {"featureType": "landscape.natural", "elementType": "geometry", "stylers": [{"color": "#023e58"}]},
  {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#283d6a"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#6f9ba5"}]},
  {"featureType": "poi", "elementType": "labels.text.stroke", "stylers": [{"color": "#1d2c4d"}]},
  {"featureType": "poi.park", "elementType": "geometry.fill", "stylers": [{"color": "#023e58"}]},
  {"featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [{"color": "#3C7680"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#304a7d"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#98a5be"}]},
  {"featureType": "road", "elementType": "labels.text.stroke", "stylers": [{"color": "#1d2c4d"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#2c6675"}]},
  {"featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{"color": "#255763"}]},
  {"featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [{"color": "#b0d5ce"}]},
  {"featureType": "road.highway", "elementType": "labels.text.stroke", "stylers": [{"color": "#023e58"}]},
  {"featureType": "transit", "elementType": "labels.text.fill", "stylers": [{"color": "#98a5be"}]},
  {"featureType": "transit", "elementType": "labels.text.stroke", "stylers": [{"color": "#1d2c4d"}]},
  {"featureType": "transit.line", "elementType": "geometry.fill", "stylers": [{"color": "#283d6a"}]},
  {"featureType": "transit.station", "elementType": "geometry", "stylers": [{"color": "#3a4762"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0e1626"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#4e6d70"}]}
]
''';
}

class _MapActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final ColorScheme colors;

  const _MapActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surface.withAlpha(245),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.outline.withAlpha(160)),
      ),
      elevation: 5,
      shadowColor: Colors.black.withAlpha(80),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon, color: colors.onSurface),
        constraints: const BoxConstraints.tightFor(width: 54, height: 54),
      ),
    );
  }
}

class _MapPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final ColorScheme colors;

  const _MapPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surface.withAlpha(238),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outline.withAlpha(140)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: colors.onSurface,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerSectionLabel extends StatelessWidget {
  final String label;

  const _DrawerSectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 5),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _TrapBottomSheet extends StatelessWidget {
  final TrapModel trap;
  final VoidCallback onDetails;

  const _TrapBottomSheet({required this.trap, required this.onDetails});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          if (trap.photoUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                trap.photoUrl!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 140,
                  color: colors.surfaceContainerHighest,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          if (trap.photoUrl != null) const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primary.withAlpha(60)),
                ),
                child: Text(
                  'Pułapka',
                  style: GoogleFonts.poppins(
                    color: AppTheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trap.city,
                  style: GoogleFonts.poppins(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            trap.title,
            style: GoogleFonts.poppins(
              color: colors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          DifficultyStars(difficulty: trap.difficulty),
          const SizedBox(height: 8),
          Text(
            trap.description.length > 100
                ? '${trap.description.substring(0, 100)}...'
                : trap.description,
            style: GoogleFonts.poppins(
              color: colors.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onDetails,
              child: const Text('Zobacz szczegóły'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
