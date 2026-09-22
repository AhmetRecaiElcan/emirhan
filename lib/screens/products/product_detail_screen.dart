import 'package:flutter/material.dart';
import '../../widgets/app_network_image.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../models/product_model.dart';
import '../../models/transaction_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../services/transaction_service.dart';
import '../../widgets/transaction_tile.dart';
import '../../widgets/loading_widget.dart';
import 'reduce_stock_screen.dart';
import 'add_product_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isOwner = authService.currentUser?.uid == product.createdBy;
    final firestoreService = FirestoreService();
    final transactionService = TransactionService();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: AppTheme.glassDecoration(
                            opacity: 0.1, borderRadius: 12),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Ürün Detayı',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (isOwner)
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddProductScreen(product: product),
                            ),
                          );
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: AppTheme.glassDecoration(
                              opacity: 0.1, borderRadius: 12),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: AppTheme.textPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                    if (isOwner)
                      IconButton(
                        onPressed: () => _showDeleteDialog(context, firestoreService),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.errorColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppTheme.errorColor,
                            size: 20,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 96),
                  ],
                ),
              ),
              // İçerik
              Expanded(
                child: StreamBuilder<ProductModel?>(
                  stream: firestoreService.getProductStream(product.id),
                  builder: (context, productSnapshot) {
                    final currentProduct = productSnapshot.data ?? product;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          // Ürün fotoğrafı
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: AspectRatio(
                              aspectRatio: 1.4,
                              child: AppNetworkImage(
                                imageUrl: currentProduct.imageUrl,
                                fit: BoxFit.cover,
                                iconSize: 60,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Ürün adı
                          Text(
                            currentProduct.name,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Bilgi kartları
                          Row(
                            children: [
                              _buildInfoCard(
                                icon: Icons.scale_rounded,
                                label: 'Miktar',
                                value:
                                    '${_formatQuantity(currentProduct.quantity)} ${currentProduct.unit}',
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 12),
                              _buildInfoCard(
                                icon: Icons.warehouse_rounded,
                                label: 'Depo',
                                value: currentProduct.depot,
                                color: AppTheme.secondaryColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildInfoCard(
                                icon: Icons.person_rounded,
                                label: 'Oluşturan',
                                value: currentProduct.createdByName,
                                color: AppTheme.accentColor,
                              ),
                              const SizedBox(width: 12),
                              _buildInfoCard(
                                icon: Icons.warning_amber_rounded,
                                label: 'Alt Limit',
                                value:
                                    '${_formatQuantity(currentProduct.minQuantity)} ${currentProduct.unit}',
                                color: currentProduct.isLowStock
                                    ? AppTheme.errorColor
                                    : AppTheme.warningColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: AppTheme.cardBorderColor),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (currentProduct.purchaseType
                                                .contains('Devlet')
                                            ? AppTheme.accentColor
                                            : AppTheme.primaryColor)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    currentProduct.purchaseType
                                            .contains('Devlet')
                                        ? Icons.account_balance_rounded
                                        : Icons.storefront_rounded,
                                    color: currentProduct.purchaseType
                                            .contains('Devlet')
                                        ? AppTheme.accentColor
                                        : AppTheme.primaryColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Alım Şekli / Nasıl Alındı',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      currentProduct.purchaseType,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Stok azaltma butonu (sadece ürün sahibi)
                          if (isOwner) ...[
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton.icon(
                                onPressed: currentProduct.quantity > 0
                                    ? () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => ReduceStockScreen(
                                                product: currentProduct),
                                          ),
                                        );
                                      }
                                    : null,
                                icon: const Icon(
                                    Icons.remove_circle_outline_rounded),
                                label: const Text(
                                  'Stok Azalt / Ürün Ver',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accentColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => AddProductScreen(
                                          product: currentProduct),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.edit_rounded),
                                label: const Text(
                                  'Bilgileri Düzenle / Stok Artır',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primaryColor,
                                  side: const BorderSide(
                                      color: AppTheme.primaryColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          // İşlem geçmişi başlığı
                          const Row(
                            children: [
                              Icon(Icons.history_rounded,
                                  color: AppTheme.textSecondary, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'İşlem Geçmişi',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // İşlem listesi
                          StreamBuilder<List<TransactionModel>>(
                            stream: transactionService
                                .getProductTransactions(product.id),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox(
                                  height: 100,
                                  child: LoadingWidget(),
                                );
                              }

                              final transactions = snapshot.data ?? [];

                              if (transactions.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration:
                                      AppTheme.glassDecoration(opacity: 0.05),
                                  child: const Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.receipt_long_outlined,
                                          color: AppTheme.textSecondary,
                                          size: 36,
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          'Henüz işlem yapılmamış',
                                          style: TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              return Column(
                                children: transactions
                                    .map((t) => TransactionTile(transaction: t))
                                    .toList(),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, FirestoreService firestoreService) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Ürünü Sil',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'Bu ürünü silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await firestoreService.deleteProduct(product.id);
              await StorageService().deleteProductImage(product.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ürün silindi'),
                    backgroundColor: AppTheme.cardColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatQuantity(double quantity) {
    if (quantity == quantity.toInt().toDouble()) {
      return quantity.toInt().toString();
    }
    return quantity.toStringAsFixed(1);
  }
}
