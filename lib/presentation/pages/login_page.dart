import 'package:birren/presentation/controllers/auth_controller.dart';
import 'package:birren/presentation/theme/colors.dart';
import 'package:birren/presentation/theme/text_style.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:get/get.dart';

import '../widgets/carousel_item.dart';
import '../widgets/custom_textfield.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {

  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthController authController = Get.find<AuthController>();
  final List<Map<String, String>> slides = [
    {
      'image': 'assets/LGraph.png',
      'description': 'See an overview of how much money you spend each month.',
    },
    {
      'image': 'assets/RChatBubbles.png',
      'description': 'Get transaction details directly from your bank messages.',
    },
    {
      'image': 'assets/LPhone.png',
      'description': 'Set limits on you daily spending.',
    },
  ];

  final CarouselSliderController _carouselController = CarouselSliderController();
  int _currentIndex = 0;


  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;



    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Carousel Section
              SizedBox(
                height: height * 0.5,
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
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: slides.asMap().entries.map((entry) {
                  return GestureDetector(
                    onTap: () => _carouselController.animateToPage(entry.key),
                    child: Container(
                      width: _currentIndex == entry.key ? 10.0 : 8.0,
                      height: _currentIndex == entry.key ? 10.0 : 8.0,
                      margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentIndex == entry.key
                            ? AppColors.accent
                            : Colors.grey.withOpacity(0.4),
                        boxShadow: [
                          BoxShadow(
                            color: _currentIndex == entry.key
                                ? AppColors.accent // shadow color
                                : Colors.black26, // default faint shadow
                            blurRadius: 6, // how soft the shadow is
                            spreadRadius: 2, // how far it spreads

                          ),
                        ],
                      ),

                    ),
                  );
                }).toList(),
              ),


              const SizedBox(height: 40),

              // Title
               Text(
                'Welcome to ብሬን!',
                style: AppTextStyles.headline2,
              ),
              const SizedBox(height: 10),
              Text(
                'Your insight to how you handle money.',
                style: AppTextStyles.body1
              ),

              const SizedBox(height: 50),

              // Continue with Google Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // TODO: handle Google sign-in
                  },
                  icon: Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/800px-Google_%22G%22_logo.svg.png?20230822192911',
                    height: 24,
                  ),
                  label:  Text(
                    'Continue with Google',
                    style: AppTextStyles.button1
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Continue as Guest
              TextButton(
                onPressed: () {
                  _showGuestDialog(context);
                },
                child:  Text(
                  'Continue as Guest',
                  style: AppTextStyles.button2
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showGuestDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // smaller radius
        ),
        title:  Text('Continue as Guest',style: AppTextStyles.headline1,),
        content:CustomTextField(
          controller: nameController,
          hintText: 'Full Name',
        ),


        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:  Text('Cancel', style: AppTextStyles.smallButton2),
          ),
          ElevatedButton(
            onPressed: () async {
              String name = nameController.text.trim();
              if (name.isNotEmpty) {

                await authController.loginAsGuest(name);

                Get.offAll(() => HomePage());
              }
            },
            child: Text('Continue', style: AppTextStyles.smallButton1)

          ),
        ],
      ),
    );
  }
}
