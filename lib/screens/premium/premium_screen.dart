import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:drivio/config/app_config.dart';
import 'package:drivio/providers/auth_provider.dart';
import 'package:drivio/providers/premium_provider.dart';
import 'package:drivio/providers/user_provider.dart';
import 'package:drivio/services/revenuecat_service.dart';
import 'package:drivio/theme/app_theme.dart';

const _showPremiumCheckoutPreview = bool.fromEnvironment(
  'DRIVIO_PREVIEW_CHECKOUT',
  defaultValue: false,
);

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    final productsAsync = ref.watch(productsProvider);
    final premiumService = ref.watch(premiumServiceProvider);
    final useIap = premiumService.shouldUseIAP;
    final showCheckoutPreview = kDebugMode || _showPremiumCheckoutPreview;

    ref.listen(premiumPurchaseEventsProvider, (_, next) {
      next.whenData((event) {
        final message = event.message;
        if (message == null || !context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      });
    });

    if (isPremium && !showCheckoutPreview) {
      return Scaffold(
        backgroundColor: AppTheme.bgDark,
        appBar: AppBar(backgroundColor: AppTheme.bgDark),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: AppTheme.premiumGold,
                  size: 76,
                ),
                const SizedBox(height: 16),
                Text(
                  'Jesteś już Premium',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pełny dostęp do Drivio jest aktywny na tym koncie.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Zamknij',
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () async => _restorePurchases(context, ref),
            child: const Text('Przywróć'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PremiumHero(
                      showDebugPreview: isPremium && showCheckoutPreview,
                    ),
                    const SizedBox(height: 22),
                    _BenefitsSection(),
                    const SizedBox(height: 24),
                    _SectionHeader(
                      title: 'Wybierz dostęp',
                      subtitle: premiumService.isUsingTestStore
                          ? 'Tryb testowy RevenueCat — bez prawdziwej opłaty.'
                          : useIap
                          ? 'Zakup obsłuży sklep urządzenia.'
                          : 'W podglądzie web używamy płatności Stripe.',
                    ),
                    const SizedBox(height: 12),
                    productsAsync.when(
                      data: (products) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (useIap) _missingProductsNotice(products),
                          _buildPlanCards(
                            context,
                            ref,
                            products,
                            isStoreLoading: false,
                          ),
                        ],
                      ),
                      loading: () => _buildPlanCards(
                        context,
                        ref,
                        const [],
                        isStoreLoading: true,
                      ),
                      error: (_, _) => Column(
                        children: [
                          _storeErrorNotice(
                            premiumService,
                            onRetry: () => ref.invalidate(productsProvider),
                          ),
                          _buildPlanCards(
                            context,
                            ref,
                            const [],
                            isStoreLoading: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _Footnote(useIap: useIap),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCards(
    BuildContext context,
    WidgetRef ref,
    List<Package> products, {
    required bool isStoreLoading,
  }) {
    final useIap = ref.read(premiumServiceProvider).shouldUseIAP;
    final allPlans = [
      _PlanData(
        label: 'Tydzień',
        price: AppConfig.priceWeekly,
        period: 'co tydzień',
        productId: AppConfig.iapWeekly,
        stripeUrl: AppConfig.stripeWeekly,
        badge: 'Na próbę',
        note: 'Szybki start przed jazdami.',
        highlighted: false,
      ),
      _PlanData(
        label: 'Miesiąc',
        price: AppConfig.priceMonthly,
        period: 'co miesiąc',
        productId: AppConfig.iapMonthly,
        stripeUrl: AppConfig.stripeMonthly,
        badge: 'Najczęściej',
        note: 'Najlepszy wybór na intensywną naukę.',
        highlighted: true,
      ),
      _PlanData(
        label: useIap ? 'Na zawsze' : 'Rok',
        price: useIap ? AppConfig.priceLifetime : AppConfig.priceYearly,
        period: useIap ? 'jednorazowo' : 'rok',
        productId: AppConfig.iapLifetime,
        stripeUrl: AppConfig.stripeYearly,
        badge: 'Najlepsza wartość',
        note: useIap
            ? 'Jedna płatność, dostęp bez końca.'
            : 'Najniższa cena w przeliczeniu na miesiąc.',
        highlighted: false,
      ),
    ];
    final plans = useIap
        ? allPlans
              .where(
                (plan) => RevenueCatService.productIds.contains(plan.productId),
              )
              .toList()
        : allPlans;

    return Column(
      children: plans.map((plan) {
        Package? iapProduct;
        try {
          iapProduct = products.firstWhere(
            (p) => p.storeProduct.identifier == plan.productId,
          );
        } catch (_) {
          iapProduct = null;
        }

        return _PlanCard(
          plan: plan,
          iapProduct: iapProduct,
          isStoreLoading: isStoreLoading,
          requiresStoreProduct: useIap,
          onBuy: () async => _buyPlan(context, ref, plan, iapProduct),
        );
      }).toList(),
    );
  }

  Future<void> _buyPlan(
    BuildContext context,
    WidgetRef ref,
    _PlanData plan,
    Package? iapProduct,
  ) async {
    final premiumService = ref.read(premiumServiceProvider);
    final authUser = ref.read(authStateProvider).value;
    final uid = _currentUid(ref);

    try {
      if (premiumService.shouldUseIAP) {
        if (uid == null) {
          context.push('/login');
          return;
        }
        if (authUser?.isAnonymous == true) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Załóż konto przed zakupem, aby nie utracić Premium.',
                ),
              ),
            );
          }
          return;
        }
        if (iapProduct == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Produkt w sklepie nie jest jeszcze gotowy.'),
              ),
            );
          }
          return;
        }
        await premiumService.purchase(uid: uid, product: iapProduct);
      } else {
        await premiumService.openStripePayment(plan.stripeUrl);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nie udało się rozpocząć zakupu.')),
        );
      }
    }
  }

  Future<void> _restorePurchases(BuildContext context, WidgetRef ref) async {
    final authUser = ref.read(authStateProvider).value;
    final uid = _currentUid(ref);
    if (uid == null) {
      context.push('/login');
      return;
    }
    if (authUser?.isAnonymous == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Załóż konto, aby przywrócić zakupy.')),
      );
      return;
    }
    try {
      await ref.read(premiumServiceProvider).restorePurchases(uid);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nie udało się przywrócić zakupów. Sprawdź połączenie i konto sklepu.',
          ),
        ),
      );
    }
  }

  String? _currentUid(WidgetRef ref) {
    final authUser = ref.read(authStateProvider).value;
    if (authUser != null) return authUser.uid;
    return ref.read(currentUserProvider).value?.uid;
  }

  Widget _missingProductsNotice(List<Package> products) {
    final productIds = products
        .map((product) => product.storeProduct.identifier)
        .toSet();
    final missing = RevenueCatService.productOrder
        .where((id) => !productIds.contains(id))
        .toList();
    // Store configuration details are only useful to developers.
    if (missing.isEmpty || !kDebugMode) return const SizedBox.shrink();

    return _NoticeBox(
      icon: Icons.storefront_outlined,
      text: 'Brakuje produktów w sklepie: ${missing.join(', ')}',
    );
  }

  Widget _storeErrorNotice(
    RevenueCatService service, {
    required VoidCallback onRetry,
  }) {
    final debugDetails =
        service.configurationIssue ??
        'Nie udało się pobrać offeringu ${AppConfig.revenueCatOfferingId}.';
    return _NoticeBox(
      icon: Icons.error_outline_rounded,
      text: kDebugMode
          ? debugDetails
          : 'Nie udało się połączyć ze sklepem. Sprawdź połączenie z internetem i spróbuj ponownie.',
      actionLabel: 'Spróbuj ponownie',
      onAction: onRetry,
    );
  }
}

