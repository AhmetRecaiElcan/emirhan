import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../models/product_model.dart';
import '../../models/transaction_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/transaction_service.dart';
import '../../widgets/custom_text_field.dart';

class ReduceStockScreen extends StatefulWidget {
  final ProductModel product;

  const ReduceStockScreen({super.key, required this.product});

  @override
  State<ReduceStockScreen> createState() => _ReduceStockScreenState();
}

class _ReduceStockScreenState extends State<ReduceStockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _toNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final TransactionService _transactionService = TransactionService();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _toNameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: AppTheme.darkTheme.copyWith(
            dialogTheme: const DialogThemeData(
              backgroundColor: AppTheme.cardColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      // Saat seçici
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: AppTheme.darkTheme.copyWith(
              dialogTheme: const DialogThemeData(
                backgroundColor: AppTheme.cardColor,
              ),
            ),
            child: child!,
          );
        },
      );
      setState(() {
        if (time != null) {
          _selectedDate = DateTime(
              picked.year, picked.month, picked.day, time.hour, time.minute);
        } else {
          _selectedDate = picked;
        }
      });
    }
  }

  Future<void> _reduceStock() async {
    if (!_formKey.currentState!.validate()) return;

    final quantity = double.parse(_quantityController.text);

    if (quantity > widget.product.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Stokta yeterli miktar yok! Mevcut: ${_formatQuantity(widget.product.quantity)} ${widget.product.unit}'),
          backgroundColor: AppTheme.cardColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser!;

      // İşlem kaydı oluştur
      final transaction = TransactionModel(
        id: '',
        productId: widget.product.id,
        productName: widget.product.name,
        fromUserId: user.uid,
        fromUserName: user.displayName ?? 'Bilinmeyen',
        toUserName: _toNameController.text.trim(),
        quantity: quantity,
        unit: widget.product.unit,
        transactionDate: _selectedDate,
        createdAt: DateTime.now(),
        type: TransactionModel.typeOut,
      );

      await _transactionService.addTransaction(transaction);

      // Stok miktarını güncelle
      final newQuantity = widget.product.quantity - quantity;
      await _firestoreService.updateProductQuantity(
          widget.product.id, newQuantity);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: AppTheme.successColor),
              const SizedBox(width: 8),
              Text(
                  '${_formatQuantity(quantity)} ${widget.product.unit} başarıyla çıkarıldı'),
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
    final dateFormat = DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR');

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
                    const Expanded(
                      child: Text(
                        'Stok Azalt',
                        style: TextStyle(
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
              const SizedBox(height: 20),
              // İçerik
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ürün bilgi kartı
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration:
                              AppTheme.gradientCardDecoration(borderRadius: 16),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.inventory_2_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.product.name,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Mevcut Stok: ${_formatQuantity(widget.product.quantity)} ${widget.product.unit}',
                                      style: const TextStyle(
                                        color: AppTheme.secondaryColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.secondaryColor
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.product.depot,
                                  style: const TextStyle(
                                    color: AppTheme.secondaryColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Kime verildi
                        CustomTextField(
                          controller: _toNameController,
                          label: 'Kime Verildi',
                          hint: 'Kişi adını girin',
                          prefixIcon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Bu alan gerekli';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        // Miktar
                        CustomTextField(
                          controller: _quantityController,
                          label: 'Miktar (${widget.product.unit})',
                          hint: 'Ne kadar verildi',
                          prefixIcon: Icons.numbers,
                          keyboardType: const TextInputType.numberWithOptions(
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
                        const SizedBox(height: 18),
                        // Tarih seçici
                        GestureDetector(
                          onTap: _selectDate,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: AppTheme.cardBorderColor),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  color: AppTheme.primaryColor,
                                  size: 22,
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'İşlem Tarihi',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      dateFormat.format(_selectedDate),
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: AppTheme.textSecondary,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),
                        // Onayla butonu
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _reduceStock,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentColor,
                              foregroundColor: Colors.white,
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
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                          Icons.check_circle_outline_rounded,
                                          size: 22),
                                      SizedBox(width: 10),
                                      Text(
                                        'İşlemi Onayla',
                                        style: TextStyle(
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
            ],
          ),
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
