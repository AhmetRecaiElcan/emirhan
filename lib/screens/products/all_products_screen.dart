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
  String _searchQuery = '';
  String _selectedDepot = 'Tümü';
  bool _isPrinting = false;
  List<ProductModel> _currentFilteredProducts = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _depotFilters(List<ProductModel> products) {
    final depots = products.map((p) => p.depot).toSet().toList()..sort();
    return ['Tümü', ...depots];
  }

  Future<void> _exportPdf() async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);

    try {
      List<ProductModel> productsToPrint = List.from(_currentFilteredProducts);
      if (productsToPrint.isEmpty) {
        final all = await _firestoreService.getProducts().first;
        final selectedDepot = _selectedDepot;
        productsToPrint = all.where((product) {
          final matchesSearch = product.name
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
          final matchesDepot = selectedDepot == 'Tümü' ||
              product.depot == selectedDepot;
          return matchesSearch && matchesDepot;
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

      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUserName = authService.currentUser?.displayName;

      await PdfService.generateAndPrintProductList(
        products: _currentFilteredProducts,
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
                final filters = _depotFilters(allProducts);
                final selectedDepot =
                    filters.contains(_selectedDepot) ? _selectedDepot : 'Tümü';
                final products = allProducts.where((product) {
                  final matchesSearch = product.name
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase());
                  final matchesDepot = selectedDepot == 'Tümü' ||
                      product.depot == selectedDepot;
                  return matchesSearch && matchesDepot;
                }).toList();
                _currentFilteredProducts = products;

                return Column(
                  children: [
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: filters.map((label) {
                          final isSelected = selectedDepot == label;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedDepot = label),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? AppTheme.primaryGradient
                                    : null,
                                color:
                                    isSelected ? null : AppTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : AppTheme.cardBorderColor,
                                ),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
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
                                  const Text(
                                    'Henüz ürün bulunmuyor',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 16,
                                    ),
                                  ),
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





