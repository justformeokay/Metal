import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../services/store_service.dart';
import '../../utils/theme.dart';
import '../../widgets/auth_widgets.dart';

/// Onboarding screen shown after registration for store/business setup.
class StoreSetupScreen extends StatefulWidget {
  const StoreSetupScreen({super.key});

  @override
  State<StoreSetupScreen> createState() => _StoreSetupScreenState();
}

class _StoreSetupScreenState extends State<StoreSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  final StoreService _storeService = StoreService();
  bool _isLoading = false;
  int _currentStep = 0;

  // Business type selection
  final List<_BusinessType> _businessTypes = [
    _BusinessType('Toko Kelontong', Icons.store_rounded, 'Warung & sembako'),
    _BusinessType('Makanan & Minuman', Icons.restaurant_rounded, 'Kuliner & F&B'),
    _BusinessType('Fashion', Icons.checkroom_rounded, 'Pakaian & aksesoris'),
    _BusinessType('Jasa', Icons.build_rounded, 'Servis & layanan'),
    _BusinessType('Online Shop', Icons.shopping_bag_rounded, 'Toko online'),
    _BusinessType('Lainnya', Icons.category_rounded, 'Jenis usaha lain'),
  ];
  int? _selectedType;

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Get the business type label from selected index
    final businessType = _selectedType != null
        ? _businessTypes[_selectedType!].label
        : null;

    final result = await _storeService.createStore(
      storeName: _storeNameCtrl.text.trim(),
      businessType: businessType,
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      // Mark setup as complete in AuthController and navigate
      final auth = context.read<AuthController>();
      auth.markStoreSetupComplete();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppTheme.dangerColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _nextStep() {
    if (_currentStep == 0 && _selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pilih jenis usaha terlebih dahulu'),
          backgroundColor: AppTheme.warningColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    setState(() => _currentStep = 1);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthController>().user;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ─── Progress Header ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step indicator
                  Row(
                    children: [
                      _stepDot(0),
                      _stepLine(0),
                      _stepDot(1),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _currentStep == 0
                        ? 'Halo, ${user?.name ?? 'User'}! 👋'
                        : 'Detail Usahamu',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentStep == 0
                        ? 'Pilih jenis usaha yang kamu jalankan'
                        : 'Lengkapi informasi toko atau usahamu',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─── Content ─────────────────────────────────
            Expanded(
              child: _currentStep == 0
                  ? _buildStepBusinessType()
                  : _buildStepStoreDetail(),
            ),

            // ─── Bottom Button ───────────────────────────
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentStep == 1) ...[
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => setState(() => _currentStep = 0),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Kembali'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      text: _currentStep == 0 ? 'Lanjutkan' : 'Mulai Sekarang',
                      isLoading: _isLoading,
                      onPressed: _currentStep == 0 ? _nextStep : _handleSubmit,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  STEP 0 — Business Type Selection
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildStepBusinessType() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: _businessTypes.length,
      itemBuilder: (context, index) {
        final type = _businessTypes[index];
        final isSelected = _selectedType == index;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return GestureDetector(
          onTap: () => setState(() => _selectedType = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.08)
                  : (isDark ? AppTheme.cardDark : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryColor
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppTheme.border),
                width: isSelected ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor.withValues(alpha: 0.15)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : AppTheme.surfaceLight),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    type.icon,
                    size: 22,
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  type.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? AppTheme.primaryColor : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  type.subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  STEP 1 — Store Detail Form
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildStepStoreDetail() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Store icon preview
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _selectedType != null
                    ? _businessTypes[_selectedType!].icon
                    : Icons.store_rounded,
                size: 40,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            if (_selectedType != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _businessTypes[_selectedType!].label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Store name
            CustomTextField(
              controller: _storeNameCtrl,
              label: 'Nama Toko / Usaha',
              hint: 'Contoh: Toko Maju Jaya',
              prefixIcon: Icons.store_rounded,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Nama toko wajib diisi';
                }
                if (v.trim().length < 3) {
                  return 'Nama toko minimal 3 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone
            CustomTextField(
              controller: _phoneCtrl,
              label: 'Nomor Telepon Toko',
              hint: '08xxxxxxxxxx',
              prefixIcon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // Address
            TextFormField(
              controller: _addressCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Alamat Toko',
                hintText: 'Jl. Contoh No. 123, Kota',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 48),
                  child: Icon(Icons.location_on_rounded, size: 20),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Info box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: AppTheme.infoColor),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Informasi ini bisa diubah kapan saja dari menu Pengaturan.',
                      style:
                          TextStyle(fontSize: 13, color: AppTheme.infoColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  Helpers
  // ═══════════════════════════════════════════════════════════════════

  Widget _stepDot(int step) {
    final isActive = _currentStep >= step;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryColor : AppTheme.border,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isActive && _currentStep > step
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Text(
                '${step + 1}',
                style: TextStyle(
                  color: isActive ? Colors.white : AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }

  Widget _stepLine(int afterStep) {
    final isActive = _currentStep > afterStep;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : AppTheme.border,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

/// Internal model for business type options.
class _BusinessType {
  final String label;
  final IconData icon;
  final String subtitle;

  const _BusinessType(this.label, this.icon, this.subtitle);
}
