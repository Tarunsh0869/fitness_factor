import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../services/geo_service.dart';
import '../services/auth_prefs.dart';
import 'admin_dashboard_screen.dart';

class AdminGymRegistrationScreen extends StatefulWidget {
  const AdminGymRegistrationScreen({super.key});

  @override
  State<AdminGymRegistrationScreen> createState() =>
      _AdminGymRegistrationScreenState();
}

class _AdminGymRegistrationScreenState
    extends State<AdminGymRegistrationScreen> {
  static const _blue = Color(0xFF035C4A);
  static const _blueDk = Color(0xFF02473A);
  static const _red = Color(0xFFB3261E);
  static const _green = Color(0xFF0A8F69);
  static const _bg = Color(0xFFF9F7F2);
  static const _card = Color(0xFFF3F2ED);
  static const _ink = Color(0xFF2A323E);
  static const _muted = Color(0xFF535E62);
  static const _outline = Color(0xFFC3C8C6);

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _confirmPinCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();

  bool _loading = false;
  bool _saving = false;
  String? _error;
  String? _success;
  bool _locationFetching = false;
  bool _codeEdited = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_syncSuggestedGymCode);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchLocation();
    });
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_syncSuggestedGymCode);
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _pinCtrl.dispose();
    _confirmPinCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  void _syncSuggestedGymCode() {
    if (_codeEdited) return;
    final suggestion = AdminService.suggestGymCode(_nameCtrl.text);
    if (suggestion.isEmpty) return;
    _codeCtrl.value = TextEditingValue(
      text: suggestion,
      selection: TextSelection.collapsed(offset: suggestion.length),
    );
  }

  Future<void> _fetchLocation() async {
    if (_locationFetching) return;
    setState(() {
      _locationFetching = true;
      _error = null;
    });
    try {
      final granted = await GeoService.requestPermission();
      if (!granted) {
        if (mounted) {
          setState(
            () => _error = 'Location permission is needed to auto-fill coordinates.',
          );
        }
        return;
      }

      final pos = await GeoService.currentPosition();
      if (pos != null && mounted) {
        setState(() {
          _latCtrl.text = pos.latitude.toString();
          _lngCtrl.text = pos.longitude.toString();
        });
      } else {
        if (mounted) {
          setState(
            () => _error = 'Could not fetch location. Please try again.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Location fetch failed: $e');
      }
    } finally {
      if (mounted) setState(() => _locationFetching = false);
    }
  }

  Future<void> _registerGym() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final code = AdminService.normalizeGymCode(_codeCtrl.text);
    final pin = _pinCtrl.text.trim();
    if (code.length < 3) {
      setState(() => _error = 'Gym code must be at least 3 characters.');
      return;
    }
    if (await AdminService.gymCodeExists(code)) {
      setState(() => _error = 'This gym code already exists.');
      return;
    }
    if (pin.length != 4 || int.tryParse(pin) == null) {
      setState(() => _error = 'PIN must be exactly 4 digits.');
      return;
    }
    if (pin != _confirmPinCtrl.text.trim()) {
      setState(() => _error = 'PINs do not match.');
      return;
    }
    final lat = double.tryParse(_latCtrl.text.trim());
    final lng = double.tryParse(_lngCtrl.text.trim());
    if (lat == null || lng == null) {
      setState(() => _error = 'Please provide valid latitude and longitude.');
      return;
    }

    setState(() => _saving = true);
    try {
      // Create a new gym document with auto-generated ID
      final docRef = await AdminService.db.collection('gyms').add({
        'name': name,
        'gymCode': code,
        'gymCodeNormalized': code,
        'latitude': lat,
        'longitude': lng,
        'radiusMeters': 50,
        'adminPins': [pin],
      });

      final gymId = docRef.id;

      // Save admin session
      await AuthPrefs.save(
        memberId: 'admin',
        memberName: 'Admin',
        gymId: gymId,
        isAdmin: true,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AdminDashboardScreen(gymId: gymId)),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Registration failed: $e';
        });
      }
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
        title: const Text(
          'Register New Gym',
          style: TextStyle(fontWeight: FontWeight.w700, color: _ink),
        ),
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
                    _textField(
                      controller: _nameCtrl,
                      label: 'Gym Name',
                      icon: Icons.store_outlined,
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 12),
                    _textField(
                      controller: _codeCtrl,
                      label: 'Gym Code',
                      icon: Icons.qr_code_2_outlined,
                      onChanged: (_) => _codeEdited = true,
                      validator: (v) {
                        final code = AdminService.normalizeGymCode(v ?? '');
                        if (code.isEmpty) return 'Code is required';
                        if (code.length < 3) return 'Use at least 3 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    _sectionLabel('Admin PIN'),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _pinCtrl,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 20,
                        letterSpacing: 8,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        labelText: 'PIN',
                        labelStyle: TextStyle(color: _muted),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: _blue,
                        ),
                        filled: true,
                        fillColor: _card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: _outline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: _outline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: _blue,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmPinCtrl,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 20,
                        letterSpacing: 8,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Confirm PIN',
                        labelStyle: TextStyle(color: _muted),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: _blue,
                        ),
                        filled: true,
                        fillColor: _card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: _outline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: _outline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: _blue,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _sectionLabel('Location'),
                    const SizedBox(height: 4),
                    Text(
                      "We'll use your device's location to set the gym's coordinates.",
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _textField(
                            controller: _latCtrl,
                            label: 'Latitude',
                            icon: Icons.my_location_outlined,
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            validator: (v) {
                              if (v!.trim().isEmpty) return 'Required';
                              if (double.tryParse(v.trim()) == null)
                                return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _textField(
                            controller: _lngCtrl,
                            label: 'Longitude',
                            icon: Icons.my_location_outlined,
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            validator: (v) {
                              if (v!.trim().isEmpty) return 'Required';
                              if (double.tryParse(v.trim()) == null)
                                return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _locationFetching ? null : _fetchLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _blue.withOpacity(0.1),
                          foregroundColor: _blue,
                          side: BorderSide(color: _blue.withOpacity(0.3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: _locationFetching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: _blue,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.my_location_outlined),
                        label: Text(
                          _locationFetching
                              ? 'Fetching coordinates...'
                              : 'Auto Fetch Current Coordinates',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _red.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _red.withOpacity(0.25)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: _red,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: _red,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_success != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _green.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _green.withOpacity(0.25)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: _green,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _success!,
                                style: TextStyle(color: _green, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_blue, _blueDk],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: _blue.withOpacity(0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _saving ? null : _registerGym,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Register Gym',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
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
    child: Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: _blue,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    ),
  );

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: _ink, fontSize: 15),
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _muted),
        prefixIcon: Icon(icon, color: _blue, size: 20),
        filled: true,
        fillColor: _card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: _red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: _red, width: 1),
        ),
        errorStyle: const TextStyle(color: _red),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
      ),
    );
  }
}
