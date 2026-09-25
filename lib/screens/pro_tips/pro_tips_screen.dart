import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drivio/theme/app_theme.dart';

class ProTipsScreen extends StatelessWidget {
  const ProTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tips = [
      _TipData(
        icon: '🔄',
        title: 'Jak prawidłowo przejechać rondo',
        content:
            '''Rondo to jedno z najtrudniejszych miejsc na egzaminie. Oto jak je pokonać:

1. Przed rondem: zwolnij i rozejrzyj się – kto ma pierwszeństwo
2. Ustąp pierwszeństwa pojazdom będącym już na rondzie
3. Wjeżdżaj spokojnie, nie przyspieszaj gwałtownie
4. Sygnalizuj zjazd z ronda – włącz prawy kierunkowskaz przed zjazdem
5. Nie zmieniaj pasa na rondzie, jeśli nie jest to konieczne
6. Na rondach wielopasmowych: lewy pas – dla jadących prosto lub w lewo, prawy – dla pierwszego zjazdu
7. Obserwuj pieszych przy przejściach na wyjeździe''',
      ),
      _TipData(
        icon: '✅',
        title: 'Checklist przed egzaminem',
        content: '''Sprawdź te rzeczy przed wyjazdem na egzamin:

□ Dowód osobisty lub paszport
□ PKK (Profil Kandydata na Kierowcę) – numer od instruktora
□ Okulary korekcyjne (jeśli je nosisz)
□ Naładowany telefon (na wszelki wypadek)
□ Odpowiedni ubiór – wygodne buty
□ Dotarcie 15 minut wcześniej
□ Wyspany i wypoczęty
□ Zjedzony posiłek – nie jedź głodny
□ Brak alkoholu (48h wcześniej)
□ Spokojna myśl – egzaminator nie chce Cię oblać!''',
      ),
      _TipData(
        icon: '🚦',
        title: 'Pierwszeństwo przejazdu',
        content: '''Zasady pierwszeństwa przejazdu na skrzyżowaniach:

ZASADA PODSTAWOWA: Droga z pierwszeństwem > droga podporządkowana

Na skrzyżowaniu bez znaków:
• Pojazd z prawej strony ma pierwszeństwo
• Tramwaj zawsze ma pierwszeństwo
• Piesi na przejściu mają bezwzględne pierwszeństwo

Znaki pionowe:
• "Ustąp pierwszeństwa" – zatrzymaj się i przepuść
• "Stop" – ZAWSZE zatrzymaj się przed linią
• "Droga z pierwszeństwem" – jesteś na uprzywilejowanej drodze

Sygnały świetlne zawsze mają pierwszeństwo przed znakami!''',
      ),
      _TipData(
        icon: '🅿️',
        title: 'Parkowanie równoległe krok po kroku',
        content: '''Parkowanie równoległe – klasyczny sposób:

1. Ustaw się równolegle do pojazdu z przodu, ok. 0,5–1 m od niego
2. Jedź do tyłu aż tylna oś zrówna się z tylnym zderzakiem przedniego auta
3. Skręć kierownicę maksymalnie w prawo (do tyłu)
4. Cofaj aż tył znajdzie się ok. 45° do krawężnika
5. Wyprostuj kierownicę
6. Skręć maksymalnie w lewo i cofaj aż auto będzie równoległe
7. Wyrównaj pozycję, utrzymuj ok. 30 cm od krawężnika
8. Sprawdź lustra i przestrzeń między autami''',
      ),
      _TipData(
        icon: '⚠️',
        title: 'Najczęstsze błędy na egzaminie',
        content: '''8 najczęstszych błędów zdających:

1. NIEDOSTATECZNA OBSERWACJA – nie sprawdzają lusterek i martwych kątów
2. NIEODPOWIEDNIA PRĘDKOŚĆ – za szybko w obszarze zabudowanym
3. BŁĘDY NA SKRZYŻOWANIACH – nieprawidłowe ustępowanie pierwszeństwa
4. BRAK KIERUNKOWSKAZÓW – zbyt późno lub wcale
5. NIEWŁAŚCIWE HAMOWANIE – gwałtowne lub za późne
6. PARKOWANIE – zbyt daleko od krawężnika lub na chodnik
7. NIEDOSTOSOWANIE DO WARUNKÓW – deszcz, mgła, noc
8. STRES I BRAK SKUPIENIA – egzaminatorzy to zauważają''',
      ),
      _TipData(
        icon: '🚗',
        title: 'Jak się zachować na egzaminie',
        content: '''Praktyczne wskazówki na dzień egzaminu:

• Przywitaj się z egzaminatorem – zrób dobre pierwsze wrażenie
• Dostosuj lusterka i siedzenie przed ruszeniem
• Zapnij pasy i upewnij się, że egzaminator też to zrobił
• Zapytaj, czy możesz ruszać – ale nie czekaj zbyt długo
• Jedź spokojnie i pewnie – nie szarżuj
• Jeśli popełnisz błąd – nie panikuj, kontynuuj jazdę
• Sygnalizuj każdy manewr z wyprzedzeniem
• Przy wątpliwościach – wyraź je słownie ("skręcam w lewo")
• Nie kłóć się z egzaminatorem podczas jazdy''',
      ),
      _TipData(
        icon: '📋',
        title: 'Co zabrać na egzamin',
        content: '''Lista dokumentów i rzeczy na egzamin:

OBOWIĄZKOWE:
• Dowód osobisty lub paszport
• PKK – Profil Kandydata na Kierowcę (numer ze szkoły jazdy)
• Ewentualnie zaświadczenie lekarskie (w razie potrzeby)

ZALECANE:
• Okulary/soczewki kontaktowe (jeśli dotyczy)
• Woda do picia (na sali egzaminacyjnej)
• Ładowarka do telefonu
• Numery telefonów: szkoła jazdy, rodzice/opiekunowie

PAMIĘTAJ:
• Smartwatch i słuchawki są ZABRONIONE podczas teorii
• Telefon musi być wyciszony''',
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Pro Tipy'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withAlpha(30),
                  AppTheme.routeBlue.withAlpha(20),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withAlpha(60)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: AppTheme.premiumGold,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Porady ekspertów',
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Wszystko, co musisz wiedzieć przed egzaminem',
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ...tips.map((tip) => _TipCard(tip: tip)),
        ],
      ),
    );
  }
}

class _TipData {
  final String icon;
  final String title;
  final String content;

  const _TipData({
    required this.icon,
    required this.title,
    required this.content,
  });
}

class _TipCard extends StatelessWidget {
  final _TipData tip;

  const _TipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Text(tip.icon, style: const TextStyle(fontSize: 24)),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  tip.title,
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          children: [
            Text(
              tip.content,
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
