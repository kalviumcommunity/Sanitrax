import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../mainpage/home_page.dart';
import '../mainpage/admin_dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _auth = AuthService();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool hidePassword = true;

  Future<void> _routeByRole(User user) async {
    // Role is always derived from email/domain rules in AuthService.
    await _auth.ensureUserProfile(user, defaultRole: 'Resident');
    final role = await _auth.getUserRole(user.uid);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => role.toLowerCase() == 'admin'
            ? const AdminDashboardPage()
            : const HomePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              // Header
              Container(
                height: 200,
                decoration: const BoxDecoration(
                  color: Color(0xFF4A7C59),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    const Text(
                      'Welcome back',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Manage your neighborhood waste collection',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Body
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F7F2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Role is assigned automatically from your email domain.',
                        style: TextStyle(
                          color: Color(0xFF4A7C59),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Email Field
                    const Text(
                      'Email Address',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        hintText: 'Enter your email',
                        hintStyle: const TextStyle(color: Color(0xFFBBBBBB)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFEEEEEE),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFEEEEEE),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Password Field
                    const Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: passwordController,
                      obscureText: hidePassword,
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        hintStyle: const TextStyle(color: Color(0xFFBBBBBB)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFEEEEEE),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFEEEEEE),
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            hidePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: const Color(0xFF999999),
                          ),
                          onPressed: () =>
                              setState(() => hidePassword = !hidePassword),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A7C59),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          if (emailController.text.isEmpty ||
                              passwordController.text.isEmpty) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please fill all fields'),
                                ),
                              );
                            }
                            return;
                          }
                          try {
                            final user = await _auth.signIn(
                              emailController.text,
                              passwordController.text,
                            );
                            if (user != null) {
                              await _routeByRole(user);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error: $e")),
                              );
                            }
                          }
                        },
                        child: const Text(
                          'Login →',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Don\'t have an account? ',
                          style: TextStyle(color: Colors.black54, fontSize: 14),
                        ),
                        TextButton(
                          onPressed: () => showSignUpDialog(context),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Color(0xFF4A7C59),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    // Social Login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => googleSignIn(),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFEEEEEE),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.g_mobiledata,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFEEEEEE),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.fingerprint,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> googleSignIn() async {
    try {
      final user = await _auth.signInWithGoogle();
      if (user != null) {
        await _routeByRole(user);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void showSignUpDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool hidePass = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A7C59),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Full Name',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Enter your name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Email Address',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailCtrl,
                    decoration: InputDecoration(
                      hintText: 'Enter your email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Password',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passCtrl,
                    obscureText: hidePass,
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          hidePass ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () =>
                            setModalState(() => hidePass = !hidePass),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
                    ),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A7C59),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        if (nameCtrl.text.isEmpty ||
                            emailCtrl.text.isEmpty ||
                            passCtrl.text.isEmpty) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill all fields'),
                              ),
                            );
                          }
                          return;
                        }
                        try {
                          final user = await _auth.signUp(
                            emailCtrl.text,
                            passCtrl.text,
                            name: nameCtrl.text.trim(),
                            role: 'Resident',
                          );
                          if (user != null && mounted) {
                            Navigator.pop(context);
                            await _routeByRole(user);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e")),
                            );
                          }
                        }
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        try {
                          final user = await _auth.signInWithGoogle();
                          if (user != null && mounted) {
                            Navigator.pop(context);
                            await _routeByRole(user);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e")),
                            );
                          }
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.g_mobiledata, color: Colors.black54),
                          SizedBox(width: 10),
                          Text(
                            'Sign Up with Google',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
