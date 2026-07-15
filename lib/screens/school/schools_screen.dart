import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drivio/config/app_config.dart';
import 'package:drivio/models/school_model.dart';
import 'package:drivio/providers/schools_provider.dart';
import 'package:drivio/theme/app_theme.dart';
import 'package:drivio/widgets/school/school_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SchoolsScreen extends ConsumerStatefulWidget {
  const SchoolsScreen({super.key});

  @override
  ConsumerState<SchoolsScreen> createState() => _SchoolsScreenState();
}

class _SchoolsScreenState extends ConsumerState<SchoolsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCity = AppConfig.defaultCity;

  @override
  void initState() {
    super.initState();
    _loadCity();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  Future<void> _loadCity() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _selectedCity =
            prefs.getString('selectedCity') ?? AppConfig.defaultCity;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SchoolModel> _filter(List<SchoolModel> schools) {
    if (_searchQuery.isEmpty) return schools;
    return schools
        .where((s) => s.name.toLowerCase().contains(_searchQuery))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final schoolsAsync = ref.watch(schoolsProvider(_selectedCity));

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('Szkoły jazdy'),
        backgroundColor: AppTheme.bgDark,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Szukaj szkoły jazdy...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.textSecondary,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: schoolsAsync.when(
              data: (schools) {
                final filtered = _filter(schools);
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.school_outlined,
                          color: AppTheme.textSecondary,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Nie znaleziono szkoły'
                              : 'Brak szkół w bazie',
                          style: GoogleFonts.poppins(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => SchoolCard(school: filtered[i]),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Błąd ładowania szkół',
                  style: GoogleFonts.poppins(color: AppTheme.textSecondary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
