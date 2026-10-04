import 'package:flutter/material.dart';
import '../auth/auth_notifier.dart';

/// Minimal auth screen matching the GraceGrid design system.
///
/// Supports sign-in, sign-up, and password reset modes.
class AuthScreen extends StatefulWidget {
  final AuthNotifier authNotifier;

  const AuthScreen({super.key, required this.authNotifier});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

enum _AuthMode { signIn, signUp, resetPassword }

class _AuthScreenState extends State<AuthScreen> {
  _AuthMode _mode = _AuthMode.signIn;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      switch (_mode) {
        case _AuthMode.signIn:
          final result = await widget.authNotifier.signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
          if (mounted) {
            if (result.success) {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            } else {
              setState(() => _errorMessage = result.errorMessage);
            }
          }
          break;

        case _AuthMode.signUp:
          final result = await widget.authNotifier.signUp(
            email: _emailController.text,
            password: _passwordController.text,
            displayName: _nameController.text.trim().isNotEmpty
                ? _nameController.text
                : null,
          );
          if (mounted) {
            if (result.success) {
              if (widget.authNotifier.isAuthenticated) {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              } else {
                setState(() {
                  _successMessage =
                      'Account created! Check your email to confirm, then sign in.';
                  _mode = _AuthMode.signIn;
                  _passwordController.clear();
                });
              }
            } else {
              setState(() => _errorMessage = result.errorMessage);
            }
          }
          break;

        case _AuthMode.resetPassword:
          final result =
              await widget.authNotifier.resetPassword(_emailController.text);
          if (mounted) {
            if (result.success) {
              setState(() {
                _successMessage =
                    'Password reset email sent. Check your inbox.';
                _mode = _AuthMode.signIn;
              });
            } else {
              setState(() => _errorMessage = result.errorMessage);
            }
          }
          break;
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _switchMode(_AuthMode newMode) {
    setState(() {
      _mode = newMode;
      _errorMessage = null;
      _successMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue =
        isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
    final surfaceColor =
        isDark ? const Color(0xFF111827) : const Color(0xFFFFFFFF);
    final borderColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    String title;
    String submitLabel;
    switch (_mode) {
      case _AuthMode.signIn:
        title = 'Welcome Back';
        submitLabel = 'Sign In';
        break;
      case _AuthMode.signUp:
        title = 'Create Account';
        submitLabel = 'Sign Up';
        break;
      case _AuthMode.resetPassword:
        title = 'Reset Password';
        submitLabel = 'Send Reset Email';
        break;
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo + Title
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Image.asset(
                        isDark
                            ? 'assets/logo/gracegrid-symbol-dark.png'
                            : 'assets/logo/gracegrid-symbol-light.png',
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _mode == _AuthMode.signUp
                          ? 'Join the GraceGrid community'
                          : _mode == _AuthMode.resetPassword
                              ? 'Enter your email to reset your password'
                              : 'Sign in to access community features',
                      style: TextStyle(fontSize: 14, color: textSecondary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Success message
              if (_successMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_successMessage!,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.green)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFEF4444), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_errorMessage!,
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFFEF4444))),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Name field (sign up only)
              if (_mode == _AuthMode.signUp) ...[
                _buildLabel('Display Name', textSecondary),
                const SizedBox(height: 6),
                _buildInputContainer(
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  child: TextFormField(
                    controller: _nameController,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Your name',
                      hintStyle:
                          TextStyle(color: textSecondary.withValues(alpha: 0.6)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                      prefixIcon: Icon(Icons.person_outline,
                          size: 18, color: textSecondary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Email field
              _buildLabel('Email', textSecondary),
              const SizedBox(height: 6),
              _buildInputContainer(
                surfaceColor: surfaceColor,
                borderColor: borderColor,
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? const Color(0xFFF8FAFC)
                        : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'your@email.com',
                    hintStyle:
                        TextStyle(color: textSecondary.withValues(alpha: 0.6)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(14),
                    prefixIcon: Icon(Icons.email_outlined,
                        size: 18, color: textSecondary),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!val.contains('@') || !val.contains('.')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
              ),

              // Password field (not for reset)
              if (_mode != _AuthMode.resetPassword) ...[
                const SizedBox(height: 16),
                _buildLabel('Password', textSecondary),
                const SizedBox(height: 6),
                _buildInputContainer(
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: _mode == _AuthMode.signUp
                          ? 'At least 6 characters'
                          : 'Enter your password',
                      hintStyle: TextStyle(
                          color: textSecondary.withValues(alpha: 0.6)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                      prefixIcon: Icon(Icons.lock_outline,
                          size: 18, color: textSecondary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                          color: textSecondary,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (_mode == _AuthMode.signUp && val.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                ),
              ],

              // Forgot password link (sign in only)
              if (_mode == _AuthMode.signIn) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _switchMode(_AuthMode.resetPassword),
                    child: Text('Forgot password?',
                        style: TextStyle(
                            fontSize: 13,
                            color: primaryBlue,
                            fontWeight: FontWeight.w500)),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(submitLabel,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ),

              const SizedBox(height: 20),

              // Mode switch links
              Center(
                child: _mode == _AuthMode.signIn
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account? ",
                              style: TextStyle(
                                  fontSize: 13, color: textSecondary)),
                          GestureDetector(
                            onTap: () => _switchMode(_AuthMode.signUp),
                            child: Text('Sign Up',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: primaryBlue,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Already have an account? ',
                              style: TextStyle(
                                  fontSize: 13, color: textSecondary)),
                          GestureDetector(
                            onTap: () => _switchMode(_AuthMode.signIn),
                            child: Text('Sign In',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: primaryBlue,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Text(text,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: color));
  }

  Widget _buildInputContainer({
    required Color surfaceColor,
    required Color borderColor,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}
