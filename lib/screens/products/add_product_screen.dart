import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_theme.dart';
import '../../models/product_model.dart';
import '../../models/transaction_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../services/transaction_service.dart';
import '../../widgets/custom_text_field.dart';

class AddProductScreen extends StatefulWidget {
  final ProductModel? product;

  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minQuantityController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final TransactionService _transactionService = TransactionService();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _imageBytes;
  String _selectedUnit = AppConstants.unitTypes[0];
  String _selectedPurchaseType = AppConstants.purchaseTypes[0];
  int _selectedNumber = AppConstants.depotNumbers[0];
  String _selectedLetter = AppConstants.depotLetters[0];
  bool _useSpecialDepot = false;
  bool _isLoading = false;

  bool get _isEditing => widget.product != null;

  String get _selectedDepot => _useSpecialDepot
      ? AppConstants.specialDepot
      : AppConstants.buildDepot(_selectedNumber, _selectedLetter);

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product != null) {
      _nameController.text = product.name;
      _quantityController.text = product.quantity == product.quantity.toInt()
          ? product.quantity.toInt().toString()
          : product.quantity.toString();
      _minQuantityController.text =
          product.minQuantity == product.minQuantity.toInt()
              ? product.minQuantity.toInt().toString()
              : product.minQuantity.toString();
      _selectedUnit = AppConstants.unitTypes.contains(product.unit)
          ? product.unit
          : AppConstants.unitTypes[0];
      final parsed = AppConstants.parseDepot(product.depot);
      _selectedNumber = parsed.number;
      _selectedLetter = parsed.letter;
      _useSpecialDepot = parsed.special;
      if (AppConstants.purchaseTypes.contains(product.purchaseType)) {
        _selectedPurchaseType = product.purchaseType;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _minQuantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() => _imageBytes = bytes);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fotoğraf seçilemedi: $e'),
          backgroundColor: AppTheme.cardColor,
        ),
      );
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Fotoğraf Seç',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildPickerOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Kamera',
                    color: AppTheme.primaryColor,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPickerOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Galeri',
                    color: AppTheme.secondaryColor,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageBytes == null && !_isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.photo_camera_outlined, color: AppTheme.warningColor),
              SizedBox(width: 8),
              Text('Lütfen bir ürün fotoğrafı ekleyin'),
            ],
          ),
          backgroundColor: AppTheme.cardColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser!;
      final productId = widget.product?.id ?? const Uuid().v4();
      final newQuantity = double.parse(_quantityController.text);
      final minQuantity = double.parse(_minQuantityController.text);

      String imageUrl = widget.product?.imageUrl ?? '';
      if (_imageBytes != null) {
        imageUrl = await _storageService.uploadProductImage(_imageBytes!, productId);
      }

      final product = ProductModel(
        id: productId,
        name: _nameController.text.trim(),
        quantity: newQuantity,
        unit: _selectedUnit,
        depot: _selectedDepot,
        imageUrl: imageUrl,
        createdBy: widget.product?.createdBy ?? user.uid,
        createdByName: widget.product?.createdByName ?? user.displayName ?? 'Bilinmeyen',
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        minQuantity: minQuantity,
        purchaseType: _selectedPurchaseType,
      );

      if (_isEditing) {
        await _firestoreService.updateProduct(product);
        final oldQty = widget.product!.quantity;
        final diff = newQuantity - oldQty;
        if (diff.abs() > 0.0001) {
          await _transactionService.addTransaction(
            TransactionModel(
              id: '',
              productId: product.id,
              productName: product.name,
              fromUserId: user.uid,
              fromUserName: user.displayName ?? 'Bilinmeyen',
              toUserName: diff > 0 ? 'Stok artırma' : 'Stok düzeltme',
              quantity: diff.abs(),
              unit: product.unit,
              transactionDate: DateTime.now(),
              createdAt: DateTime.now(),
              type: diff > 0
                  ? TransactionModel.typeIn
                  : TransactionModel.typeOut,
            ),
          );
        }
      } else {
        await _firestoreService.addProduct(product);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: AppTheme.successColor),
              const SizedBox(width: 8),
              Text(_isEditing ? 'Ürün güncellendi' : 'Ürün başarıyla eklendi!'),
            ],
          ),
          backgroundColor: AppTheme.cardColor,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: AppTheme.cardColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
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
                    Expanded(
                      child: Text(
                        _isEditing ? 'Ürünü Düzenle' : 'Yeni Ürün Ekle',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        // Fotoğraf alanı
                        GestureDetector(
                          onTap: _showImagePicker,
                          child: Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.cardBorderColor,
                                width: 2,
                              ),
                              image: _imageBytes != null
                                  ? DecorationImage(
                                      image: MemoryImage(_imageBytes!),
                                      fit: BoxFit.cover,
                                    )
                                  : (_isEditing &&
                                          (widget.product?.imageUrl.isNotEmpty ??
                                              false))
                                      ? DecorationImage(
                                          image: NetworkImage(
                                              widget.product!.imageUrl),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                            ),
                            child: (_imageBytes == null &&
                                    !(_isEditing &&
                                        (widget.product?.imageUrl.isNotEmpty ??
                                            false)))
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: const Icon(
                                          Icons.add_a_photo_rounded,
                                          color: AppTheme.primaryColor,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Fotoğraf Ekle',
                                        style: TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Kamera veya galeriden seçin',
                                        style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  )
                                : Align(
                                    alignment: Alignment.topRight,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.5),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.edit_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Ürün adı
                        CustomTextField(
                          controller: _nameController,
                          label: 'Ürün Adı',
                          hint: 'Ürün adını girin',
                          prefixIcon: Icons.label_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ürün adı gerekli';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        // Miktar ve birim
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: CustomTextField(
                                controller: _quantityController,
                                label: 'Miktar',
                                hint: '0',
                                prefixIcon: Icons.numbers,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Miktar gerekli';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Geçerli sayı girin';
                                  }
                                  if (double.parse(value) <= 0) {
                                    return '0\'dan büyük olmalı';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 1,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AppTheme.cardBorderColor),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedUnit,
                                    dropdownColor: AppTheme.cardColor,
                                    icon: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: AppTheme.primaryColor),
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 15,
                                    ),
                                    items: AppConstants.unitTypes
                                        .map((unit) => DropdownMenuItem(
                                              value: unit,
                                              child: Text(unit),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(
                                            () => _selectedUnit = value);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        CustomTextField(
                          controller: _minQuantityController,
                          label: 'Alt Limit',
                          hint: 'Kritik stok miktarı',
                          prefixIcon: Icons.warning_amber_rounded,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Alt limit gerekli';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Geçerli sayı girin';
                            }
                            if (double.parse(value) < 0) {
                              return '0 veya daha büyük olmalı';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        // Depo lokasyonu: rakam + harf (veya özel Z1)
                        const Text(
                          'Depo Lokasyonu',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.cardBorderColor),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warehouse_outlined,
                                  color: AppTheme.primaryColor, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'Seçilen: $_selectedDepot',
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Rakam (1-10)',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: AppConstants.depotNumbers.map((number) {
                            final isSelected =
                                !_useSpecialDepot && _selectedNumber == number;
                            return _buildDepotChip(
                              label: '$number',
                              isSelected: isSelected,
                              onTap: () => setState(() {
                                _useSpecialDepot = false;
                                _selectedNumber = number;
                              }),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Harf (A-H)',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: AppConstants.depotLetters.map((letter) {
                            final isSelected =
                                !_useSpecialDepot && _selectedLetter == letter;
                            return _buildDepotChip(
                              label: letter,
                              isSelected: isSelected,
                              onTap: () => setState(() {
                                _useSpecialDepot = false;
                                _selectedLetter = letter;
                              }),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Özel',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDepotChip(
                          label: AppConstants.specialDepot,
                          isSelected: _useSpecialDepot,
                          onTap: () => setState(() => _useSpecialDepot = true),
                        ),
                        const SizedBox(height: 24),
                        // Nasıl Alındı?
                        const Text(
                          'Nasıl Alındı?',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildPurchaseTypeOption(
                          title: AppConstants.purchaseTypes[0],
                          value: AppConstants.purchaseTypes[0],
                          icon: Icons.storefront_rounded,
                        ),
                        const SizedBox(height: 10),
                        _buildPurchaseTypeOption(
                          title: AppConstants.purchaseTypes[1],
                          value: AppConstants.purchaseTypes[1],
                          icon: Icons.account_balance_rounded,
                        ),
                        const SizedBox(height: 32),
                        // Kaydet butonu
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveProduct,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.save_rounded, size: 22),
                                      const SizedBox(width: 10),
                                      Text(
                                        _isEditing
                                            ? 'Değişiklikleri Kaydet'
                                            : 'Ürünü Kaydet',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDepotChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected ? null : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppTheme.cardBorderColor,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPurchaseTypeOption({
    required String title,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _selectedPurchaseType == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPurchaseType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.15)
              : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.cardBorderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.textSecondary.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
