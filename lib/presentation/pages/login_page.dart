import 'package:birren/presentation/controllers/auth_controller.dart';
import 'package:birren/presentation/theme/colors.dart';
import 'package:birren/presentation/theme/text_style.dart';
import 'package:birren/presentation/widgets/app_snackbar.dart';
import 'package:birren/presentation/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:get/get.dart';

import '../widgets/carousel_item.dart';
import 'app_root.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthController authController = Get.find<AuthController>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  bool _usePin = false;
  bool _isSubmitting = false;

  final List<Map<String, String>> slides = [
    {
      'image': 'assets/LGraph.png',
      'description': 'See an overview of how much money you spend each month.',
    },
    {
      'image': 'assets/RChatBubbles.png',
      'description':
          'Get transaction details directly from your bank messages.',
    },
    {
      'image': 'assets/LPhone.png',
      'description': 'Set limits on you daily spending.',
    },
  ];

  final CarouselSliderController _carouselController =
      CarouselSliderController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppSnackbar.showError('Enter your name');
      return;
    }

    String? pin;
    if (_usePin) {
      pin = _pinController.text.trim();
      final confirm = _confirmPinController.text.trim();
      if (pin.length < 4) {
        AppSnackbar.showError('PIN must be at least 4 digits');
        return;
      }
      if (pin != confirm) {
        AppSnackbar.showError('PINs do not match');
        return;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      await authController.loginWithName(name, pin: pin);
      Get.offAll(() => const AppRoot());
    } catch (e) {
      AppSnackbar.showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: height * 0.38,
                child: CarouselSlider.builder(
                  carouselController: _carouselController,
                  itemCount: slides.length,
                  itemBuilder: (context, index, realIndex) {
                    final slide = slides[index];
                    return CarouselItem(
                      imageUrl: slide['image']!,
                      description: slide['description']!,
                    );
                  },
                  options: CarouselOptions(
                    autoPlay: true,
                    enlargeCenterPage: true,
                    viewportFraction: 0.85,
                    aspectRatio: 4 / 5,
                    autoPlayInterval: const Duration(seconds: 5),
                    onPageChanged: (index, reason) {
                      setState(() => _currentIndex = index);
                    },
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: slides.asMap().entries.map((entry) {
                  return Container(
                    width: _currentIndex == entry.key ? 10.0 : 8.0,
                    height: _currentIndex == entry.key ? 10.0 : 8.0,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4.0,
                      vertical: 8.0,
                    ),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == entry.key
                          ? AppColors.accent
                          : Colors.grey.withOpacity(0.4),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text('Welcome to ብሬን!', style: AppTextStyles.headline2),
              const SizedBox(height: 8),
              Text(
                'Enter your name to get started.',
                style: AppTextStyles.body1,
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _nameController,
                      hintText: 'Your name',
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Protect app with PIN',
                        style: AppTextStyles.body1,
                      ),
                      subtitle: Text(
                        'Required each time you open the app',
                        style: AppTextStyles.lightBody1,
                      ),
                      value: _usePin,
                      activeColor: AppColors.accent,
                      onChanged: (value) => setState(() => _usePin = value),
                    ),
                    if (_usePin) ...[
                      CustomTextField(
                        controller: _pinController,
                        hintText: 'PIN (4+ digits)',
                        keyboardType: TextInputType.number,
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _confirmPinController,
                        hintText: 'Confirm PIN',
                        keyboardType: TextInputType.number,
                        obscureText: true,
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Get Started',
                                style: AppTextStyles.button1.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
