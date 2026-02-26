import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  
  late AnimationController _animationController;
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    _performAuthAction(() => _authService.login(
      _emailController.text,
      _passwordController.text,
    ));
  }

  Future<void> _handleGoogleSignIn() async {
    _performAuthAction(() => _authService.signInWithGoogle());
  }

  Future<void> _performAuthAction(Future<void> Function() action) async {
    setState(() => _isLoading = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/malaysia_flag.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color.fromARGB(255, 73, 83, 185).withOpacity(0.90),
                    const Color.fromARGB(255, 72, 168, 157).withOpacity(0.85),
                    const Color.fromARGB(255, 83, 130, 201).withOpacity(0.90),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildAnimatedHeader(),

                      const SizedBox(height: 40),

                      _buildTextField(
                        controller: _emailController,
                        label: "Email Address",
                        icon: Icons.email_outlined,
                        validator: (val) => (val == null || !val.contains('@')) ? "Enter a valid email" : null,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _passwordController,
                        label: "Password",
                        icon: Icons.lock_outline,
                        obscureText: !_isPasswordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.indigo.shade900),
                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                        validator: (val) => (val == null || val.length < 6) ? "Minimum 6 characters" : null,
                      ),
                      
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text("Forgot Password?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            backgroundColor: Colors.indigo.shade900,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                          ),
                          child: _isLoading 
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                              : const Text("SIGN IN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white.withOpacity(0.5))),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text("OR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          Expanded(child: Divider(color: Colors.white.withOpacity(0.5))),
                        ],
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                          icon: Image.asset('assets/google_logo.webp', height: 18),
                          label: const Text("Continue with Google", style: TextStyle(color: Colors.black87, fontSize: 16)),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account?", style: TextStyle(color: Colors.white70)),
                          TextButton(
                            onPressed: () {}, 
                            child: const Text("Create Account", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return FadeTransition(
      opacity: _animationController,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            ),
            child: const Icon(Icons.location_city_rounded, size: 70, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text(
            'AidCess',
            style: TextStyle(
              fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2.0,
              shadows: [Shadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 4))]
            ),
          ),
          const Text(
            'Accessible Path Planning',
            style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        prefixIcon: Icon(icon, color: Colors.indigo.shade900),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      validator: validator,
    );
  }
}