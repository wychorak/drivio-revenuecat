import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:drivio/config/app_config.dart';
import 'package:drivio/models/school_model.dart';
import 'package:drivio/providers/user_provider.dart';
import 'package:drivio/services/admin_access_service.dart';
import 'package:drivio/theme/app_theme.dart';

class AdminSchoolFormScreen extends ConsumerStatefulWidget {
  final String? schoolId;

  const AdminSchoolFormScreen({super.key, this.schoolId});

  @override
  ConsumerState<AdminSchoolFormScreen> createState() =>
      _AdminSchoolFormScreenState();
}

class _AdminSchoolFormScreenState extends ConsumerState<AdminSchoolFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _description = TextEditingController();
  final _city = TextEditingController(text: AppConfig.defaultCity);
  final _priceFrom = TextEditingController();
  final _priceTo = TextEditingController();
  final _phone = TextEditingController();
  final _website = TextEditingController();
  LatLng _position = const LatLng(
    AppConfig.szczecin_lat,
    AppConfig.szczecin_lng,
  );
  bool _loading = false;
  bool _initializing = false;
  SchoolModel? _original;

  bool get _editing => widget.schoolId != null;

  @override
  void initState() {
    super.initState();
    if (_editing) _loadSchool();
  }

  Future<void> _loadSchool() async {
    setState(() => _initializing = true);
    try {
      final school = await ref
          .read(firestoreServiceProvider)
          .getSchoolById(widget.schoolId!);
      if (!mounted || school == null) return;
      _original = school;
      _name.text = school.name;
      _address.text = school.address;
      _description.text = school.description;
      _city.text = school.city;
      _priceFrom.text = school.priceFrom.toStringAsFixed(0);
      _priceTo.text = school.priceTo.toStringAsFixed(0);
      _phone.text = school.phone ?? '';
      _website.text = school.website ?? '';
      setState(() => _position = LatLng(school.lat, school.lng));
    } finally {
      if (mounted) setState(() => _initializing = false);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _address,
      _description,
      _city,
      _priceFrom,
      _priceTo,
      _phone,
      _website,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'To pole jest wymagane' : null;

  String? _price(String? value) {
    final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));
    return parsed == null || parsed < 0 ? 'Podaj poprawną cenę' : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final access = await ref.read(adminAccessProvider.future);
    if (!access.isAdmin || !mounted) return;

    final from = double.parse(_priceFrom.text.replaceAll(',', '.'));
    final to = double.parse(_priceTo.text.replaceAll(',', '.'));
    if (to < from) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cena maksymalna nie może być niższa od minimalnej.'),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final school = SchoolModel(
        id: widget.schoolId ?? '',
        name: _name.text.trim(),
        logoUrl: _original?.logoUrl,
        rating: _original?.rating ?? 0,
        reviewCount: _original?.reviewCount ?? 0,
        priceFrom: from,
        priceTo: to,
        address: _address.text.trim(),
        description: _description.text.trim(),
        city: _city.text.trim(),
        lat: _position.latitude,
        lng: _position.longitude,
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        website: _website.text.trim().isEmpty ? null : _website.text.trim(),
      );
      final service = ref.read(firestoreServiceProvider);
      if (_editing) {
        await service.updateSchool(widget.schoolId!, school);
      } else {
        await service.addSchool(school);
      }
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nie udało się zapisać szkoły.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(adminAccessProvider);
    if (access.isLoading || _initializing) {
      return const Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (access.value?.isAdmin != true) {
      return const Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Center(
          child: Text(
            'Brak uprawnień administratora.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text(_editing ? 'Edytuj szkołę' : 'Dodaj szkołę'),
        backgroundColor: AppTheme.bgDark,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _field(_name, 'Nazwa szkoły', validator: _required),
            _field(_city, 'Miasto', validator: _required),
            _field(_address, 'Adres', validator: _required),
            _field(_description, 'Opis', validator: _required, maxLines: 4),
            Row(
              children: [
                Expanded(
                  child: _field(
                    _priceFrom,
                    'Cena od',
                    validator: _price,
                    number: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    _priceTo,
                    'Cena do',
                    validator: _price,
                    number: true,
                  ),
                ),
              ],
            ),
            _field(_phone, 'Telefon (opcjonalnie)'),
            _field(_website, 'Strona WWW (opcjonalnie)'),
            const Text(
              'Położenie pinezki',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 260,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _position,
                    zoom: 14,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('school'),
                      position: _position,
                      draggable: true,
                      onDragEnd: (value) => setState(() => _position = value),
                    ),
                  },
                  onTap: (value) => setState(() => _position = value),
                  zoomControlsEnabled: false,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_editing ? 'Zapisz zmiany' : 'Dodaj szkołę'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    int maxLines = 1,
    bool number = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : null,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(labelText: label),
        validator: validator,
      ),
    );
  }
}
