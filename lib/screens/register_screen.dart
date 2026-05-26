// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/basic_gym.dart';
import '../services/attendance_service.dart';
import '../services/firebase_service.dart';
import '../services/auth_prefs.dart';
import '../widgets/fitness_factor_logo.dart';
import 'home_screen.dart';

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
  static const _outlineDark = Color(0xFFA0A8A5);
  static const _surface = Color(0xFFE0E4E2);
  static const _success = Color(0xFF0A8F69);

  final _formKey         = GlobalKey<FormState>();
  final _nameCtrl        = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _passwordCtrl    = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _phoneCtrl       = TextEditingController();
  final _emergencyCtrl   = TextEditingController();
  final _aadhaarCtrl     = TextEditingController();
  final _aadhaarNameCtrl = TextEditingController();

  String    _membershipType  = 'Basic';
  String    _gender          = 'Male';
  DateTime? _dob;
  bool      _loading         = false;
  bool      _googleLoading   = false;
  bool      _usingGoogleAccount = false;
  bool      _passwordObscured = true;
  bool      _aadhaarObscured = true;
  String?   _error;

  final _memberships = ['Basic', 'Premium', 'VIP'];
  final _genders     = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _emailCtrl.text = widget.initialEmail;
    _nameCtrl.text = widget.initialName;
    _usingGoogleAccount = widget.useCurrentFirebaseUser;
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passwordCtrl.dispose(); _confirmPassCtrl.dispose();
    _phoneCtrl.dispose();
    _emergencyCtrl.dispose(); _aadhaarCtrl.dispose();
    _aadhaarNameCtrl.dispose();
    super.dispose();
  }

  String? _validateAadhaar(String? v) {
    if (v == null || v.trim().isEmpty) return 'Aadhaar number is required';
    final digits = v.replaceAll(' ', '');
    if (digits.length != 12) return 'Aadhaar must be exactly 12 digits';
    if (!RegExp(r'^[2-9][0-9]{11}$').hasMatch(digits)) {
      return 'Invalid Aadhaar — must start with 2–9, digits only';
    }
    return null;
  }

  String _formatAadhaar(String raw) {
    final digits = raw.replaceAll(' ', '');
    final buf = StringBuffer();
    for (int i = 0; i < digits.length && i < 12; i++) {
      if (i == 4 || i == 8) buf.write(' ');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  String _maskAadhaar(String formatted) {
    final digits = formatted.replaceAll(' ', '');
    if (digits.length < 12) return formatted;
    return 'XXXX XXXX ${digits.substring(8)}';
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _blue,
            onPrimary: Colors.white,
            surface: _card,
            onSurface: _ink,
          ),
          dialogTheme: const DialogThemeData(backgroundColor: _card),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
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

  String? _validateConfirmPassword(String? value) {
    if (_usingGoogleAccount) return null;
    if (value != _passwordCtrl.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _useGoogleAccount() async {
    setState(() { _googleLoading = true; _error = null; });
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
        final name = result['name'] as String? ?? '';
        if (_nameCtrl.text.trim().isEmpty) _nameCtrl.text = name;
      });
      return;
    }

    await _openHome(result);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      setState(() => _error = 'Please select your date of birth.');
      return;
    }
    setState(() { _loading = true; _error = null; });

    final result = await AttendanceService.register(
      email:            _emailCtrl.text.trim(),
      password:         _usingGoogleAccount ? null : _passwordCtrl.text,
      useCurrentFirebaseUser: _usingGoogleAccount,
      name:             _nameCtrl.text.trim(),
      phone:            _phoneCtrl.text.trim(),
      emergencyContact: _emergencyCtrl.text.trim(),
      membershipType:   _membershipType,
      gender:           _gender,
      dateOfBirth:      _dob!,
      gymId:            BasicGymConfig.gymId,
      aadhaarNumber:    _aadhaarCtrl.text.replaceAll(' ', ''),
      aadhaarName:      _aadhaarNameCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result == null || result.containsKey('error')) {
      setState(() => _error = result?['error'] ?? 'Registration failed. Try again.');
      return;
    }

    await _openHome(result);
  }

  Future<void> _openHome(Map<String, dynamic> result) async {
    FirebaseService.setMemberId(result['memberId']);
    await AuthPrefs.save(
      memberId:   result['memberId'],
      memberName: result['name'],
      gymId:      result['gymId'],
    );
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen(
        memberId:   result['memberId'],
        memberName: result['name'],
        gymId:      result['gymId'],
      )),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Positioned(
            top: -60, right: -60,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _blue.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 40, left: -60,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _blue.withOpacity(0.05),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // App bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: _ink, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text('Create Account',
                          style: TextStyle(color: _ink, fontSize: 18,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              const FitnessFactorLogo(size: 48),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Fitness Factor',
                                      style: TextStyle(color: _ink, fontSize: 16,
                                          fontWeight: FontWeight.w800)),
                                  Text('New Member Registration',
                                      style: TextStyle(color: _muted, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          _sectionLabel('Account Access'),
                          const SizedBox(height: 12),
                          _field(
                            controller: _emailCtrl,
                            label: 'Email Address',
                            hint: 'member@example.com',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                          ),
                          if (_usingGoogleAccount) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _blue.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _blue.withOpacity(0.18)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.g_mobiledata,
                                      color: _blue, size: 30),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Google account selected. No password is needed.',
                                      style: TextStyle(color: _muted, fontSize: 12),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => setState(
                                        () => _usingGoogleAccount = false),
                                    child: const Text('Use password'),
                                  ),
                                ],
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
                                  color: _muted, size: 20,
                                ),
                                onPressed: () => setState(
                                    () => _passwordObscured = !_passwordObscured),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _field(
                              controller: _confirmPassCtrl,
                              label: 'Confirm Password',
                              hint: 'Repeat password',
                              icon: Icons.lock_reset_outlined,
                              obscureText: _passwordObscured,
                              validator: _validateConfirmPassword,
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
                                    : const Icon(Icons.g_mobiledata, size: 28),
                                label: Text(_googleLoading
                                    ? 'Opening Google...'
                                    : 'Use Google Account'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _ink,
                                  side: const BorderSide(color: _outline),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),

                          _sectionLabel('Personal Information'),
                          const SizedBox(height: 12),
                          _field(controller: _nameCtrl, label: 'Full Name',
                              hint: 'e.g. Ahmad bin Ali', icon: Icons.person_outline,
                              validator: (v) => v!.trim().isEmpty ? 'Name is required' : null),
                          const SizedBox(height: 12),
                          _field(controller: _phoneCtrl, label: 'Phone Number',
                              hint: '+60 12-345 6789', icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (v) {
                                if (v!.trim().isEmpty) return 'Phone is required';
                                if (v.trim().length < 8) return 'Enter a valid phone number';
                                return null;
                              }),
                          const SizedBox(height: 12),

                          // DOB
                          _label('Date of Birth'),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _pickDob,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 15),
                              decoration: BoxDecoration(
                                color: _card,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _dob != null
                                      ? _blue.withOpacity(0.5)
                                      : _outline,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.cake_outlined,
                                      color: _dob != null ? _blue : _muted, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _dob != null
                                          ? DateFormat('dd MMM yyyy').format(_dob!)
                                          : 'Select date of birth',
                                      style: TextStyle(
                                        color: _dob != null ? _ink : _muted,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  if (_dob != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _blue.withOpacity(0.10),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(_age(_dob!),
                                          style: const TextStyle(color: _blue,
                                              fontSize: 12, fontWeight: FontWeight.w600)),
                                    ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.edit_outlined, color: _muted, size: 16),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Gender
                          _label('Gender'),
                          const SizedBox(height: 8),
                          Row(
                            children: _genders.map((g) {
                              final sel = _gender == g;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _gender = g),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    margin: EdgeInsets.only(
                                        right: g != _genders.last ? 8 : 0),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: sel ? _blue.withOpacity(0.08) : _card,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: sel ? _blue : _outline,
                                        width: sel ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Text(g,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: sel ? _blue : _muted,
                                        fontSize: 14,
                                        fontWeight: sel
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),

                          _sectionLabel('Membership Plan'),
                          const SizedBox(height: 12),
                          ..._memberships.map(_membershipTile),
                          const SizedBox(height: 24),

                          _sectionLabel('Emergency Contact'),
                          const SizedBox(height: 12),
                          _field(controller: _emergencyCtrl,
                              label: 'Emergency Contact Number',
                              hint: '+60 11-234 5678',
                              icon: Icons.emergency_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (v) => v!.trim().isEmpty
                                  ? 'Emergency contact is required'
                                  : null),
                          const SizedBox(height: 24),

                          _sectionLabel('Aadhaar Details'),
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
                                    'Aadhaar details are stored securely. Only last 4 digits are visible after submission.',
                                    style: TextStyle(color: _muted, fontSize: 12,
                                        height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _field(controller: _aadhaarNameCtrl,
                              label: 'Name as on Aadhaar',
                              hint: 'Full name exactly as on Aadhaar card',
                              icon: Icons.badge_outlined,
                              validator: (v) => v!.trim().isEmpty
                                  ? 'Name as on Aadhaar is required'
                                  : null),
                          const SizedBox(height: 12),
                          _label('Aadhaar Number'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _aadhaarCtrl,
                            keyboardType: TextInputType.number,
                            obscureText: _aadhaarObscured,
                            style: const TextStyle(
                              color: _ink, fontSize: 18,
                              letterSpacing: 2, fontWeight: FontWeight.w600,
                            ),
                            maxLength: 14,
                            onChanged: (v) {
                              final formatted = _formatAadhaar(v);
                              if (formatted != v) {
                                _aadhaarCtrl.value = TextEditingValue(
                                  text: formatted,
                                  selection: TextSelection.collapsed(
                                      offset: formatted.length),
                                );
                              }
                            },
                            validator: _validateAadhaar,
                            decoration: InputDecoration(
                              hintText: 'XXXX XXXX XXXX',
                              hintStyle: TextStyle(
                                  color: _muted.withOpacity(0.5), letterSpacing: 2),
                              prefixIcon: const Icon(Icons.credit_card_outlined,
                                  color: _blue),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _aadhaarObscured
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: _muted, size: 20,
                                ),
                                onPressed: () => setState(
                                    () => _aadhaarObscured = !_aadhaarObscured),
                              ),
                              filled: true,
                              fillColor: _card,
                              counterText: '',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    BorderSide(color: _outline),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    BorderSide(color: _outline),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    const BorderSide(color: _blue, width: 1.5),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    const BorderSide(color: _red, width: 1),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    const BorderSide(color: _red, width: 1.5),
                              ),
                              errorStyle: const TextStyle(color: _red),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 15),
                            ),
                          ),
                          if (_aadhaarCtrl.text.replaceAll(' ', '').length == 12)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: _success, size: 14),
                                  const SizedBox(width: 6),
                                  Text(_maskAadhaar(_aadhaarCtrl.text),
                                      style: const TextStyle(
                                        color: _success, fontSize: 13,
                                        letterSpacing: 1.5,
                                        fontWeight: FontWeight.w600,
                                      )),
                                  const SizedBox(width: 8),
                                  Text('Valid format',
                                      style: TextStyle(
                                          color: _muted, fontSize: 12)),
                                ],
                              ),
                            ),

                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _red.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: _red.withOpacity(0.25)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: _red, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(_error!,
                                        style: const TextStyle(
                                            color: _red, fontSize: 13)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 32),

                          SizedBox(
                            width: double.infinity, height: 54,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [_blue, _blueDk]),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: _blue.withOpacity(0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _loading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                child: _loading
                                    ? const SizedBox(width: 22, height: 22,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5))
                                    : Text(_usingGoogleAccount
                                        ? 'Complete Google Registration'
                                        : 'Create Account',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16)),
                              ),
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
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(label.toUpperCase(),
        style: const TextStyle(color: _blue, fontSize: 11,
            fontWeight: FontWeight.w700, letterSpacing: 1.4)),
  );

  Widget _label(String label) => Text(label,
      style: const TextStyle(color: _ink, fontSize: 13,
          fontWeight: FontWeight.w600));

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: const TextStyle(color: _ink, fontSize: 15),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _muted.withOpacity(0.5)),
            prefixIcon: Icon(icon, color: _blue, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: _card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _blue, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _red, width: 1.5),
            ),
            errorStyle: const TextStyle(color: _red),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          ),
        ),
      ],
    );
  }

  Widget _membershipTile(String type) {
    final sel = _membershipType == type;
    final details = {
      'Basic':   {'price': 'RM 80 / month',  'perks': 'Gym access • Auto attendance',        'icon': Icons.star_outline},
      'Premium': {'price': 'RM 150 / month', 'perks': 'All Basic • Classes • Locker',         'icon': Icons.star_half},
      'VIP':     {'price': 'RM 250 / month', 'perks': 'All Premium • PT sessions • Priority', 'icon': Icons.star},
    };
    final d = details[type]!;
    return GestureDetector(
      onTap: () => setState(() => _membershipType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: sel ? _blue.withOpacity(0.06) : _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: sel ? _blue : _outline,
            width: sel ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: sel ? _blue.withOpacity(0.12) : _surface,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(d['icon'] as IconData,
                  color: sel ? _blue : _muted, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type,
                      style: TextStyle(
                          color: sel ? _ink : _muted,
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(d['perks'] as String,
                      style: TextStyle(color: _muted, fontSize: 12)),
                ],
              ),
            ),
            Text(d['price'] as String,
                style: TextStyle(
                    color: sel ? _blue : _muted,
                    fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: sel ? _blue : Colors.transparent,
                border: Border.all(
                    color: sel ? _blue : _outlineDark, width: 2),
              ),
              child: sel
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  String _age(DateTime dob) => '${DateTime.now().year - dob.year} yrs';
}

