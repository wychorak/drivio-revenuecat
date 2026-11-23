import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drivio/theme/app_theme.dart';

class CarScreen extends StatelessWidget {
  const CarScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Samochód na egzaminie')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        const _Checklist('Przed ruszeniem', Icons.fact_check_outlined, [
          'Ustaw fotel, zagłówek i lusterka',
          'Zapnij pas i sprawdź drzwi',
          'Sprawdź bieg jałowy oraz hamulec postojowy',
          'Uruchom światła wymagane w danych warunkach',
        ]),
        const _SectionHeader(
          title: 'Światła',
          subtitle:
              'Barwa, sposób włączenia i miejsce na samochodzie. '
              'Dotknij zdjęcia, aby je powiększyć.',
          icon: Icons.highlight_rounded,
        ),
        for (final item in _lights) _ItemCard(item: item),
        const SizedBox(height: 8),
        const _SectionHeader(
          title: 'Płyny pod maską',
          subtitle: 'Gdzie szukać zbiorniczków i co powiedzieć egzaminatorowi.',
          icon: Icons.water_drop_outlined,
        ),
        for (final item in _fluids) _ItemCard(item: item),
        const SizedBox(height: 8),
        const _Checklist('Pozostałe elementy', Icons.directions_car_outlined, [
          'Światła przeciwmgłowe',
          'Kontrolki na desce rozdzielczej',
          'Sygnał dźwiękowy i podstawowe wyposażenie',
        ]),
        const _Checklist('Podczas jazdy', Icons.route_outlined, [
          'Regularnie obserwuj lusterka',
          'Sygnalizuj manewry odpowiednio wcześnie',
          'Zachowuj odstęp i dostosuj prędkość',
          'Przed manewrem sprawdzaj martwe pole',
        ]),
      ],
    ),
  );
}

const _white = Color(0xFFF5F5F5);
const _red = Color(0xFFE53935);
const _amber = Color(0xFFFFB300);

enum _Ignition { required, notRequired }

class _CarItem {
  const _CarItem({
    required this.title,
    required this.summary,
    required this.image,
    required this.points,
    this.icon = Icons.lightbulb_outline_rounded,
    this.iconColor = AppTheme.primary,
    this.symbol,
    this.colors = const [],
    this.ignition,
    this.warning,
  });

  final String title;
  final String summary;
  final String image;
  final List<String> points;
  final IconData icon;
  final Color iconColor;

  /// Dashboard symbol shown instead of [icon], when the light has one.
  final String? symbol;
  final List<Color> colors;
  final _Ignition? ignition;
  final String? warning;
}

const _carImages = 'assets/images/car';

