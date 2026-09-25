import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:drivio/config/app_config.dart';
import 'package:drivio/models/trap_model.dart';
import 'package:drivio/providers/auth_provider.dart';
import 'package:drivio/providers/user_provider.dart';
import 'package:drivio/services/admin_access_service.dart';
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
  File? _pickedVideo;
  bool _isLoading = false;
  final _storageService = StorageService();

  bool get _hasUnsavedChanges =>
      _titleController.text.trim().isNotEmpty ||
      _descriptionController.text.trim().isNotEmpty ||
      _ruleController.text.trim().isNotEmpty ||
      _pickedImage != null ||
      _pickedVideo != null ||
      _difficulty != 3 ||
      _markerPosition.latitude != AppConfig.szczecin_lat ||
      _markerPosition.longitude != AppConfig.szczecin_lng;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _ruleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _pickedImage = File(picked.path));
      }
    } on PlatformException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              source == ImageSource.camera
                  ? 'Nie udało się otworzyć aparatu. Sprawdź uprawnienia.'
                  : 'Nie udało się otworzyć galerii. Sprawdź uprawnienia.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickVideo() async {
    try {
      final picked = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      );
      if (picked == null || !mounted) return;
      final file = File(picked.path);
      if (await file.length() > 100 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Film może mieć maksymalnie 100 MB.')),
          );
        }
        return;
      }
      if (mounted) setState(() => _pickedVideo = file);
    } on PlatformException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nie udało się wybrać filmu.')),
        );
      }
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasUnsavedChanges) return true;
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Odrzucić zmiany?'),
            content: const Text(
              'Wpisane informacje, zdjęcie i film nie zostaną zapisane.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Zostań'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Odrzuć'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _requestPop() async {
    if (_isLoading) return;
    if (await _confirmDiscard() && mounted) {
      context.pop();
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

    if (!devLogin && !(await AdminAccessService.check(user!)).isAdmin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tylko administrator może dodawać pułapki.'),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    String? uploadedPhotoUrl;
    String? uploadedVideoUrl;
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

      if (_pickedImage != null) {
        uploadedPhotoUrl = await _storageService.uploadTrapPhoto(
          user!.uid,
          _pickedImage!,
        );
      }
      if (_pickedVideo != null) {
        uploadedVideoUrl = await _storageService.uploadTrapVideo(
          user!.uid,
          _pickedVideo!,
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
        photoUrl: uploadedPhotoUrl,
        videoUrl: uploadedVideoUrl,
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
      debugPrint('Add trap failed: $e');
      if (uploadedPhotoUrl != null) {
        await _storageService.deletePhoto(uploadedPhotoUrl);
      }
      if (uploadedVideoUrl != null) {
        await _storageService.deleteUploadedMedia(uploadedVideoUrl);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is FormatException
                  ? e.message
                  : 'Nie udało się dodać pułapki. Sprawdź dane i spróbuj ponownie.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final access = ref.watch(adminAccessProvider);
    if (!ref.read(devLoginProvider) && access.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!ref.read(devLoginProvider) && access.value?.isAdmin != true) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Tylko administrator może dodawać pułapki.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dodaj pułapkę'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: _requestPop,
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressGuide(),
                const SizedBox(height: 24),
                _sectionLabel('Lokalizacja'),
                const SizedBox(height: 8),
                Container(
                  height: 250,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.outlineVariant),
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
                        onDragEnd: (pos) =>
                            setState(() => _markerPosition = pos),
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
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),
                _sectionLabel('Nazwa miejsca'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  style: TextStyle(color: colors.onSurface),
                  decoration: InputDecoration(
                    hintText: 'np. Rondo przy CH Galaxy',
                    prefixIcon: Icon(
                      Icons.location_on_outlined,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  maxLength: 100,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.length < 3) {
                      return 'Nazwa musi mieć co najmniej 3 znaki';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _sectionLabel('Opis błędu / co tu bywa problemem'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  style: TextStyle(color: colors.onSurface),
                  maxLines: 4,
                  maxLength: 1500,
                  decoration: InputDecoration(
                    hintText: 'Opisz pułapkę, którą zauważyłeś na egzaminie...',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(
                      Icons.warning_amber_outlined,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.length < 10) {
                      return 'Opis musi mieć co najmniej 10 znaków';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _sectionLabel('Zasada ruchu drogowego'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _ruleController,
                  style: TextStyle(color: colors.onSurface),
                  maxLines: 3,
                  maxLength: 1000,
                  decoration: InputDecoration(
                    hintText: 'Jaka zasada tu obowiązuje?',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(
                      Icons.info_outline,
                      color: colors.onSurfaceVariant,
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
                              : colors.onSurfaceVariant,
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
                const SizedBox(height: 20),
                _sectionLabel('Film (opcjonalny, maks. 100 MB)'),
                const SizedBox(height: 8),
                if (_pickedVideo != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.video_file_outlined,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _pickedVideo!.uri.pathSegments.last,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: colors.onSurface),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Usuń film',
                          onPressed: () => setState(() => _pickedVideo = null),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  )
                else
                  _imagePickerBtn(
                    icon: Icons.video_library_outlined,
                    label: 'Dodaj film',
                    onTap: _pickVideo,
                  ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Zapisywanie...'),
                            ],
                          )
                        : const Text('Dodaj pułapkę'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressGuide() {
    final colors = Theme.of(context).colorScheme;
    const steps = [
      (Icons.place_outlined, 'Miejsce'),
      (Icons.edit_note_rounded, 'Opis'),
      (Icons.photo_camera_outlined, 'Zdjęcie'),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          for (var index = 0; index < steps.length; index++) ...[
            Expanded(
              child: Column(
                children: [
                  Icon(
                    steps[index].$1,
                    color: index == 0
                        ? AppTheme.primary
                        : colors.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${index + 1}. ${steps[index].$2}',
                    style: GoogleFonts.poppins(
                      color: index == 0
                          ? colors.onSurface
                          : colors.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (index < steps.length - 1)
              Icon(
                Icons.chevron_right_rounded,
                color: colors.outlineVariant,
                size: 18,
              ),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    final colors = Theme.of(context).colorScheme;
    return Text(
      text,
      style: GoogleFonts.poppins(
        color: colors.onSurface,
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
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(icon, color: colors.onSurfaceVariant, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: colors.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
