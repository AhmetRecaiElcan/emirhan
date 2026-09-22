import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../services/pdf_service.dart';
import '../../models/product_model.dart';
import '../../widgets/product_card.dart';
import '../../widgets/loading_widget.dart';
import 'product_detail_screen.dart';

class AllProductsScreen extends StatefulWidget {
  const AllProductsScreen({super.key});

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _purchaseTypeScrollController = ScrollController();
  final ScrollController _depotScrollController = ScrollController();
  String _searchQuery = '';
  String _selectedDepot = 'Tümü';
  String _selectedPurchaseType = 'Tümü';
  bool _isPrinting = false;
  List<ProductModel> _currentFilteredProducts = [];

  @override
  void dispose() {
    _searchController.dispose();
    _purchaseTypeScrollController.dispose();
    _depotScrollController.dispose();
    super.dispose();
  }

  List<String> _depotFilters(List<ProductModel> products) {
    final depots = products
        .map((p) => p.depot.trim())
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['Tümü', ...depots];
  }

  Future<void> _exportPdf() async {
    if (_isPrinting) return;
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserName = authService.currentUser?.displayName;
    setState(() => _isPrinting = true);

    try {
      List<ProductModel> productsToPrint = List.from(_currentFilteredProducts);
      if (productsToPrint.isEmpty) {
        final all = await _firestoreService.getProducts().first;
        final selectedDepot = _selectedDepot;
        final selectedPurchaseType = _selectedPurchaseType;
        productsToPrint = all.where((product) {
          final matchesSearch = product.name
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
          final matchesDepot = selectedDepot == 'Tümü' ||
              product.depot == selectedDepot;
          final matchesPurchaseType = selectedPurchaseType == 'Tümü' ||
              product.purchaseType == selectedPurchaseType;
          return matchesSearch && matchesDepot && matchesPurchaseType;
        }).toList();
      }

      if (productsToPrint.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.warningColor),
                SizedBox(width: 8),
                Text('Yazdırılacak ürün bulunmuyor'),
              ],
            ),
            backgroundColor: AppTheme.cardColor,
          ),
        );
        return;
      }

      await PdfService.generateAndPrintProductList(
        products: productsToPrint,
        currentUserName: currentUserName,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF oluşturulurken hata: $e'),
          backgroundColor: AppTheme.cardColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    Color? activeColor,
    int? count,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? (activeColor != null
                  ? LinearGradient(
                      colors: [activeColor, activeColor.withValues(alpha: 0.8)])
                  : AppTheme.primaryGradient)
              : null,
          color: isSelected ? null : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppTheme.cardBorderColor,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color:
                        (activeColor ?? AppTheme.primaryColor).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.primaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalFilterBar({
    required ScrollController controller,
    required List<Widget> children,
    double height = 38,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktopOrWide = kIsWeb || constraints.maxWidth > 700;

        return SizedBox(
          height: height,
          child: Row(
            children: [
              if (isDesktopOrWide)
                Padding(
                  padding: const EdgeInsets.only(left: 12, right: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      if (controller.hasClients) {
                        controller.animateTo(
                          (controller.offset - 240).clamp(
                            0.0,
                            controller.position.maxScrollExtent,
                          ),
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                        );
                      }
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.cardBorderColor),
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        size: 20,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Listener(
                  onPointerSignal: (pointerSignal) {
                    if (pointerSignal is PointerScrollEvent &&
                        controller.hasClients) {
                      final double delta = pointerSignal.scrollDelta.dy != 0
                          ? pointerSignal.scrollDelta.dy
                          : pointerSignal.scrollDelta.dx;
                      controller.jumpTo(
                        (controller.offset + delta).clamp(
                          0.0,
                          controller.position.maxScrollExtent,
                        ),
                      );
                    }
                  },
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.trackpad,
                        PointerDeviceKind.stylus,
                      },
                    ),
                    child: ListView(
                      controller: controller,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktopOrWide ? 4 : 20,
                      ),
                      children: children,
                    ),
                  ),
                ),
              ),
              if (isDesktopOrWide)
                Padding(
                  padding: const EdgeInsets.only(left: 6, right: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      if (controller.hasClients) {
                        controller.animateTo(
                          (controller.offset + 240).clamp(
                            0.0,
                            controller.position.maxScrollExtent,
                          ),
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                        );
                      }
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.cardBorderColor),
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.grid_view_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ürün Havuzu',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Tüm ürünleri görüntüle',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // PDF İndir / Yazdır Butonu
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _exportPdf,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _isPrinting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.picture_as_pdf_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                            const SizedBox(width: 8),
                            const Text(
                              'Yazdır / PDF',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: AppTheme.glassDecoration(opacity: 0.06),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Ürün ara...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppTheme.textSecondary,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: AppTheme.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceColor.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<List<ProductModel>>(
              stream: _firestoreService.getProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget(message: 'Ürünler yükleniyor...');
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppTheme.errorColor, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'Hata: ${snapshot.error}',
                            style:
                                const TextStyle(color: AppTheme.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final allProducts = snapshot.data ?? [];
                final depotFilters = _depotFilters(allProducts);
                final selectedDepot =
                    depotFilters.contains(_selectedDepot) ? _selectedDepot : 'Tümü';
                final products = allProducts.where((product) {
                  final matchesSearch = product.name
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase());
                  final matchesDepot = selectedDepot == 'Tümü' ||
                      product.depot == selectedDepot;
                  final matchesPurchaseType = _selectedPurchaseType == 'Tümü' ||
                      product.purchaseType == _selectedPurchaseType;
                  return matchesSearch && matchesDepot && matchesPurchaseType;
                }).toList();
                _currentFilteredProducts = products;

                final hasActiveFilter = _selectedPurchaseType != 'Tümü' ||
                    selectedDepot != 'Tümü' ||
                    _searchQuery.isNotEmpty;

                return Column(
                  children: [
                    // Alım Şekli Filtresi
                    _buildHorizontalFilterBar(
                      controller: _purchaseTypeScrollController,
                      height: 38,
                      children: [
                        _buildFilterChip(
                          label: 'Tüm Alımlar',
                          icon: Icons.layers_rounded,
                          isSelected: _selectedPurchaseType == 'Tümü',
                          onTap: () => setState(() => _selectedPurchaseType = 'Tümü'),
                          count: allProducts
                              .where((p) =>
                                  selectedDepot == 'Tümü' || p.depot == selectedDepot)
                              .length,
                        ),
                        _buildFilterChip(
                          label: 'İşletme Geliriyle Alınanlar',
                          icon: Icons.business_center_rounded,
                          isSelected: _selectedPurchaseType ==
                              'İşletme Geliriyle Alınanlar',
                          activeColor: const Color(0xFF6C5CE7),
                          onTap: () => setState(() =>
                              _selectedPurchaseType = 'İşletme Geliriyle Alınanlar'),
                          count: allProducts
                              .where((p) =>
                                  p.purchaseType == 'İşletme Geliriyle Alınanlar' &&
                                  (selectedDepot == 'Tümü' || p.depot == selectedDepot))
                              .length,
                        ),
                        _buildFilterChip(
                          label: 'Devlet Kredisiyle Alınanlar',
                          icon: Icons.account_balance_rounded,
                          isSelected: _selectedPurchaseType ==
                              'Devlet Kredisiyle Alınanlar',
                          activeColor: const Color(0xFF00CEC9),
                          onTap: () => setState(() =>
                              _selectedPurchaseType = 'Devlet Kredisiyle Alınanlar'),
                          count: allProducts
                              .where((p) =>
                                  p.purchaseType == 'Devlet Kredisiyle Alınanlar' &&
                                  (selectedDepot == 'Tümü' || p.depot == selectedDepot))
                              .length,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Lokasyon / Depo Filtresi
                    if (depotFilters.length > 1) ...[
                      _buildHorizontalFilterBar(
                        controller: _depotScrollController,
                        height: 34,
                        children: depotFilters.map((label) {
                          final isSelected = selectedDepot == label;
                          final displayLabel = label == 'Tümü'
                              ? 'Tüm Lokasyonlar'
                              : (label.toLowerCase().startsWith('depo') ||
                                      label.toLowerCase().startsWith('zemin')
                                  ? label
                                  : 'Depo $label');
                          final count = label == 'Tümü'
                              ? allProducts
                                  .where((p) =>
                                      _selectedPurchaseType == 'Tümü' ||
                                      p.purchaseType == _selectedPurchaseType)
                                  .length
                              : allProducts
                                  .where((p) =>
                                      p.depot == label &&
                                      (_selectedPurchaseType == 'Tümü' ||
                                          p.purchaseType == _selectedPurchaseType))
                                  .length;
                          return _buildFilterChip(
                            label: displayLabel,
                            icon: label == 'Tümü'
                                ? Icons.location_on_outlined
                                : Icons.warehouse_rounded,
                            isSelected: isSelected,
                            onTap: () => setState(() => _selectedDepot = label),
                            count: count,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 4),

                    Expanded(
                      child: products.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    color: AppTheme.textSecondary
                                        .withValues(alpha: 0.5),
                                    size: 64,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    hasActiveFilter
                                        ? 'Seçilen filtrelere uygun ürün bulunamadı'
                                        : 'Henüz ürün bulunmuyor',
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (hasActiveFilter) ...[
                                    const SizedBox(height: 12),
                                    TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          _searchQuery = '';
                                          _selectedDepot = 'Tümü';
                                          _selectedPurchaseType = 'Tümü';
                                        });
                                      },
                                      icon: const Icon(Icons.refresh_rounded, size: 16),
                                      label: const Text('Filtreleri Temizle'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : GridView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 4, 20, 20),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 220,
                                childAspectRatio: 0.72,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                              ),
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                return ProductCard(
                                  product: products[index],
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ProductDetailScreen(
                                          product: products[index],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
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
}





