import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/purchase_service.dart';

class ShopDialog extends StatefulWidget {
  final VoidCallback? onPurchased;
  const ShopDialog({super.key, this.onPurchased});

  @override
  State<ShopDialog> createState() => _ShopDialogState();
}

class _ShopDialogState extends State<ShopDialog> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final svc = PurchaseService.instance;
    final noAdsProduct = svc.productFor(PurchaseService.noAdsId);
    final coinProducts = svc.coinProducts;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_bag, color: Color(0xFF1565C0)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Magazin',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1565C0))),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                if (!svc.available) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFFE65100)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Magazinul nu e disponibil acum. Verifică-ți contul Google Play.',
                            style: TextStyle(color: Color(0xFFE65100)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (noAdsProduct != null) ...[
                  const Text('Premium',
                      style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  _NoAdsCard(
                    product: noAdsProduct,
                    purchased: svc.noAds,
                    busy: _busy,
                    onTap: _buyNoAds,
                  ),
                  const SizedBox(height: 20),
                ],
                if (coinProducts.isNotEmpty) ...[
                  const Text('Pachete monede',
                      style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  ...coinProducts.map((p) {
                    final pack =
                        PurchaseService.coinPacks.firstWhere((cp) => cp.id == p.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _CoinPackCard(
                        product: p,
                        pack: pack,
                        busy: _busy,
                        onTap: () => _buyConsumable(p.id),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: _busy
                          ? null
                          : () async {
                              setState(() => _busy = true);
                              await svc.restore();
                              await Future.delayed(const Duration(seconds: 2));
                              if (mounted) setState(() => _busy = false);
                              widget.onPurchased?.call();
                            },
                      icon: const Icon(Icons.restore),
                      label: const Text('Restaurează achizițiile'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _buyNoAds() async {
    setState(() => _busy = true);
    await PurchaseService.instance.buy(PurchaseService.noAdsId);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _busy = false);
    widget.onPurchased?.call();
  }

  Future<void> _buyConsumable(String id) async {
    setState(() => _busy = true);
    await PurchaseService.instance.buy(id);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _busy = false);
    widget.onPurchased?.call();
  }
}

class _NoAdsCard extends StatelessWidget {
  final ProductDetails product;
  final bool purchased;
  final bool busy;
  final VoidCallback onTap;
  const _NoAdsCard({
    required this.product,
    required this.purchased,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: purchased
              ? [const Color(0xFFA5D6A7), const Color(0xFF66BB6A)]
              : [const Color(0xFF42A5F5), const Color(0xFF1565C0)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.block, color: Colors.white, size: 36),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fără reclame',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18)),
                Text('Elimină banner + interstițial',
                    style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1565C0),
            ),
            onPressed: purchased || busy ? null : onTap,
            child: Text(
              purchased ? 'Activ' : product.price,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinPackCard extends StatelessWidget {
  final ProductDetails product;
  final CoinPack pack;
  final bool busy;
  final VoidCallback onTap;
  const _CoinPackCard({
    required this.product,
    required this.pack,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3F2FD)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.monetization_on, color: Color(0xFFFFAB00), size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${pack.total} monede',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 18)),
                if (pack.bonus > 0)
                  Text('+${pack.bonus} bonus',
                      style: const TextStyle(
                          color: Color(0xFF388E3C),
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
            onPressed: busy ? null : onTap,
            child: Text(product.price,
                style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