const _lights = [
  _CarItem(
    title: 'Światła pozycyjne',
    summary: 'Przód: białe, tył: czerwone',
    symbol: '$_carImages/symbol_position.png',
    image: '$_carImages/light_position.jpg',
    colors: [_white, _red],
    ignition: _Ignition.notRequired,
    points: [
      'Przód: barwa biała. Tył: barwa czerwona.',
      'Przekręć manetkę na symbol świateł pozycyjnych.',
      'Samochód nie musi być uruchomiony.',
    ],
  ),
  _CarItem(
    title: 'Światła mijania',
    summary: 'Barwa biała',
    symbol: '$_carImages/symbol_low_beam.png',
    image: '$_carImages/light_low_beam.jpg',
    colors: [_white],
    ignition: _Ignition.required,
    points: [
      'Oświetlają drogę przed pojazdem.',
      'Nie oślepiają kierowców jadących z naprzeciwka.',
      'Używa się ich na co dzień.',
      'Aby je uruchomić, trzeba włączyć zapłon.',
    ],
  ),
  _CarItem(
    title: 'Światła drogowe',
    summary: 'Barwa biała',
    symbol: '$_carImages/symbol_high_beam.png',
    image: '$_carImages/light_high_beam.jpg',
    colors: [_white],
    ignition: _Ignition.required,
    points: [
      'Oświetlają drogę na większą odległość.',
      'Nie wolno ich używać, gdy mogłyby oślepiać innych kierowców.',
      'Do użycia tylko po zmroku.',
      'Włącza się je, przyciągając manetkę do siebie, a wyłącza, '
          'odpychając ją.',
      'Samochód musi być na zapłonie.',
    ],
  ),
  _CarItem(
    title: 'Światła hamowania',
    summary: 'Barwa czerwona',
    icon: Icons.do_not_step_rounded,
    iconColor: _red,
    image: '$_carImages/light_brake.jpg',
    colors: [_red],
    ignition: _Ignition.required,
    points: [
      'Zapalają się po naciśnięciu pedału hamulca.',
      'Informują innych kierowców o hamowaniu.',
      'Samochód musi być na zapłonie.',
    ],
  ),
  _CarItem(
    title: 'Światło cofania',
    summary: 'Barwa biała',
    icon: Icons.u_turn_left_rounded,
    image: '$_carImages/light_reverse.jpg',
    colors: [_white],
    ignition: _Ignition.required,
    points: [
      'Oświetla przestrzeń za pojazdem.',
      'Włącza się po wrzuceniu biegu wstecznego.',
      'W nowej Toyocie znajduje się na dole, pod rejestracją.',
      'Samochód musi być na zapłonie.',
    ],
  ),
  _CarItem(
    title: 'Kierunkowskazy',
    summary: 'Barwa żółta',
    icon: Icons.compare_arrows_rounded,
    iconColor: _amber,
    image: '$_carImages/light_indicators.jpg',
    colors: [_amber],
    ignition: _Ignition.required,
    points: [
      'Informują o zamiarze skrętu lub zmiany pasa ruchu.',
      'Sprawdzamy lewy i prawy: z przodu, z tyłu i na lusterkach.',
      'Samochód musi być na zapłonie.',
    ],
  ),
  _CarItem(
    title: 'Światła awaryjne',
    summary: 'Barwa żółta',
    icon: Icons.warning_amber_rounded,
    iconColor: _red,
    // Hazard lights use the same lamps as the indicators.
    image: '$_carImages/light_indicators.jpg',
    colors: [_amber],
    ignition: _Ignition.notRequired,
    points: [
      'Wszystkie kierunkowskazy migają jednocześnie.',
      'Ostrzegają o niebezpieczeństwie lub awarii.',
      'Samochód nie musi być uruchomiony.',
    ],
  ),
];

