import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../models/product_model.dart';
import '../../models/transaction_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../services/transaction_service.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/transaction_tile.dart';
import 'add_product_screen.dart';
import 'reduce_stock_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  final List<ProductModel>? productList;
  final int? initialIndex;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.productList,
    this.initialIndex,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late List<ProductModel> _products;
  late int _currentIndex;
  late PageController _pageController;
  final FocusNode _focusNode = FocusNode();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    if (widget.productList != null && widget.productList!.isNotEmpty) {
      _products = List<ProductModel>.from(widget.productList!);
      if (widget.initialIndex != null &&
          widget.initialIndex! >= 0 &&
          widget.initialIndex! < _products.length) {
        _currentIndex = widget.initialIndex!;
      } else {
        final found = _products.indexWhere((p) => p.id == widget.product.id);
        _currentIndex = found >= 0 ? found : 0;
      }
    } else {
      _products = [widget.product];
      _currentIndex = 0;
    }

    _pageController = PageController(initialPage: _currentIndex);
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _isInputFocused() {
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus == null) return false;
    final ctx = primaryFocus.context;
    if (ctx == null) return false;

    if (ctx.widget is EditableText) return true;
    if (ctx.findAncestorWidgetOfExactType<EditableText>() != null) return true;
    if (ctx.findAncestorWidgetOfExactType<TextField>() != null) return true;
    if (ctx.findAncestorWidgetOfExactType<TextFormField>() != null) return true;

    return false;
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    // 1) Bu ekran şu anda en üstteki aktif ekran değilse (örn. üstüne Stok Azalt veya Düzenle ekranı açılmışsa) ASLA tuş yakalama!
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) {
      return false;
    }

    // 2) Herhangi bir metin giriş alanı odaklıysa tuş yakalama (kullanıcı sayı/yazı silerken sayfa geri dönmesin)
    if (_isInputFocused()) {
      return false;
    }

    // Backspace veya Escape tuşu ile önceki sayfaya dön
    if (event.logicalKey == LogicalKeyboardKey.backspace ||
        event.logicalKey == LogicalKeyboardKey.escape) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        return true;
      }
    }

    // Sadece Sağ yön tuşu -> Sonraki ürün
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _nextProduct();
      return true;
    }

    // Sadece Sol yön tuşu -> Önceki ürün
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _prevProduct();
      return true;
    }

    return false;
  }

  void _nextProduct() {
    if (_currentIndex < _products.length - 1) {
      _pageController.animateToPage(
        _currentIndex + 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevProduct() {
    if (_currentIndex > 0) {
      _pageController.animateToPage(
        _currentIndex - 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentProduct =
        _products.isNotEmpty ? _products[_currentIndex] : widget.product;
    final authService = Provider.of<AuthService>(context);
    final isOwner = authService.currentUser?.uid == currentProduct.createdBy;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      child: Scaffold(
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
                      Tooltip(
                        message: 'Geri Dön (Backspace)',
                        child: IconButton(
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
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Ürün Detayı',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (_products.length > 1) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  '${_currentIndex + 1} / ${_products.length}',
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (_products.length > 1) ...[
                        Tooltip(
                          message: 'Önceki Ürün (Sol Yön Tuşu)',
                          child: IconButton(
                            onPressed: _currentIndex > 0 ? _prevProduct : null,
                            icon: Icon(
                              Icons.chevron_left_rounded,
                              color: _currentIndex > 0
                                  ? AppTheme.textPrimary
                                  : AppTheme.textSecondary.withValues(alpha: 0.3),
                              size: 28,
                            ),
                          ),
                        ),
                        Tooltip(
                          message: 'Sonraki Ürün (Sağ Yön Tuşu)',
                          child: IconButton(
                            onPressed: _currentIndex < _products.length - 1
                                ? _nextProduct
                                : null,
                            icon: Icon(
                              Icons.chevron_right_rounded,
                              color: _currentIndex < _products.length - 1
                                  ? AppTheme.textPrimary
                                  : AppTheme.textSecondary.withValues(alpha: 0.3),
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                      if (isOwner)
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    AddProductScreen(product: currentProduct),
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
                          onPressed: () => _showDeleteDialog(
                              context, _firestoreService, currentProduct),
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
                      else if (_products.length <= 1)
                        const SizedBox(width: 96),
                    ],
                  ),
                ),
                // Swipe & PageView İçeriği
                Expanded(
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: _products.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return _ProductDetailContent(
                            key: ValueKey(_products[index].id),
                            product: _products[index],
                            firestoreService: _firestoreService,
                            onDelete: (prod) => _showDeleteDialog(
                                context, _firestoreService, prod),
                          );
                        },
                      ),

                      // Masaüstü / Web için sol ve sağ hızlı geçiş butonları
                      if (_products.length > 1 && _currentIndex > 0)
                        Positioned(
                          left: 16,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Tooltip(
                              message: 'Önceki Ürün (Sol Ok)',
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(30),
                                  onTap: _prevProduct,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceColor
                                          .withValues(alpha: 0.85),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTheme.cardBorderColor,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: AppTheme.textPrimary,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      if (_products.length > 1 &&
                          _currentIndex < _products.length - 1)
                        Positioned(
                          right: 16,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Tooltip(
                              message: 'Sonraki Ürün (Sağ Ok)',
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(30),
                                  onTap: _nextProduct,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceColor
                                          .withValues(alpha: 0.85),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTheme.cardBorderColor,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: AppTheme.textPrimary,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context,
      FirestoreService firestoreService, ProductModel productToDelete) {
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
              await firestoreService.deleteProduct(productToDelete.id);
              await StorageService().deleteProductImage(productToDelete.id);
              if (context.mounted) {
                if (_products.length <= 1) {
                  Navigator.pop(context);
                } else {
                  setState(() {
                    _products.removeWhere((p) => p.id == productToDelete.id);
                    if (_currentIndex >= _products.length) {
                      _currentIndex = _products.length - 1;
                    }
                  });
                }
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
}

class _ProductDetailContent extends StatelessWidget {
  final ProductModel product;
  final FirestoreService firestoreService;
  final void Function(ProductModel) onDelete;

  const _ProductDetailContent({
    super.key,
    required this.product,
    required this.firestoreService,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final transactionService = TransactionService();

    return StreamBuilder<ProductModel?>(
      stream: firestoreService.getProductStream(product.id),
      builder: (context, productSnapshot) {
        final currentProduct = productSnapshot.data ?? product;
        final isOwner = authService.currentUser?.uid == currentProduct.createdBy;

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
                            ? () async {
                                final deleted =
                                    await Navigator.of(context).push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) => ReduceStockScreen(
                                        product: currentProduct),
                                  ),
                                );
                                if (deleted == true && context.mounted) {
                                  onDelete(currentProduct);
                                }
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

  String _formatQuantity(double quantity) {
    if (quantity == quantity.toInt().toDouble()) {
      return quantity.toInt().toString();
    }
    return quantity.toStringAsFixed(1);
  }
}
