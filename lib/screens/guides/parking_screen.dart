import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drivio/theme/app_theme.dart';

class ParkingScreen extends StatefulWidget {
  const ParkingScreen({super.key});

  @override
  State<ParkingScreen> createState() => _ParkingScreenState();
}

class _ParkingScreenState extends State<ParkingScreen> {
  _Maneuver _maneuver = _Maneuver.perpendicular;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final guide = _guides[_maneuver]!;

    return Scaffold(
      appBar: AppBar(title: const Text('Parkowanie')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SegmentedButton<_Maneuver>(
            style: ButtonStyle(
              textStyle: WidgetStatePropertyAll(
                GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? colors.onPrimary
                    : colors.onSurface,
              ),
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? colors.primary
                    : colors.surface,
              ),
            ),
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: _Maneuver.perpendicular,
                icon: Icon(Icons.local_parking_rounded),
                label: Text('Prostopadłe'),
              ),
              ButtonSegment(
                value: _Maneuver.parallel,
                icon: Icon(Icons.swap_vert_rounded),
                label: Text('Równoległe'),
              ),
            ],
            selected: {_maneuver},
            onSelectionChanged: (values) =>
                setState(() => _maneuver = values.first),
          ),
          const SizedBox(height: 16),
          _GuideIntro(guide: guide),
          const SizedBox(height: 16),
          // A new key resets the stepper to step 1 when the maneuver changes.
          _StepViewer(key: ValueKey(_maneuver), guide: guide),
        ],
      ),
    );
  }
}

enum _Maneuver { perpendicular, parallel }

class _Guide {
  const _Guide({
    required this.title,
    required this.summary,
    required this.imagePrefix,
    required this.steps,
  });

  final String title;
  final String summary;
  final String imagePrefix;
  final List<_Step> steps;

  String imageFor(int index) =>
      'assets/images/parking/${imagePrefix}_${index + 1}.png';
}

class _Step {
  const _Step(this.title, this.description, [this.tip]);

  final String title;
  final String description;
  final String? tip;
}

const _guides = {
  _Maneuver.perpendicular: _Guide(
    title: 'Parkowanie prostopadłe',
    summary:
        'Wjazd przodem w wolne stanowisko i wyjazd tyłem. '
        'Cały manewr wykonuj powoli, stale obserwując otoczenie.',
    imagePrefix: 'perpendicular',
    steps: [
      _Step(
        'Podjazd do miejsca',
        'Jedź powoli wzdłuż miejsc parkingowych i wypatruj wolnego '
            'stanowiska.',
        'Zachowaj odstęp od zaparkowanych aut — potrzebujesz miejsca na '
            'skręt.',
      ),
      _Step(
        'Kierunkowskaz i obserwacja',
        'Włącz prawy kierunkowskaz i sprawdź lusterka oraz otoczenie.',
        'Zwróć uwagę na pieszych i pojazdy jadące za Tobą.',
      ),
      _Step(
        'Zatrzymaj się obok miejsca',
        'Zatrzymaj auto, gdy Twoje ramię minie linię wyznaczającą wolne '
            'miejsce.',
      ),
      _Step(
        'Skręć maksymalnie w prawo',
        'Skręć kierownicę do oporu w prawo i powoli wjeżdżaj przodem w '
            'miejsce.',
        'Pilnuj narożnika auta po stronie, w którą skręcasz.',
      ),
      _Step(
        'Wyrównaj kierownicę',
        'Gdy auto stoi prawie prosto, ustaw koła na wprost i wjedź głębiej.',
        'Obserwuj odstęp z obu stron.',
      ),
      _Step(
        'Zaparkowane',
        'Zatrzymaj się z równymi odstępami po obu stronach i kołami na '
            'wprost. Zaciągnij hamulec postojowy.',
      ),
      _Step(
        'Wyjazd: przygotowanie',
        'Włącz wsteczny bieg i lewy kierunkowskaz — po wyjeździe pojedziesz '
            'w lewo. Rozejrzyj się, czy możesz bezpiecznie wyjechać.',
        'Przed ruszeniem sprawdź lusterka i spójrz przez ramię.',
      ),
      _Step(
        'Cofaj w prawo',
        'Cofaj powoli, kręcąc kierownicą w prawo. Gdy wyjeżdżasz, zacznij '
            'wyrównywać koła.',
        'Przez cały czas patrz za siebie.',
      ),
      _Step(
        'Wyrównaj i jedź',
        'Ustaw koła na wprost, zatrzymaj się, wrzuć jedynkę i odjedź. '
            'Wyłącz kierunkowskaz.',
      ),
    ],
  ),
  _Maneuver.parallel: _Guide(
    title: 'Parkowanie równoległe',
    summary:
        'Wjazd tyłem w lukę między autami wzdłuż krawężnika. Luka musi być '
        'wyraźnie dłuższa niż Twoje auto.',
    imagePrefix: 'parallel',
    steps: [
      _Step(
        'Podjazd do miejsca',
        'Podjedź równolegle do auta zaparkowanego przed wolną luką.',
        'Utrzymuj około 0,5–1 m odstępu od zaparkowanych aut.',
      ),
      _Step(
        'Zrównaj lusterka',
        'Zatrzymaj się, gdy Twoje lusterko zrówna się z lusterkiem auta z '
            'przodu.',
        'Przed zatrzymaniem włącz prawy kierunkowskaz, a potem wsteczny '
            'bieg.',
      ),
      _Step(
        'Skręć w prawo i cofaj',
        'Skręć kierownicę maksymalnie w prawo i cofaj powoli.',
        'Przed ruszeniem sprawdź lusterka i spójrz przez ramię.',
      ),
      _Step(
        'Szukaj świateł auta z tyłu',
        'Cofaj, aż w lewym lusterku zobaczysz prawe światła auta '
            'zaparkowanego za Tobą.',
      ),
      _Step(
        'Skręć w lewo i cofaj',
        'Teraz kręć kierownicę maksymalnie w lewo i cofaj — tył auta wjeżdża '
            'w miejsce.',
        'Uważaj na przedni narożnik przy aucie z przodu.',
      ),
      _Step(
        'Wyrównaj i gotowe',
        'Ustaw koła na wprost i zostaw równe odstępy z przodu i z tyłu. '
            'Wyłącz kierunkowskaz i zaciągnij hamulec postojowy.',
      ),
    ],
  ),
};

