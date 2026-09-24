import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../home_screen.dart';
import 'email_verification_screen.dart';
import 'register_screen.dart';

class ProfilePickerScreen extends StatefulWidget {
  const ProfilePickerScreen({super.key});

  @override
  State<ProfilePickerScreen> createState() => _ProfilePickerScreenState();
}

class _ProfilePickerScreenState extends State<ProfilePickerScreen> {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: StreamBuilder<List<UserModel>>(
            stream: authService.getProfiles(),
            builder: (context, snapshot) {
              final profiles = snapshot.data ?? [];
              final canAdd = profiles.length < AppConstants.maxProfiles;

              return Column(
                children: [
                  const SizedBox(height: 48),
                  Text(
                    AppConstants.appName,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Kim Giriyor?',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Expanded(
                    child: Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 28,
                        runSpacing: 32,
                        children: [
                          ...profiles.map((p) => _ProfileTile(
                                name: p.displayName,
                                onTap: () => _askPassword(p),
                                onDelete: () => _confirmDeleteProfile(p),
                              )),
                          if (canAdd)
                            _ProfileTile(
                              name: 'Profil Ekle',
                              isAdd: true,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: Text(
                      'En fazla ${AppConstants.maxProfiles} profil',
                      style: TextStyle(
                        color: AppTheme.textSecondary.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteProfile(UserModel profile) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor, size: 26),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Profili Sil',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          '${profile.displayName} kullanıcı hesabı silinecektir.\n\n✓ Eklenen ürünler silinmez, ambarda kalmaya devam eder.\n✓ Yapılan işlem geçmişi aynen korunur.\n\nEmin misiniz?',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Evet, Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await authService.deleteProfileByUid(profile.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil başarıyla silindi'),
              backgroundColor: AppTheme.cardColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: $e'),
              backgroundColor: AppTheme.cardColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _askPassword(UserModel profile) async {
    final pinControllers = List.generate(4, (_) => TextEditingController());
    final pinFocusNodes = List.generate(4, (_) => FocusNode());
    var loading = false;
    String? error;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String pinValue = pinControllers.map((c) => c.text).join();

            return AlertDialog(
              backgroundColor: AppTheme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Column(
                children: [
                  // Avatar
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(profile.displayName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.displayName,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'PIN Girin',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // PIN kutuları
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      return Container(
                        width: 50,
                        height: 58,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextField(
                          controller: pinControllers[index],
                          focusNode: pinFocusNodes[index],
                          obscureText: true,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(1),
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                          decoration: InputDecoration(
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                            filled: true,
                            fillColor: AppTheme.surfaceColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppTheme.cardBorderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppTheme.cardBorderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppTheme.primaryColor, width: 2),
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty && index < 3) {
                              pinFocusNodes[index + 1].requestFocus();
                            }
                            if (value.isEmpty && index > 0) {
                              pinFocusNodes[index - 1].requestFocus();
                            }
                          },
                        ),
                      );
                    }),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      error!,
                      style: const TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: loading ? null : () => Navigator.pop(ctx),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          pinValue =
                              pinControllers.map((c) => c.text).join();
                          if (pinValue.length != 4) {
                            setDialogState(
                                () => error = '4 haneli PIN girin');
                            return;
                          }
                          setDialogState(() {
                            loading = true;
                            error = null;
                          });

                          // PIN'i Firebase password'a çevir
                          final password = 'depo_pin_${pinValue}_secure';

                          final authService =
                              Provider.of<AuthService>(this.context,
                                  listen: false);
                          final result = await authService.signIn(
                            email: profile.email,
                            password: password,
                          );
                          if (!ctx.mounted) return;
                          if (result == null) {
                            Navigator.pop(ctx);
                            if (!mounted) return;
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (_) => const HomeScreen()),
                              (route) => false,
                            );
                          } else if (result == 'EMAIL_NOT_VERIFIED') {
                            Navigator.pop(ctx);
                            if (!mounted) return;
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const EmailVerificationScreen(),
                              ),
                            );
                          } else {
                            setDialogState(() {
                              loading = false;
                              error = 'PIN hatalı';
                            });
                            // PIN kutularını temizle
                            for (final c in pinControllers) {
                              c.clear();
                            }
                            pinFocusNodes[0].requestFocus();
                          }
                        },
                  child: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Giriş Yap'),
                ),
              ],
            );
          },
        );
      },
    );
    for (final c in pinControllers) {
      c.dispose();
    }
    for (final n in pinFocusNodes) {
      n.dispose();
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}

class _ProfileTile extends StatelessWidget {
  final String name;
  final bool isAdd;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _ProfileTile({
    required this.name,
    required this.onTap,
    this.isAdd = false,
    this.onDelete,
  });

  String get _initials {
    if (isAdd || name.isEmpty) return '+';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: isAdd ? null : AppTheme.primaryGradient,
                  color: isAdd ? AppTheme.surfaceColor : null,
                  borderRadius: BorderRadius.circular(18),
                  border: isAdd
                      ? Border.all(color: AppTheme.cardBorderColor, width: 2)
                      : null,
                  boxShadow: isAdd
                      ? null
                      : [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                child: Center(
                  child: isAdd
                      ? const Icon(Icons.add_rounded,
                          color: AppTheme.textSecondary, size: 42)
                      : Text(
                          _initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              if (!isAdd && onDelete != null)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.errorColor.withValues(alpha: 0.6),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 110,
            child: Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isAdd ? AppTheme.textSecondary : AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
