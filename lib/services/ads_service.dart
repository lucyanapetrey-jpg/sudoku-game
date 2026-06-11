import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'purchase_service.dart';

class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  static const String _bannerProdAndroid = 'ca-app-pub-5549243085914479/6661262791';
  static const String _bannerProdIOS = 'ca-app-pub-5549243085914479/4904310061';
  static const String _interstitialProdAndroid = 'ca-app-pub-5549243085914479/4186758255';
  static const String _interstitialProdIOS = 'ca-app-pub-5549243085914479/2278146725';
  static const String _rewardedProdAndroid = 'ca-app-pub-5549243085914479/4185775710';
  static const String _rewardedProdIOS = 'ca-app-pub-5549243085914479/8025297427';

  // App Open (highest-value launch/return ad). Replace the two prod IDs with the
  // real AdMob App Open units once created.
  static const String _appOpenProdAndroid = 'ca-app-pub-5549243085914479/APPOPEN_ANDROID';
  static const String _appOpenProdIOS = 'ca-app-pub-5549243085914479/APPOPEN_IOS';

  static const String _bannerTest = 'ca-app-pub-3940256099942544/6300978111';
  static const String _interstitialTest = 'ca-app-pub-3940256099942544/1033173712';
  static const String _rewardedTest = 'ca-app-pub-3940256099942544/5224354917';
  static const String _appOpenTestAndroid = 'ca-app-pub-3940256099942544/9257395921';
  static const String _appOpenTestIOS = 'ca-app-pub-3940256099942544/5575463023';

  static const Duration _minInterval = Duration(seconds: 60);
  static const Duration _appOpenMaxAge = Duration(hours: 4);

  bool _initialized = false;
  InterstitialAd? _interstitial;
  bool _interstitialLoading = false;
  DateTime? _lastInterstitialShown;
  RewardedAd? _rewarded;
  bool _rewardedLoading = false;
  AppOpenAd? _appOpen;
  bool _appOpenLoading = false;
  DateTime? _appOpenLoadTime;
  bool _showingFullScreenAd = false;

  /// Bumped whenever a full-screen ad (App Open or interstitial) closes, so the
  /// UI can offer the "Remove ads" upsell right after.
  final ValueNotifier<int> adClosedTick = ValueNotifier(0);
  void _notifyAdClosed() => adClosedTick.value++;

  String get bannerUnitId => kDebugMode ? _bannerTest : (Platform.isIOS ? _bannerProdIOS : _bannerProdAndroid);
  String get interstitialUnitId => kDebugMode ? _interstitialTest : (Platform.isIOS ? _interstitialProdIOS : _interstitialProdAndroid);
  String get rewardedUnitId => kDebugMode ? _rewardedTest : (Platform.isIOS ? _rewardedProdIOS : _rewardedProdAndroid);
  String get appOpenUnitId {
    if (kDebugMode) return Platform.isIOS ? _appOpenTestIOS : _appOpenTestAndroid;
    return Platform.isIOS ? _appOpenProdIOS : _appOpenProdAndroid;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      _loadInterstitial();
      _loadRewarded();
      loadAppOpen();
    } catch (_) {
      _initialized = false;
    }
  }

  void loadAppOpen() {
    if (_appOpenLoading || _appOpen != null) return;
    _appOpenLoading = true;
    AppOpenAd.load(
      adUnitId: appOpenUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpen = ad;
          _appOpenLoadTime = DateTime.now();
          _appOpenLoading = false;
        },
        onAdFailedToLoad: (err) {
          _appOpen = null;
          _appOpenLoading = false;
        },
      ),
    );
  }

  bool get _appOpenValid =>
      _appOpen != null &&
      _appOpenLoadTime != null &&
      DateTime.now().difference(_appOpenLoadTime!) < _appOpenMaxAge;

  /// Shows the App Open ad on app foreground if one is ready. Skips when ads are
  /// removed, another full-screen ad is showing, or none is loaded (then preloads).
  Future<void> showAppOpenIfReady() async {
    if (!_initialized || PurchaseService.instance.noAds) return;
    if (_showingFullScreenAd) return;
    if (!_appOpenValid) {
      loadAppOpen();
      return;
    }
    final ad = _appOpen!;
    _appOpen = null;
    _showingFullScreenAd = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _showingFullScreenAd = false;
        loadAppOpen();
        _notifyAdClosed();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _showingFullScreenAd = false;
        loadAppOpen();
      },
    );
    await ad.show();
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
    _showingFullScreenAd = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _interstitial = null;
        _showingFullScreenAd = false;
        _lastInterstitialShown = DateTime.now();
        _loadInterstitial();
        _notifyAdClosed();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _interstitial = null;
        _showingFullScreenAd = false;
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
    _showingFullScreenAd = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _rewarded = null;
        _showingFullScreenAd = false;
        _loadRewarded();
        if (!completer.isCompleted) completer.complete(false);
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _rewarded = null;
        _showingFullScreenAd = false;
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