const _fluids = [
  _CarItem(
    title: 'Płyn do spryskiwaczy',
    summary: 'Niebieski korek z symbolem szyby',
    icon: Icons.water_drop_rounded,
    iconColor: AppTheme.routeBlue,
    image: '$_carImages/fluid_washer.jpg',
    points: [
      'Zbiorniczek ma zazwyczaj niebieski korek z symbolem szyby i '
          'strumieni wody.',
      'Sprawdzamy jego obecność i informujemy o tym egzaminatora.',
    ],
  ),
  _CarItem(
    title: 'Płyn hamulcowy',
    summary: 'Poziom między MIN a MAX',
    icon: Icons.opacity_rounded,
    iconColor: _amber,
    image: '$_carImages/fluid_brake_fluid.jpg',
    points: [
      'Sprawdzamy w zbiorniczku płynu hamulcowego.',
      'Poziom powinien znajdować się między MIN a MAX — tak też mówimy '
          'egzaminatorowi.',
    ],
  ),
  _CarItem(
    title: 'Olej silnikowy',
    summary: 'Bagnet, zimny silnik, równa powierzchnia',
    icon: Icons.oil_barrel_outlined,
    iconColor: _amber,
    image: '$_carImages/fluid_oil.jpg',
    points: [
      'Sprawdzamy za pomocą bagnetu.',
      'Na zimnym silniku i na równej powierzchni: wyciągamy bagnet, '
          'wycieramy, wkładamy ponownie i wyciągamy.',
      'Poziom powinien znajdować się między MIN a MAX.',
      'Czarny korek z symbolem przypominającym lampę dżina to miejsce '
          'dolewania oleju silnikowego.',
    ],
  ),
  _CarItem(
    title: 'Płyn chłodniczy',
    summary: 'Różowy zbiorniczek, zimny silnik',
    icon: Icons.thermostat_rounded,
    iconColor: Color(0xFFEC407A),
    image: '$_carImages/fluid_coolant.jpg',
    points: [
      'Sprawdzamy w różowym zbiorniczku.',
      'Poziom powinien znajdować się między MIN a MAX.',
      'Sprawdzamy na zimnym silniku.',
    ],
    warning: 'Nie odkręcamy korka na gorącym silniku!',
  ),
];

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: colors.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: colors.onSurfaceVariant,
                    fontSize: 12.5,
                    height: 1.4,
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

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});

  final _CarItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          leading: _Leading(item: item),
          title: Text(
            item.title,
            style: GoogleFonts.poppins(
              color: colors.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final color in item.colors) _ColorDot(color),
                Text(
                  item.summary,
                  style: GoogleFonts.poppins(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                if (item.ignition != null) _IgnitionChip(item.ignition!),
              ],
            ),
          ),
          children: [
            _ZoomableImage(asset: item.image, label: item.title),
            const SizedBox(height: 14),
            for (final point in item.points) _Bullet(point),
            if (item.warning != null) ...[
              const SizedBox(height: 4),
              _Warning(item.warning!),
            ],
          ],
        ),
      ),
    );
  }
}

class _Leading extends StatelessWidget {
  const _Leading({required this.item});

  final _CarItem item;

  @override
  Widget build(BuildContext context) {
    final symbol = item.symbol;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 44,
        height: 44,
        child: symbol != null
            ? Image.asset(symbol, fit: BoxFit.cover)
            : ColoredBox(
                color: item.iconColor.withAlpha(30),
                child: Icon(item.icon, color: item.iconColor),
              ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 12,
    height: 12,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(
        color: Theme.of(context).colorScheme.outline.withAlpha(160),
      ),
    ),
  );
}

class _IgnitionChip extends StatelessWidget {
  const _IgnitionChip(this.ignition);

  final _Ignition ignition;

  @override
  Widget build(BuildContext context) {
    final needsIgnition = ignition == _Ignition.required;
    final color = needsIgnition ? AppTheme.primary : AppTheme.successColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            needsIgnition ? Icons.key_rounded : Icons.key_off_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              needsIgnition ? 'Na zapłonie' : 'Bez uruchamiania',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomableImage extends StatelessWidget {
  const _ZoomableImage({required this.asset, required this.label});

  final String asset;
  final String label;

  void _open(BuildContext context) => showDialog<void>(
    context: context,
    barrierColor: Colors.black.withAlpha(220),
    builder: (context) => Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              maxScale: 5,
              child: Center(child: Image.asset(asset)),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            right: 8,
            child: IconButton.filledTonal(
              tooltip: 'Zamknij',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Powiększ zdjęcie: $label',
    child: GestureDetector(
      onTap: () => _open(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Image.asset(asset, width: double.infinity, fit: BoxFit.fitWidth),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(140),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.zoom_in_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.check_circle_outline,
            color: AppTheme.primary,
            size: 17,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Warning extends StatelessWidget {
  const _Warning(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.primary.withAlpha(22),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.primary.withAlpha(90)),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.local_fire_department_rounded,
          color: AppTheme.primary,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Checklist extends StatelessWidget {
  const _Checklist(this.title, this.icon, this.items);
  final String title;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.primary,
                    size: 19,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(item, style: GoogleFonts.poppins(fontSize: 13)),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
