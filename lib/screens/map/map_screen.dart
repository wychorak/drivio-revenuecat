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

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  // ignore: unused_field
  GoogleMapController? _mapController;
  int _currentIndex = 0;
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
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
    setState(() => _currentIndex = index);
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
    final trapsAsync = ref.watch(trapsProvider(_selectedCity));
    final schoolsAsync = ref.watch(schoolsProvider(_selectedCity));
    final isPremium = ref.watch(isPremiumProvider);
    final remainingAsync = ref.watch(remainingViewsProvider);

    final traps = trapsAsync.value ?? [];
    final schools = schoolsAsync.value ?? [];
    final markers = _buildMarkers(traps, schools);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
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
            style: _darkMapStyle,
          ),
          // Top bar with menu icon
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Builder(
                    builder: (ctx) => GestureDetector(
                      onTap: () => Scaffold.of(ctx).openDrawer(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.dividerColor),
                        ),
                        child: const Icon(
                          Icons.menu_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.dividerColor),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.location_city_rounded,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedCity,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Remaining views chip
          if (!isPremium)
            Positioned(
              bottom: 90,
              left: 0,
              right: 0,
              child: Center(
                child: remainingAsync.when(
                  data: (remaining) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.remove_red_eye_outlined,
                          color: AppTheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pozostało $remaining pułapek dziś',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final authState = ref.read(authStateProvider);
          final devLogin = ref.read(devLoginProvider);
          if (authState.value == null && !devLogin) {
            context.push('/login');
          } else {
            context.push('/trap/add');
          }
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PremiumAwareBannerAd(),
          BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onNavTap,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined),
                activeIcon: Icon(Icons.map),
                label: 'Mapa',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.school_outlined),
                activeIcon: Icon(Icons.school),
                label: 'Szkoły',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_outlined),
                activeIcon: Icon(Icons.assignment),
                label: 'Egzamin',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final isAdmin = ref.watch(adminAccessProvider).value?.isAdmin ?? false;
    return Drawer(
      backgroundColor: AppTheme.bgCard,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE30613), Color(0xFFB00010)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withAlpha(60),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.directions_car_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
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
                ],
              ),
            ),
            const Divider(color: AppTheme.dividerColor),
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
            const Divider(color: AppTheme.dividerColor),
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
            const Spacer(),
            const Divider(color: AppTheme.dividerColor),
            _drawerItem(
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = AppTheme.textSecondary,
    Color titleColor = Colors.white,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: titleColor,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      horizontalTitleGap: 8,
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

class _TrapBottomSheet extends StatelessWidget {
  final TrapModel trap;
  final VoidCallback onDetails;

  const _TrapBottomSheet({required this.trap, required this.onDetails});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
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
                  color: AppTheme.bgDark,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: AppTheme.textSecondary,
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
                  color: AppTheme.bgDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trap.city,
                  style: GoogleFonts.poppins(
                    color: AppTheme.textSecondary,
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
              color: Colors.white,
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
              color: AppTheme.textSecondary,
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
