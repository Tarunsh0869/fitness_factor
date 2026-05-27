// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../services/attendance_service.dart';
import '../services/auth_prefs.dart';
import '../services/firebase_service.dart';
import '../services/guest_session_service.dart';
import '../widgets/fitness_factor_logo.dart';
import 'complete_profile_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String initialEmail;
  final String initialName;
  final bool useCurrentFirebaseUser;

  const RegisterScreen({
    super.key,
    this.initialEmail = '',
    this.initialName = '',
    this.useCurrentFirebaseUser = false,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _blue = Color(0xFF035C4A);
  static const _blueDk = Color(0xFF02473A);
  static const _red = Color(0xFFB3261E);
  static const _bg = Color(0xFFF9F7F2);
  static const _card = Color(0xFFF3F2ED);
  static const _ink = Color(0xFF2A323E);
  static const _muted = Color(0xFF535E62);
  static const _outline = Color(0xFFC3C8C6);

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  List<Map<String, String>> _gymOptions = const [];
  String? _selectedGymId;
  bool _loadingGyms = true;
  String? _gymLoadError;
  bool _loading = false;
  bool _googleLoading = false;
  bool _passwordObscured = true;
  bool _usingGoogleAccount = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.initialName;
    _emailCtrl.text = widget.initialEmail;
    _usingGoogleAccount = widget.useCurrentFirebaseUser;
    _loadGyms();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _useGoogleAccount() async {
    setState(() {
      _googleLoading = true;
      _error = null;
    });
    final result = await AttendanceService.signInWithGoogle();
    if (!mounted) return;
    setState(() => _googleLoading = false);

    if (result == null) {
      setState(() => _error = 'Google sign-in failed. Please try again.');
      return;
    }
    if (result.containsKey('error')) {
      setState(() => _error = result['error'] as String);
      return;
    }
    if (result['needsRegistration'] == true) {
      setState(() {
        _usingGoogleAccount = true;
        _emailCtrl.text = result['email'] as String? ?? '';
        if (_nameCtrl.text.trim().isEmpty) {
          _nameCtrl.text = result['name'] as String? ?? '';
        }
      });
      return;
    }

    await _openPostAuthFlow(result);
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (_usingGoogleAccount) return null;
    final password = value ?? '';
    if (password.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateConfirm(String? value) {
    if (_usingGoogleAccount) return null;
    if (value != _passwordCtrl.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _loadGyms() async {
    setState(() {
      _loadingGyms = true;
      _gymLoadError = null;
    });
    final gyms = await AttendanceService.registrationGyms();
    if (!mounted) return;

    if (gyms.isEmpty) {
      setState(() {
        _gymOptions = const [];
        _selectedGymId = null;
        _loadingGyms = false;
        _gymLoadError = 'No gyms available for registration right now.';
      });
      return;
    }

    final selectedStillValid = gyms.any((g) => g['id'] == _selectedGymId);
    setState(() {
      _gymOptions = gyms;
      _selectedGymId = selectedStillValid ? _selectedGymId : gyms.first['id'];
      _loadingGyms = false;
      _gymLoadError = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_loadingGyms) return;
    if (_selectedGymId == null || _selectedGymId!.isEmpty) {
      setState(() {
        _error = _gymLoadError ?? 'Please select your gym.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await AttendanceService.register(
      email: _emailCtrl.text.trim(),
      password: _usingGoogleAccount ? null : _passwordCtrl.text,
      useCurrentFirebaseUser: _usingGoogleAccount,
      displayName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      gymId: _selectedGymId,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (result == null || result.containsKey('error')) {
      setState(() => _error = result?['error'] ?? 'Registration failed.');
      return;
    }

    await _openPostAuthFlow(result);
  }

  Future<void> _openPostAuthFlow(Map<String, dynamic> result) async {
    final memberId = result['memberId'] as String;
    final memberName = ((result['name'] as String?) ?? 'Member').trim().isEmpty
        ? 'Member'
        : (result['name'] as String);
    final gymId = result['gymId'] as String? ?? '';

    FirebaseService.setMemberId(memberId);
    await _mergeGuestData(memberId);
    await AuthPrefs.save(
      memberId: memberId,
      memberName: memberName,
      gymId: gymId,
    );

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => CompleteProfileScreen(
          memberId: memberId,
          memberName: memberName,
          gymId: gymId,
        ),
      ),
      (_) => false,
    );
  }

  Future<void> _mergeGuestData(String memberId) async {
    final guest = await GuestSessionService.load();
    await AttendanceService.mergeGuestSessionData(
      memberId: memberId,
      starterWorkoutsCompleted: guest['starterWorkoutsCompleted'] as int,
      meaningfulActionCount: guest['meaningfulActionCount'] as int,
      lastAction: guest['lastAction'] as String,
    );
    await GuestSessionService.clear();
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
          'Create Account',
          style: TextStyle(fontWeight: FontWeight.w700, color: _ink),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: FitnessFactorLogo(size: 88)),
                const SizedBox(height: 14),
                const Text(
                  'Create your account now. You can complete your fitness profile after sign-in.',
                  style: TextStyle(color: _muted, fontSize: 14, height: 1.45),
                ),
                const SizedBox(height: 20),
                _field(
                  controller: _nameCtrl,
                  label: 'Display Name (Optional)',
                  hint: 'e.g. Alex',
                  icon: Icons.person_outline,
                  validator: (_) => null,
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _emailCtrl,
                  label: 'Email Address',
                  hint: 'member@example.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 12),
                _gymDropdown(),
                if (_usingGoogleAccount) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _blue.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _blue.withOpacity(0.2)),
                    ),
                    child: const Text(
                      'Google account is linked. Password is not required.',
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  _field(
                    controller: _passwordCtrl,
                    label: 'Password',
                    hint: 'Minimum 6 characters',
                    icon: Icons.lock_outline,
                    obscureText: _passwordObscured,
                    validator: _validatePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordObscured
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: _muted,
                        size: 20,
                      ),
                      onPressed: () => setState(
                        () => _passwordObscured = !_passwordObscured,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _field(
                    controller: _confirmCtrl,
                    label: 'Confirm Password',
                    hint: 'Repeat password',
                    icon: Icons.lock_reset_outlined,
                    obscureText: _passwordObscured,
                    validator: _validateConfirm,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _googleLoading ? null : _useGoogleAccount,
                      icon: _googleLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.g_mobiledata, size: 30),
                      label: Text(
                        _googleLoading
                            ? 'Opening Google...'
                            : 'Use Google Account',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _ink,
                        side: const BorderSide(color: _outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _error!,
                    style: const TextStyle(color: _red, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_blue, _blueDk]),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ElevatedButton(
                      onPressed:
                          (_loading || _loadingGyms || _gymOptions.isEmpty)
                          ? null
                          : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.4,
                              ),
                            )
                          : Text(
                              _usingGoogleAccount
                                  ? 'Continue with Google'
                                  : 'Create Account',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: _ink, fontSize: 15),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: _muted.withOpacity(0.5)),
        labelStyle: TextStyle(color: _muted),
        prefixIcon: Icon(icon, color: _blue, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _red, width: 1.5),
        ),
        errorStyle: const TextStyle(color: _red),
      ),
    );
  }

  Widget _gymDropdown() {
    if (_loadingGyms) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _outline),
        ),
        child: Row(
          children: const [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Loading gyms...',
                style: TextStyle(color: _muted, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    if (_gymOptions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _red.withOpacity(0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _gymLoadError ?? 'No gyms found.',
              style: const TextStyle(color: _red, fontSize: 12),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: OutlinedButton(
                onPressed: _loadGyms,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _blue,
                  side: const BorderSide(color: _outline),
                ),
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedGymId,
      isExpanded: true,
      iconEnabledColor: _muted,
      dropdownColor: _card,
      style: const TextStyle(color: _ink, fontSize: 15),
      items: _gymOptions.map((gym) {
        final name = gym['name'] ?? gym['id'] ?? '';
        final code = gym['code'] ?? '';
        final label = code.isEmpty ? name : '$name ($code)';
        return DropdownMenuItem<String>(
          value: gym['id'],
          child: Text(label, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedGymId = value),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Select your gym';
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Select Gym',
        hintText: 'Choose your gym',
        hintStyle: TextStyle(color: _muted.withOpacity(0.5)),
        labelStyle: TextStyle(color: _muted),
        prefixIcon: const Icon(
          Icons.fitness_center_outlined,
          color: _blue,
          size: 20,
        ),
        filled: true,
        fillColor: _card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _red, width: 1.5),
        ),
        errorStyle: const TextStyle(color: _red),
      ),
    );
  }
}