class _PremiumHero extends StatelessWidget {
  final bool showDebugPreview;

  const _PremiumHero({required this.showDebugPreview});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.premiumGold.withAlpha(90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.premiumGold.withAlpha(24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppTheme.premiumGold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Drivio Premium',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Mniej limitów, więcej przygotowania do egzaminu.',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Odblokuj pełny dostęp do pułapek, tras i materiałów premium w jednym miejscu.',
            style: GoogleFonts.poppins(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (showDebugPreview) ...[
            const SizedBox(height: 12),
            const _InlineBadge(
              icon: Icons.visibility_outlined,
              text: 'Podgląd checkoutu w trybie dev',
            ),
          ],
        ],
      ),
    );
  }
}

class _BenefitsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _BenefitRow(
          icon: Icons.all_inclusive_rounded,
          title: 'Bez dziennego limitu pułapek',
          subtitle: 'Przeglądaj tyle miejsc, ile potrzebujesz.',
        ),
        _BenefitRow(
          icon: Icons.play_circle_rounded,
          title: 'Materiały i filmy premium',
          subtitle: 'Szybkie wskazówki do trudnych manewrów.',
        ),
        _BenefitRow(
          icon: Icons.route_rounded,
          title: 'Trasy egzaminacyjne',
          subtitle: 'Lepsze przygotowanie przed realnym egzaminem.',
        ),
      ],
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(22),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.35,
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanData {
  final String label;
  final String price;
  final String period;
  final String productId;
  final String stripeUrl;
  final String badge;
  final String note;
  final bool highlighted;

  const _PlanData({
    required this.label,
    required this.price,
    required this.period,
    required this.productId,
    required this.stripeUrl,
    required this.badge,
    required this.note,
    required this.highlighted,
  });
}

