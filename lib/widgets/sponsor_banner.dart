import 'package:material_ui/material_ui.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../platform/ads_controller.dart';
import '../design/app_theme.dart';

class SponsorBanner extends StatefulWidget {
  const SponsorBanner({super.key, required this.ads});
  final AdsController ads;
  @override
  State<SponsorBanner> createState() => _SponsorBannerState();
}

class _SponsorBannerState extends State<SponsorBanner> {
  BannerAd? _ad;
  bool _loaded = false;
  int _width = 0, _generation = 0;
  Future<void> _load(int width) async {
    try {
      await _loadBanner(width);
    } catch (_) {
      if (!mounted || width != _width) return;
      _ad?.dispose();
      setState(() {
        _ad = null;
        _loaded = false;
      });
    }
  }

  Future<void> _loadBanner(int width) async {
    if (width <= 0 || width == _width) return;
    _width = width;
    final generation = ++_generation;
    _ad?.dispose();
    setState(() {
      _ad = null;
      _loaded = false;
    });
    // 광고가 표시될 때만 SDK/WebView를 준비해 앱 시작과 분리합니다.
    await widget.ads.initialize();
    if (!mounted || generation != _generation || !widget.ads.ready) return;
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || generation != _generation || size == null) return;
    final ad = BannerAd(
      adUnitId: widget.ads.bannerId,
      size: size,
      request: const AdRequest(nonPersonalizedAds: true),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted || generation != _generation) {
            ad.dispose();
            return;
          }
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted && generation == _generation) {
            setState(() {
              _ad = null;
              _loaded = false;
            });
          }
        },
      ),
    );
    _ad = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _generation++;
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth.floor();
      if (width != _width) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _load(width);
        });
      }
      if (!_loaded || _ad == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          children: [
            Text(
              widget.ads.testMode ? '테스트 광고' : '광고',
              style: TextStyle(color: context.appColors.muted, fontSize: 10),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: _ad!.size.width.toDouble(),
              height: _ad!.size.height.toDouble(),
              child: AdWidget(ad: _ad!),
            ),
          ],
        ),
      );
    },
  );
}