class _GuideIntro extends StatelessWidget {
  const _GuideIntro({required this.guide});

  final _Guide guide;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outline.withAlpha(90)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(24),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guide.title,
                  style: GoogleFonts.poppins(
                    color: colors.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  guide.summary,
                  style: GoogleFonts.poppins(
                    color: colors.onSurfaceVariant,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const double _artTop = 336;
const double _artHeight = 1164;
// Vertical alignment that places source row [_artTop] at the top edge.
const double _artAlignmentY = 2 * _artTop / (1920 - _artHeight) - 1;

class _StepViewer extends StatefulWidget {
  const _StepViewer({super.key, required this.guide});

  final _Guide guide;

  @override
  State<_StepViewer> createState() => _StepViewerState();
}

class _StepViewerState extends State<_StepViewer> {
  final _pageController = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final steps = widget.guide.steps;
    final step = steps[_index];
    final isLast = _index == steps.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProgressBar(count: steps.length, index: _index, onTap: _goTo),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          // The artwork is 1080×1920. Rows 336–1500 hold the maneuver; above
          // and below are its own step pills and captions, which the text
          // under the image already shows.
          child: AspectRatio(
            aspectRatio: 1080 / _artHeight,
            child: PageView.builder(
              controller: _pageController,
              itemCount: steps.length,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (context, index) => Image.asset(
                widget.guide.imageFor(index),
                fit: BoxFit.cover,
                alignment: const Alignment(0, _artAlignmentY),
                semanticLabel: 'Krok ${index + 1}: ${steps[index].title}',
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'KROK ${_index + 1} Z ${steps.length}',
          style: GoogleFonts.poppins(
            color: AppTheme.primary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          step.title,
          style: GoogleFonts.poppins(
            color: colors.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          step.description,
          style: GoogleFonts.poppins(
            color: colors.onSurfaceVariant,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        if (step.tip != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.premiumGold.withAlpha(26),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.premiumGold.withAlpha(90)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.visibility_rounded,
                  color: AppTheme.premiumGold,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pamiętaj: ${step.tip}',
                    style: GoogleFonts.poppins(
                      color: colors.onSurface,
                      fontSize: 12.5,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _index == 0 ? null : () => _goTo(_index - 1),
                icon: const Icon(Icons.chevron_left_rounded),
                label: const Text('Wstecz'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _goTo(isLast ? 0 : _index + 1),
                icon: Icon(
                  isLast ? Icons.replay_rounded : Icons.chevron_right_rounded,
                ),
                label: Text(isLast ? 'Od początku' : 'Dalej'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.count,
    required this.index,
    required this.onTap,
  });

  final int count;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Semantics(
              button: true,
              label: 'Krok ${i + 1}',
              selected: i == index,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    height: 6,
                    decoration: BoxDecoration(
                      color: i <= index
                          ? AppTheme.primary
                          : colors.onSurface.withAlpha(40),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