class _PlanCard extends StatelessWidget {
  final _PlanData plan;
  final Package? iapProduct;
  final bool isStoreLoading;
  final bool requiresStoreProduct;
  final VoidCallback onBuy;

  const _PlanCard({
    required this.plan,
    required this.iapProduct,
    required this.isStoreLoading,
    required this.requiresStoreProduct,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final productUnavailable =
        requiresStoreProduct && !isStoreLoading && iapProduct == null;
    final priceText = isStoreLoading
        ? 'Ładowanie...'
        : productUnavailable
        ? 'Niedostępny'
        : iapProduct?.storeProduct.priceString ?? plan.price;

    final borderColor = productUnavailable
        ? AppTheme.dividerColor
        : plan.highlighted
        ? AppTheme.primary
        : AppTheme.dividerColor;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: plan.highlighted
            ? AppTheme.primary.withAlpha(18)
            : AppTheme.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: plan.highlighted ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _InlineBadge(
                icon: plan.highlighted
                    ? Icons.local_fire_department_rounded
                    : Icons.check_circle_outline_rounded,
                text: plan.badge,
                strong: plan.highlighted,
              ),
              const Spacer(),
              Text(
                plan.period,
                style: GoogleFonts.poppins(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.label,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plan.note,
                      style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    priceText,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.poppins(
                      color: productUnavailable
                          ? AppTheme.textSecondary
                          : Colors.white,
                      fontSize: productUnavailable ? 16 : 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    productUnavailable ? 'spróbuj później' : 'brutto',
                    style: GoogleFonts.poppins(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: productUnavailable ? null : onBuy,
              style: ElevatedButton.styleFrom(
                backgroundColor: plan.highlighted
                    ? AppTheme.primary
                    : AppTheme.bgDark,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.dividerColor,
                disabledForegroundColor: AppTheme.textSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: plan.highlighted
                      ? BorderSide.none
                      : const BorderSide(color: AppTheme.dividerColor),
                ),
              ),
              child: Text(
                productUnavailable ? 'Produkt niedostępny' : 'Wybierz plan',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool strong;

  const _InlineBadge({
    required this.icon,
    required this.text,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = strong ? AppTheme.primary : AppTheme.premiumGold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeBox extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _NoticeBox({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withAlpha(16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primary.withAlpha(70)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                if (actionLabel != null && onAction != null)
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: Text(actionLabel!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Footnote extends StatelessWidget {
  final bool useIap;

  const _Footnote({required this.useIap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          useIap
              ? 'Plan tygodniowy i miesięczny odnawia się automatycznie, dopóki nie zostanie anulowany co najmniej 24 godziny przed końcem okresu. Płatność obciąża Apple ID po potwierdzeniu zakupu. Subskrypcją zarządzasz w Ustawieniach → Apple ID → Subskrypcje. Plan „Na zawsze” jest zakupem jednorazowym.'
              : 'Wersja web otwiera bezpieczną stronę płatności. W aplikacji iOS zakup przejmuje App Store.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: AppTheme.textSecondary,
            fontSize: 11,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            TextButton(
              onPressed: () => context.push('/terms'),
              child: const Text('Regulamin'),
            ),
            TextButton(
              onPressed: () => context.push('/privacy'),
              child: const Text('Polityka prywatności'),
            ),
          ],
        ),
      ],
    );
  }
}
