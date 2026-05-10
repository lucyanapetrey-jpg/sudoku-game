import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ads_service.dart';
import '../services/purchase_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ad ??= _create();
  }

  BannerAd _create() {
    final width = MediaQuery.of(context).size.width.truncate();
    final ad = AdsService.instance.createBanner(
      size: AdSize(width: width, height: 50),
      onLoaded: (_) {
        if (mounted) setState(() => _loaded = true);
      },
    );
    ad.load();
    return ad;
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid && !Platform.isIOS) return const SizedBox.shrink();
    return ValueListenableBuilder<bool>(
      valueListenable: PurchaseService.instance.noAdsNotifier,
      builder: (_, noAds, __) {
        if (noAds) return const SizedBox.shrink();
        if (!_loaded || _ad == null) return const SizedBox(height: 50);
        return SizedBox(
          width: _ad!.size.width.toDouble(),
          height: _ad!.size.height.toDouble(),
          child: AdWidget(ad: _ad!),
        );
      },
    );
  }
}
