import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/order_service.dart';
import '../location_picker_screen.dart';
import 'widgets/order_widgets.dart';

/// Create Order Screen - For Senders to create new orders
class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Item data
  final _itemNameController = TextEditingController();
  final _itemDescriptionController = TextEditingController();
  final _itemWeightController = TextEditingController();
  String _selectedCategory = ItemCategory.other;
  bool _isFragile = false;

  // Pickup location
  final _pickupAddressController = TextEditingController();
  double? _pickupLatitude;
  double? _pickupLongitude;

  // Destination location
  final _destinationAddressController = TextEditingController();
  double? _destinationLatitude;
  double? _destinationLongitude;

  // Order data
  final _notesController = TextEditingController();
  double _distanceKm = 0;

  bool _isLoading = false;
  bool _useDefaultAddress = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDefaultAddress();
    });
  }

  void _loadDefaultAddress() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user?.defaultAddress != null) {
      setState(() {
        _pickupAddressController.text = user!.defaultAddress!.address;
        _pickupLatitude = user.defaultAddress!.latitude;
        _pickupLongitude = user.defaultAddress!.longitude;
      });
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _itemDescriptionController.dispose();
    _itemWeightController.dispose();
    _pickupAddressController.dispose();
    _destinationAddressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Buat Pesanan')),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Form(
          key: _formKey,
          child: Stepper(
            currentStep: _currentStep,
            onStepContinue: _onStepContinue,
            onStepCancel: _onStepCancel,
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: details.onStepContinue,
                        child: Text(
                          _currentStep == 2 ? 'Buat Pesanan' : 'Lanjutkan',
                        ),
                      ),
                    ),
                    if (_currentStep > 0) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Kembali'),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
            steps: [
              // Step 1: Item Info
              Step(
                title: const Text('Informasi Barang'),
                subtitle: const Text('Detail barang yang akan dikirim'),
                isActive: _currentStep >= 0,
                state: _currentStep > 0
                    ? StepState.complete
                    : StepState.indexed,
                content: _buildItemStep(),
              ),
              // Step 2: Location
              Step(
                title: const Text('Lokasi'),
                subtitle: const Text('Pickup dan tujuan pengiriman'),
                isActive: _currentStep >= 1,
                state: _currentStep > 1
                    ? StepState.complete
                    : StepState.indexed,
                content: _buildLocationStep(),
              ),
              // Step 3: Review
              Step(
                title: const Text('Konfirmasi'),
                subtitle: const Text('Review dan buat pesanan'),
                isActive: _currentStep >= 2,
                state: StepState.indexed,
                content: _buildReviewStep(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category selector
        const Text(
          'Kategori',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        CategorySelector(
          selectedCategory: _selectedCategory,
          onSelect: (category) {
            setState(() {
              _selectedCategory = category;
            });
          },
        ),
        const SizedBox(height: 20),

        // Item name
        TextFormField(
          controller: _itemNameController,
          decoration: const InputDecoration(
            labelText: 'Nama Barang',
            hintText: 'Contoh: Nasi Goreng Spesial',
            prefixIcon: Icon(Icons.inventory_2_outlined),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Nama barang wajib diisi';
            }
            if (value.length < 3) {
              return 'Nama barang minimal 3 karakter';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Description
        TextFormField(
          controller: _itemDescriptionController,
          decoration: const InputDecoration(
            labelText: 'Deskripsi (Opsional)',
            hintText: 'Detail tambahan tentang barang',
            prefixIcon: Icon(Icons.description_outlined),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),

        // Weight
        TextFormField(
          controller: _itemWeightController,
          decoration: const InputDecoration(
            labelText: 'Berat (kg)',
            hintText: 'Contoh: 0.5',
            prefixIcon: Icon(Icons.scale_outlined),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Berat wajib diisi';
            }
            final weight = double.tryParse(value);
            if (weight == null || weight <= 0) {
              return 'Masukkan berat yang valid';
            }
            if (weight > 50) {
              return 'Berat maksimal 50 kg';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Fragile switch
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceVariant),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber, color: AppColors.warning),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Barang Mudah Pecah',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Perlu penanganan ekstra hati-hati',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isFragile,
                onChanged: (value) {
                  setState(() {
                    _isFragile = value;
                  });
                },
                activeColor: AppColors.primaryStart,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationStep() {
    final authProvider = context.watch<AuthProvider>();
    final hasDefaultAddress = authProvider.user?.defaultAddress != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Default Address Toggle
        if (hasDefaultAddress) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryStart.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryStart.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.home, color: AppColors.primaryStart, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gunakan Alamat Default',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        authProvider.user!.defaultAddress!.address,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _useDefaultAddress,
                  onChanged: (value) {
                    setState(() {
                      _useDefaultAddress = value;
                      if (value) {
                        _loadDefaultAddress();
                      } else {
                        _pickupAddressController.clear();
                        _pickupLatitude = null;
                        _pickupLongitude = null;
                      }
                    });
                  },
                  activeColor: AppColors.primaryStart,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Pickup location
        const Text(
          'Lokasi Pickup',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _pickupAddressController,
          decoration: const InputDecoration(
            labelText: 'Alamat Pickup',
            hintText: 'Masukkan alamat lengkap',
            prefixIcon: Icon(
              Icons.circle,
              color: AppColors.primaryStart,
              size: 16,
            ),
          ),
          maxLines: 2,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Alamat pickup wajib diisi';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),

        // Pickup Map Picker Button
        _buildMapPickerButton(
          label: 'Pilih Lokasi Pickup di Peta',
          latitude: _pickupLatitude,
          longitude: _pickupLongitude,
          iconColor: AppColors.primaryStart,
          onTap: () => _openPickupMapPicker(),
        ),
        const SizedBox(height: 24),

        // Destination location
        const Text(
          'Lokasi Tujuan',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _destinationAddressController,
          decoration: const InputDecoration(
            labelText: 'Alamat Tujuan',
            hintText: 'Masukkan alamat lengkap',
            prefixIcon: Icon(
              Icons.location_on,
              color: AppColors.error,
              size: 20,
            ),
          ),
          maxLines: 2,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Alamat tujuan wajib diisi';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),

        // Destination Map Picker Button
        _buildMapPickerButton(
          label: 'Pilih Lokasi Tujuan di Peta',
          latitude: _destinationLatitude,
          longitude: _destinationLongitude,
          iconColor: AppColors.error,
          onTap: () => _openDestinationMapPicker(),
        ),
        const SizedBox(height: 16),

        // Distance display
        if (_distanceKm > 0)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.straighten, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Text(
                  'Jarak: ${_distanceKm.toStringAsFixed(1)} km',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '~${(_distanceKm * 5).round()} menit',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // Notes
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Catatan untuk Hunter (Opsional)',
            hintText: 'Instruksi khusus untuk pengiriman',
            prefixIcon: Icon(Icons.note_outlined),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildMapPickerButton({
    required String label,
    required double? latitude,
    required double? longitude,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final hasCoordinates = latitude != null && longitude != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasCoordinates
                ? AppColors.success.withValues(alpha: 0.5)
                : AppColors.surfaceVariant,
            width: hasCoordinates ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: hasCoordinates
              ? AppColors.success.withValues(alpha: 0.05)
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.map, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasCoordinates
                        ? 'Lat: ${latitude.toStringAsFixed(4)}, Lng: ${longitude.toStringAsFixed(4)}'
                        : 'Ketuk untuk membuka peta',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasCoordinates
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              hasCoordinates ? Icons.check_circle : Icons.chevron_right,
              color: hasCoordinates
                  ? AppColors.success
                  : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPickupMapPicker() async {
    final result = await Navigator.push<LocationPickerResult>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLatitude: _pickupLatitude,
          initialLongitude: _pickupLongitude,
          title: 'Pilih Lokasi Pickup',
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _pickupLatitude = result.latitude;
        _pickupLongitude = result.longitude;
      });
      _calculateDistance();
    }
  }

  Future<void> _openDestinationMapPicker() async {
    final result = await Navigator.push<LocationPickerResult>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLatitude: _destinationLatitude,
          initialLongitude: _destinationLongitude,
          title: 'Pilih Lokasi Tujuan',
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _destinationLatitude = result.latitude;
        _destinationLongitude = result.longitude;
      });
      _calculateDistance();
    }
  }

  Widget _buildReviewStep() {
    final weight = double.tryParse(_itemWeightController.text) ?? 0;
    final estimatedPoints = (10 + (_distanceKm * 10)).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Item summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    ItemCategory.getIcon(_selectedCategory),
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _itemNameController.text.isEmpty
                              ? 'Nama Barang'
                              : _itemNameController.text,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          ItemCategory.getDisplayName(_selectedCategory),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _ReviewRow(label: 'Berat', value: '$weight kg'),
              if (_isFragile)
                _ReviewRow(
                  label: 'Penanganan',
                  value: 'Fragile - Hati-hati',
                  valueColor: AppColors.warning,
                ),
              if (_itemDescriptionController.text.isNotEmpty)
                _ReviewRow(
                  label: 'Deskripsi',
                  value: _itemDescriptionController.text,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Location summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.circle, color: AppColors.primaryStart, size: 12),
                  const SizedBox(width: 8),
                  const Text(
                    'Pickup',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text(
                  _pickupAddressController.text.isEmpty
                      ? 'Alamat pickup'
                      : _pickupAddressController.text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, color: AppColors.error, size: 12),
                  const SizedBox(width: 8),
                  const Text(
                    'Tujuan',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text(
                  _destinationAddressController.text.isEmpty
                      ? 'Alamat tujuan'
                      : _destinationAddressController.text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Divider(height: 24),
              _ReviewRow(
                label: 'Jarak',
                value: '${_distanceKm.toStringAsFixed(1)} km',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Trust Points estimate
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryStart, AppColors.primaryEnd],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.stars, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estimasi Trust Points',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      '+$estimatedPoints TP untuk Hunter',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        if (_notesController.text.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Catatan',
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
                const SizedBox(height: 4),
                Text(
                  _notesController.text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Validate only item step fields
  bool _validateItemStep() {
    // Validate item name
    final itemName = _itemNameController.text.trim();
    if (itemName.isEmpty) {
      _showValidationError('Nama barang wajib diisi');
      return false;
    }
    if (itemName.length < 2) {
      _showValidationError('Nama barang minimal 2 karakter');
      return false;
    }

    // Validate weight
    final weightText = _itemWeightController.text.trim();
    if (weightText.isEmpty) {
      _showValidationError('Berat wajib diisi');
      return false;
    }
    final weight = double.tryParse(weightText);
    if (weight == null || weight <= 0) {
      _showValidationError('Masukkan berat yang valid');
      return false;
    }
    if (weight > 50) {
      _showValidationError('Berat maksimal 50 kg');
      return false;
    }

    return true;
  }

  /// Validate only location step fields
  bool _validateLocationStep() {
    // Validate pickup address
    if (_pickupAddressController.text.trim().isEmpty) {
      _showValidationError('Alamat pickup wajib diisi');
      return false;
    }
    if (_pickupAddressController.text.trim().length < 5) {
      _showValidationError('Alamat pickup minimal 5 karakter');
      return false;
    }

    // Validate destination address
    if (_destinationAddressController.text.trim().isEmpty) {
      _showValidationError('Alamat tujuan wajib diisi');
      return false;
    }
    if (_destinationAddressController.text.trim().length < 5) {
      _showValidationError('Alamat tujuan minimal 5 karakter');
      return false;
    }

    // Validate coordinates
    if (_pickupLatitude == null || _pickupLongitude == null) {
      _showValidationError('Lokasi pickup wajib diisi');
      return false;
    }
    if (_destinationLatitude == null || _destinationLongitude == null) {
      _showValidationError('Lokasi tujuan wajib diisi');
      return false;
    }

    return true;
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      // Validate item step only
      if (_validateItemStep()) {
        setState(() {
          _currentStep++;
        });
      }
    } else if (_currentStep == 1) {
      // Validate location step only
      if (_validateLocationStep()) {
        setState(() {
          _currentStep++;
        });
      }
    } else if (_currentStep == 2) {
      // Create order
      _createOrder();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _calculateDistance() {
    // Haversine formula for accurate distance calculation
    if (_pickupLatitude != null &&
        _pickupLongitude != null &&
        _destinationLatitude != null &&
        _destinationLongitude != null) {
      const double earthRadius = 6371; // km

      final lat1 = _pickupLatitude! * math.pi / 180;
      final lat2 = _destinationLatitude! * math.pi / 180;
      final dLat = (_destinationLatitude! - _pickupLatitude!) * math.pi / 180;
      final dLng = (_destinationLongitude! - _pickupLongitude!) * math.pi / 180;

      final a =
          math.sin(dLat / 2) * math.sin(dLat / 2) +
          math.cos(lat1) *
              math.cos(lat2) *
              math.sin(dLng / 2) *
              math.sin(dLng / 2);
      final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

      _distanceKm = earthRadius * c;
      setState(() {});
    }
  }

  Future<void> _createOrder() async {
    // Final validation before creating order
    if (!_validateItemStep() || !_validateLocationStep()) {
      return;
    }

    // Calculate distance if not already done
    if (_pickupLatitude != null &&
        _pickupLongitude != null &&
        _destinationLatitude != null &&
        _destinationLongitude != null) {
      _calculateDistance();
    }

    // Validate distance
    if (_distanceKm <= 0) {
      _showValidationError('Jarak pengiriman tidak valid');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final orderProvider = context.read<OrderProvider>();
      final orderService = OrderService();

      // First, estimate the delivery cost
      final weight = double.tryParse(_itemWeightController.text.trim()) ?? 0;
      final estimateResult = await orderService.estimateDeliveryCost(
        token: authProvider.token!,
        distanceKm: _distanceKm,
        weightKg: weight,
        isFragile: _isFragile,
      );

      setState(() {
        _isLoading = false;
      });

      if (!estimateResult.success) {
        _showValidationError(estimateResult.message ?? 'Gagal menghitung biaya');
        return;
      }

      // Check if user can afford
      if (!estimateResult.canAfford) {
        _showInsufficientPointsDialog(
          estimateResult.estimatedCost,
          estimateResult.currentBalance,
          estimateResult.shortage,
        );
        return;
      }

      // Show confirmation dialog with payment details
      final confirmed = await _showPaymentConfirmationDialog(
        estimatedCost: estimateResult.estimatedCost,
        currentBalance: estimateResult.currentBalance,
        hunterReward: estimateResult.hunterReward,
      );

      if (confirmed != true) {
        return;
      }

      // Proceed with order creation
      setState(() {
        _isLoading = true;
      });

      debugPrint('Creating order with distance: $_distanceKm km');

      final request = CreateOrderRequest(
        item: OrderItem(
          name: _itemNameController.text.trim(),
          category: _selectedCategory,
          weight: double.parse(_itemWeightController.text.trim()),
          description: _itemDescriptionController.text.trim().isEmpty
              ? null
              : _itemDescriptionController.text.trim(),
          isFragile: _isFragile,
        ),
        pickup: Location(
          address: _pickupAddressController.text.trim(),
          coords: Coordinates(
            latitude: _pickupLatitude!, // Now guaranteed non-null by validation
            longitude: _pickupLongitude!,
          ),
        ),
        destination: Location(
          address: _destinationAddressController.text.trim(),
          coords: Coordinates(
            latitude:
                _destinationLatitude!, // Now guaranteed non-null by validation
            longitude: _destinationLongitude!,
          ),
        ),
        distanceKm: _distanceKm > 0
            ? _distanceKm
            : 5.0, // Fallback to 5km if not calculated
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      final result = await orderProvider.createOrder(
        token: authProvider.token!,
        request: request,
      );

      debugPrint('CreateOrder Response: ${result.message}');
      debugPrint('CreateOrder Success: ${result.success}');

      setState(() {
        _isLoading = false;
      });

      if (result.success && mounted) {
        // Refresh user profile to update points balance
        await authProvider.refreshProfile();
        _showSuccessDialog(result.order!);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Gagal membuat pesanan'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Show insufficient points dialog
  void _showInsufficientPointsDialog(int required, int current, int shortage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
            const SizedBox(width: 8),
            const Text('Saldo Tidak Cukup'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPointsRow('Biaya Pengiriman', '$required pts', AppColors.error),
            const SizedBox(height: 8),
            _buildPointsRow('Saldo Anda', '$current pts', AppColors.textSecondary),
            const Divider(height: 24),
            _buildPointsRow('Kekurangan', '$shortage pts', AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Silakan top-up points Anda terlebih dahulu untuk melanjutkan.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to wallet/top-up screen
            },
            child: const Text('Top Up Points'),
          ),
        ],
      ),
    );
  }

  /// Show payment confirmation dialog
  Future<bool?> _showPaymentConfirmationDialog({
    required int estimatedCost,
    required int currentBalance,
    required int hunterReward,
  }) {
    final newBalance = currentBalance - estimatedCost;
    
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Pembayaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryStart.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildPointsRow('Biaya Pengiriman', '$estimatedCost pts', AppColors.textPrimary),
                  const SizedBox(height: 8),
                  _buildPointsRow('Saldo Anda', '$currentBalance pts', AppColors.textSecondary),
                  const Divider(height: 16),
                  _buildPointsRow('Saldo Setelah', '$newBalance pts', AppColors.success),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.textTertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hunter akan mendapat $hunterReward pts saat pengiriman selesai.',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Bayar $estimatedCost pts'),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  void _showSuccessDialog(Order order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Pesanan Berhasil Dibuat!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Order ID: ${order.orderId}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (order.pointsCost > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.toll, color: AppColors.warning, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '-${order.pointsCost} pts',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              'Hunter terdekat akan segera mengambil pesanan Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back
              },
              child: const Text('Selesai'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Review Row Widget
class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ReviewRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
