import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:drivio/config/app_config.dart';
import 'package:drivio/providers/ads_provider.dart';
import 'package:drivio/providers/user_provider.dart';

class PremiumAwareBannerAd extends ConsumerStatefulWidget {
  const PremiumAwareBannerAd({super.key});

  @override
  ConsumerState<PremiumAwareBannerAd> createState() =>
      _PremiumAwareBannerAdState();
}

class _PremiumAwareBannerAdState extends ConsumerState<PremiumAwareBannerAd> {
  BannerAd? _banner;
  bool _loading = false;
  int? _requestedWidth;

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  Future<void> _load(int width, Orientation orientation) async {
    if (_loading || width <= 0 || _requestedWidth == width) return;
    _loading = true;
    _requestedWidth = width;

    // Keep the compact adaptive format; the new large format may consume
    // up to 20% of the screen and is too intrusive for Drivio.
    // ignore: deprecated_member_use
    final size = await AdSize.getAnchoredAdaptiveBannerAdSize(
      orientation,
      width,
    );
    if (!mounted || size == null) {
      _loading = false;
      return;
    }

    final ad = BannerAd(
      adUnitId: kDebugMode
          ? 'ca-app-pub-3940256099942544/2435281174'
          : AppConfig.admobIosBannerId,
      size: size,
      request: const AdRequest(
        nonPersonalizedAds: true,
        keywords: ['prawo jazdy', 'nauka jazdy', 'egzamin'],
      ),
      listener: BannerAdListener(
        onAdLoaded: (loadedAd) {
          if (!mounted) {
            loadedAd.dispose();
            return;
          }
          setState(() {
            _banner?.dispose();
            _banner = loadedAd as BannerAd;
            _loading = false;
          });
        },
        onAdFailedToLoad: (failedAd, error) {
          debugPrint('AdMob banner failed: $error');
          failedAd.dispose();
          if (mounted) setState(() => _loading = false);
        },
      ),
    );
    await ad.load();
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);
    final premiumResolved = ref.watch(premiumStatusResolvedProvider);
    final ready = ref.watch(adReadinessProvider).value ?? false;
    if (isPremium || !premiumResolved || !ready) {
      if (_banner != null) {
        final old = _banner;
        _banner = null;
        WidgetsBinding.instance.addPostFrameCallback((_) => old?.dispose());
      }
      return const SizedBox.shrink();
    }

    final width = MediaQuery.sizeOf(context).width.truncate();
    final orientation = MediaQuery.orientationOf(context);
    if (_banner == null && !_loading) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _load(width, orientation),
      );
    }
    final banner = _banner;
    if (banner == null) return const SizedBox.shrink();

    return ColoredBox(
      color: Colors.black,
      child: SafeArea(
        top: false,
        bottom: false,
        child: SizedBox(
          width: banner.size.width.toDouble(),
          height: banner.size.height.toDouble(),
          child: AdWidget(ad: banner),
        ),
      ),
    );
  }
}
