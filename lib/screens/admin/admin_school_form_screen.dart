import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:drivio/config/app_config.dart';
import 'package:drivio/models/school_model.dart';
import 'package:drivio/providers/user_provider.dart';
import 'package:drivio/services/admin_access_service.dart';
import 'package:drivio/services/storage_service.dart';
import 'package:drivio/theme/app_theme.dart';
import 'package:drivio/widgets/map/location_picker.dart';

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
  File? _pickedLogo;
  bool _logoRemoved = false;
  final _storage = StorageService();

  Future<void> _pickLogo() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 88,
      );
      if (picked != null && mounted) {
        setState(() {
          _pickedLogo = File(picked.path);
          _logoRemoved = false;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nie udało się wybrać zdjęcia.')),
        );
      }
    }
  }

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
      var logoUrl = _logoRemoved ? null : _original?.logoUrl;
      if (_pickedLogo != null) {
        logoUrl = await _storage.uploadSchoolLogo(_pickedLogo!);
      }
      final school = SchoolModel(
        id: widget.schoolId ?? '',
        name: _name.text.trim(),
        logoUrl: logoUrl,
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
    } on FormatException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (access.value?.isAdmin != true) {
      return Scaffold(
        body: Center(
          child: Text(
            'Brak uprawnień administratora.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edytuj szkołę' : 'Dodaj szkołę')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildLogoPicker(),
            const SizedBox(height: 20),
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
            Text(
              'Położenie pinezki',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            LocationPreview(
              position: _position,
              title: 'Lokalizacja szkoły',
              onChanged: (value) => setState(() => _position = value),
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

  Widget _buildLogoPicker() {
    final colors = Theme.of(context).colorScheme;
    final existingUrl = _logoRemoved ? null : _original?.logoUrl;
    final Widget? logo = _pickedLogo != null
        ? Image.file(_pickedLogo!, fit: BoxFit.cover)
        : existingUrl != null
        ? CachedNetworkImage(imageUrl: existingUrl, fit: BoxFit.cover)
        : null;
    final hasLogo = logo != null;

    return Row(
      children: [
        GestureDetector(
          onTap: _loading ? null : _pickLogo,
          child: Container(
            width: 88,
            height: 88,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.outlineVariant),
            ),
            child:
                logo ??
                Icon(
                  Icons.add_photo_alternate_outlined,
                  color: colors.onSurfaceVariant,
                  size: 32,
                ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Logo szkoły',
                style: TextStyle(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'JPG, PNG, WebP lub HEIC, do 5 MB. Najlepiej kwadratowe.',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
              Wrap(
                spacing: 4,
                children: [
                  TextButton(
                    onPressed: _loading ? null : _pickLogo,
                    child: Text(hasLogo ? 'Zmień' : 'Dodaj zdjęcie'),
                  ),
                  if (hasLogo)
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => setState(() {
                              _pickedLogo = null;
                              _logoRemoved = true;
                            }),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                      ),
                      child: const Text('Usuń'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
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
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(labelText: label),
        validator: validator,
      ),
    );
  }
}
