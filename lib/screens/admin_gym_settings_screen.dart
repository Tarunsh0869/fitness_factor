// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../services/attendance_service.dart';

class AdminGymSettingsScreen extends StatefulWidget {
  final String gymId;
  const AdminGymSettingsScreen({super.key, required this.gymId});

  @override
  State<AdminGymSettingsScreen> createState() => _AdminGymSettingsScreenState();
}

class _AdminGymSettingsScreenState extends State<AdminGymSettingsScreen> {
  static const _blue   = Color(0xFF2563EB);
  static const _blueDk = Color(0xFF1D4ED8);
  static const _red    = Color(0xFFEF4444);
  static const _green  = Color(0xFF16A34A);
  static const _bg     = Color(0xFFF0F4FF);
  static const _card   = Colors.white;
  static const _ink    = Color(0xFF111827);
  static const _muted  = Color(0xFF6B7280);

  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _latCtrl    = TextEditingController();
  final _lngCtrl    = TextEditingController();
  final _radiusCtrl = TextEditingController();

  bool _loading     = true;
  bool _saving      = false;

  // Admin PINs management
  List<String> _adminPins = [];
  final _newPinCtrl = TextEditingController();
  final _confirmNewPinCtrl = TextEditingController();
  bool _addingPin = false;
  String? _pinError;
  String? _pinSuccess;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _radiusCtrl.dispose();
    _newPinCtrl.dispose();
    _confirmNewPinCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final gym = await AttendanceService.getGym(widget.gymId);
    if (gym != null && mounted) {
      _nameCtrl.text   = gym['name']         ?? '';
      _latCtrl.text    = '${gym['latitude']  ?? ''}';
      _lngCtrl.text    = '${gym['longitude'] ?? ''}';
      _radiusCtrl.text = '${gym['radiusMeters'] ?? 50}';
      _adminPins = List<String>.from(gym['adminPins'] ?? []);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveGymSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _saving = true; });

    final ok = await AdminService.updateGymSettings(
      gymId:        widget.gymId,
      name:         _nameCtrl.text.trim(),
      latitude:     double.parse(_latCtrl.text.trim()),
      longitude:    double.parse(_lngCtrl.text.trim()),
      radiusMeters: int.parse(_radiusCtrl.text.trim()),
      adminPins:    _adminPins,
    );

    if (mounted) {
      setState(() {
        _saving  = false;
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gym settings saved successfully.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save. Please try again.')),
          );
        }
      });
    }
  }

  Future<void> _addAdminPin() async {
    final pin = _newPinCtrl.text.trim();
    final confirm = _confirmNewPinCtrl.text.trim();

    if (pin.isEmpty || confirm.isEmpty) {
      setState(() => _pinError = 'Please enter PIN in both fields.');
      return;
    }
    if (pin.length != 4 || int.tryParse(pin) == null) {
      setState(() => _pinError = 'PIN must be exactly 4 digits.');
      return;
    }
    if (pin != confirm) {
      setState(() => _pinError = 'PINs do not match.');
      return;
    }
    if (_adminPins.contains(pin)) {
      setState(() => _pinError = 'This PIN already exists.');
      return;
    }

    setState(() => _addingPin = true);
    final ok = await AdminService.addAdminPin(widget.gymId, pin);
    if (mounted) {
      setState(() {
        _addingPin = false;
        if (ok) {
          _adminPins.add(pin);
          _newPinCtrl.clear();
          _confirmNewPinCtrl.clear();
          _pinError = null;
          _pinSuccess = 'PIN added successfully.';
        } else {
          _pinError = 'Failed to add PIN. Please try again.';
        }
      });
    }
  }

  Future<void> _removeAdminPin(String pin) async {
    setState(() {
      // We'll show a loading indicator by disabling the remove button via a separate state if needed.
      // For simplicity, we'll just call the service and update the list on success.
    });
    final ok = await AdminService.removeAdminPin(widget.gymId, pin);
    if (mounted && ok) {
      setState(() {
        _adminPins.removeWhere((p) => p == pin);
      });
    } else if (mounted) {
      // Show error? We'll use a snackbar or just console for now.
      // We'll set an error state if we want to show UI.
      // For now, we'll just log.
      // In a real app, we'd show a snackbar.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _ink,
        elevation: 0,
        title: const Text('Gym Settings',
            style: TextStyle(fontWeight: FontWeight.w700, color: _ink)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Gym Information'),
                    const SizedBox(height: 12),
                    _field(controller: _nameCtrl, label: 'Gym Name',
                        icon: Icons.store_outlined,
                        validator: (v) =>
                            v!.trim().isEmpty ? 'Name is required' : null),
                    const SizedBox(height: 24),

                    _sectionLabel('Geofence Location'),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _blue.withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: _blue, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Use Google Maps to find your gym\'s exact coordinates.',
                              style: TextStyle(color: _muted, fontSize: 12,
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _field(
                          controller: _latCtrl,
                          label: 'Latitude',
                          icon: Icons.my_location_outlined,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                          validator: (v) {
                            if (v!.trim().isEmpty) return 'Required';
                            if (double.tryParse(v.trim()) == null) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _field(
                          controller: _lngCtrl,
                          label: 'Longitude',
                          icon: Icons.my_location_outlined,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                          validator: (v) {
                            if (v!.trim().isEmpty) return 'Required';
                            if (double.tryParse(v.trim()) == null) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        )),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _field(
                      controller: _radiusCtrl,
                      label: 'Geofence Radius (meters)',
                      icon: Icons.radar_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v!.trim().isEmpty) return 'Required';
                        final n = int.tryParse(v.trim());
                        if (n == null || n < 10 || n > 1000) {
                          return 'Enter 10–1000 meters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    _sectionLabel('Admin PINs'),
                    const SizedBox(height: 4),
                    Text('Manage administrator PINs. Each admin can use a unique PIN to access the gym.',
                        style: TextStyle(color: _muted, fontSize: 12)),
                    const SizedBox(height: 12),
                    if (_adminPins.isEmpty) ...
                      [
                        Text('No admin PINs set. Add at least one PIN.',
                            style: TextStyle(color: _red, fontSize: 12)),
                      ]
                    else ...
                      [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _adminPins.map((pin) {
                            final masked = pin.length > 2
                                ? '${pin.substring(0, 2)}****'
                                : '****';
                            return Chip(
                              label: Text(masked),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () => _removeAdminPin(pin),
                              backgroundColor: _blue.withOpacity(0.1),
                              labelStyle: TextStyle(color: _blue),
                            );
                          }).toList(),
                        ),
                      ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _newPinCtrl,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            maxLength: 4,
                            decoration: InputDecoration(
                              labelText: 'New PIN',
                              labelStyle: TextStyle(color: _muted),
                              prefixIcon: const Icon(Icons.lock_outline, color: _blue),
                              filled: true,
                              fillColor: _card,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: _blue, width: 1.5),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: _red, width: 1),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: _red, width: 1),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 15),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _confirmNewPinCtrl,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            maxLength: 4,
                            decoration: InputDecoration(
                              labelText: 'Confirm PIN',
                              labelStyle: TextStyle(color: _muted),
                              prefixIcon: const Icon(Icons.lock_outline, color: _blue),
                              filled: true,
                              fillColor: _card,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: _blue, width: 1.5),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: _red, width: 1),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: _red, width: 1),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _addingPin ? null : _addAdminPin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _blue.withOpacity(0.1),
                          foregroundColor: _blue,
                          side: BorderSide(color: _blue.withOpacity(0.3)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _addingPin
                            ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    color: _blue, strokeWidth: 2.5))
                            : const Text('Add PIN'),
                      ),
                    ),
                    if (_pinError != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _red.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _red.withOpacity(0.25)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.error_outline, color: _red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_pinError!,
                              style: const TextStyle(color: _red, fontSize: 13))),
                        ]),
                      ),
                    ],
                    if (_pinSuccess != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _green.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _green.withOpacity(0.25)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.check_circle_outline,
                              color: _green, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_pinSuccess!,
                              style: TextStyle(color: _green, fontSize: 13))),
                        ]),
                      ),
                    ],

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity, height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [_blue, _blueDk]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(color: _blue.withOpacity(0.35),
                                blurRadius: 16, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _saving ? null : _saveGymSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _saving
                              ? const SizedBox(width: 22, height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5))
                              : const Text('Save Settings',
                                  style: TextStyle(fontWeight: FontWeight.w700,
                                      fontSize: 16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(label.toUpperCase(),
            style: const TextStyle(color: _blue, fontSize: 11,
                fontWeight: FontWeight.w700, letterSpacing: 1.4)),
      );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: _ink, fontSize: 15),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _muted),
        prefixIcon: Icon(icon, color: _blue, size: 20),
        filled: true,
        fillColor: _card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _red, width: 1),
        ),
        errorStyle: const TextStyle(color: _red),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
    );
  }
}