import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'purchase_service.dart';

class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  static const String _bannerProd = 'ca-app-pub-5549243085914479/6661262791';
  static const String _interstitialProd = 'ca-app-pub-5549243085914479/4186758255';
  static const String _rewardedProd = 'ca-app-pub-5549243085914479/4185775710';

  static const String _bannerTest = 'ca-app-pub-3940256099942544/6300978111';
  static const String _interstitialTest = 'ca-app-pub-3940256099942544/1033173712';
  static const String _rewardedTest = 'ca-app-pub-3940256099942544/5224354917';

  static const Duration _minInterval = Duration(seconds: 60);

  bool _initialized = false;
  InterstitialAd? _interstitial;
  bool _interstitialLoading = false;
  DateTime? _lastInterstitialShown;
  RewardedAd? _rewarded;
  bool _rewardedLoading = false;

  String get bannerUnitId => kDebugMode ? _bannerTest : _bannerProd;
  String get interstitialUnitId => kDebugMode ? _interstitialTest : _interstitialProd;
  String get rewardedUnitId => kDebugMode ? _rewardedTest : _rewardedProd;

  Future<void> initialize() async {
    if (_initialized) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      _loadInterstitial();
      _loadRewarded();
    } catch (_) {
      _initialized = false;
    }
  }

  void _loadInterstitial() {
    if (_interstitialLoading || _interstitial != null) return;
    _interstitialLoading = true;
    InterstitialAd.load(
      adUnitId: interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _interstitialLoading = false;
        },
        onAdFailedToLoad: (err) {
          _interstitial = null;
          _interstitialLoading = false;
        },
      ),
    );
  }

  Future<void> maybeShowInterstitial() async {
    if (!_initialized) return;
    if (PurchaseService.instance.noAds) return;
    final now = DateTime.now();
    if (_lastInterstitialShown != null &&
        now.difference(_lastInterstitialShown!) < _minInterval) {
      return;
    }
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _interstitial = null;
        _lastInterstitialShown = DateTime.now();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _interstitial = null;
        _loadInterstitial();
      },
    );
    await ad.show();
  }

  void _loadRewarded() {
    if (_rewardedLoading || _rewarded != null) return;
    _rewardedLoading = true;
    RewardedAd.load(
      adUnitId: rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _rewardedLoading = false;
        },
        onAdFailedToLoad: (err) {
          _rewarded = null;
          _rewardedLoading = false;
        },
      ),
    );
  }

  Future<bool> showRewarded() async {
    if (!_initialized) return false;
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return false;
    }
    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _rewarded = null;
        _loadRewarded();
        if (!completer.isCompleted) completer.complete(false);
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _rewarded = null;
        _loadRewarded();
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    await ad.show(onUserEarnedReward: (_, __) {
      if (!completer.isCompleted) completer.complete(true);
    });
    return completer.future;
  }

  BannerAd createBanner({required AdSize size, void Function(Ad)? onLoaded}) {
    return BannerAd(
      adUnitId: bannerUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => onLoaded?.call(ad),
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    );
  }
}
