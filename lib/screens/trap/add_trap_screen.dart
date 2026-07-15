import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:drivio/config/app_config.dart';
import 'package:drivio/models/trap_model.dart';
import 'package:drivio/providers/auth_provider.dart';
import 'package:drivio/providers/user_provider.dart';
import 'package:drivio/services/content_moderation_service.dart';
import 'package:drivio/services/storage_service.dart';
import 'package:drivio/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddTrapScreen extends ConsumerStatefulWidget {
  const AddTrapScreen({super.key});

  @override
  ConsumerState<AddTrapScreen> createState() => _AddTrapScreenState();
}

class _AddTrapScreenState extends ConsumerState<AddTrapScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ruleController = TextEditingController();
  int _difficulty = 3;
  LatLng _markerPosition = const LatLng(
    AppConfig.szczecin_lat,
    AppConfig.szczecin_lng,
  );
  File? _pickedImage;
  bool _isLoading = false;
  final _storageService = StorageService();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _ruleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final moderationError = ContentModerationService.validateFields([
      _titleController.text,
      _descriptionController.text,
      if (_ruleController.text.trim().isNotEmpty) _ruleController.text,
    ]);
    if (moderationError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(moderationError)));
      return;
    }

    final devLogin = ref.read(devLoginProvider);
    final authState = ref.read(authStateProvider);
    final user = authState.value;
    if (user == null && !devLogin) return;

    setState(() => _isLoading = true);

    try {
      if (devLogin) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('DEV: pulapka nie zapisuje Firestore'),
            ),
          );
          context.pop();
        }
        return;
      }

      String? photoUrl;
      if (_pickedImage != null) {
        photoUrl = await _storageService.uploadTrapPhoto(
          user!.uid,
          _pickedImage!,
        );
      }

      final prefs = await SharedPreferences.getInstance();
      final city = prefs.getString('selectedCity') ?? AppConfig.defaultCity;

      final trap = TrapModel(
        id: '',
        lat: _markerPosition.latitude,
        lng: _markerPosition.longitude,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        difficulty: _difficulty,
        photoUrl: photoUrl,
        ruleDescription: _ruleController.text.trim(),
        createdBy: user!.uid,
        city: city,
        createdAt: DateTime.now(),
      );

      await ref.read(firestoreServiceProvider).addTrap(trap);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pułapka dodana! Dziękujemy.')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Błąd: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('Dodaj pułapkę'),
        backgroundColor: AppTheme.bgDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Lokalizacja'),
              const SizedBox(height: 8),
              Container(
                height: 250,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _markerPosition,
                    zoom: 14,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: _markerPosition,
                      draggable: true,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ),
                      onDragEnd: (pos) => setState(() => _markerPosition = pos),
                    ),
                  },
                  onTap: (pos) => setState(() => _markerPosition = pos),
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Dotknij mapę lub przeciągnij pin, aby ustawić lokalizację',
                style: GoogleFonts.poppins(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
              _sectionLabel('Nazwa miejsca'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'np. Rondo przy CH Galaxy',
                  prefixIcon: Icon(
                    Icons.location_on_outlined,
                    color: AppTheme.textSecondary,
                  ),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Podaj nazwę miejsca' : null,
              ),
              const SizedBox(height: 16),
              _sectionLabel('Opis błędu / co tu bywa problemem'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Opisz pułapkę, którą zauważyłeś na egzaminie...',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(
                    Icons.warning_amber_outlined,
                    color: AppTheme.textSecondary,
                  ),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Opisz pułapkę' : null,
              ),
              const SizedBox(height: 16),
              _sectionLabel('Zasada ruchu drogowego'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ruleController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Jaka zasada tu obowiązuje?',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(
                    Icons.info_outline,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _sectionLabel('Trudność'),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _difficulty = star),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        star <= _difficulty ? Icons.star : Icons.star_outline,
                        color: star <= _difficulty
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                        size: 36,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              _sectionLabel('Zdjęcie (opcjonalne)'),
              const SizedBox(height: 8),
              if (_pickedImage != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _pickedImage!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => setState(() => _pickedImage = null),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Usuń zdjęcie'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                  ),
                ),
              ] else
                Row(
                  children: [
                    _imagePickerBtn(
                      icon: Icons.camera_alt_outlined,
                      label: 'Aparat',
                      onTap: () => _pickImage(ImageSource.camera),
                    ),
                    const SizedBox(width: 12),
                    _imagePickerBtn(
                      icon: Icons.photo_library_outlined,
                      label: 'Galeria',
                      onTap: () => _pickImage(ImageSource.gallery),
                    ),
                  ],
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Dodaj pułapkę'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _imagePickerBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
