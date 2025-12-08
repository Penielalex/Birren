import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_style.dart';

class LimitCard extends StatefulWidget {
  final VoidCallback onSetLimit;
  final String dailyLimit;
  final String monthLimit;
  final String yearlyLimit;

  const LimitCard({
    super.key,
    required this.onSetLimit,
    required this.dailyLimit,
    required this.monthLimit,
    required this.yearlyLimit,
  });

  @override
  State<LimitCard> createState() => _LimitCardState();
}

class _LimitCardState extends State<LimitCard> {
  final CarouselSliderController _carouselController = CarouselSliderController();
  int _currentIndex = 0;

  final List<String> _titles = ["Daily Limit", "Monthly Limit", "Yearly Limit"];

  @override
  Widget build(BuildContext context) {
    final List<String> _values = [
      widget.dailyLimit,
      widget.monthLimit,
      widget.yearlyLimit
    ];

    return Card(
      color: AppColors.background,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Circle + carousel
            Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent,
                  ),
                  child: const Icon(Icons.money_off, color: Colors.white),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 120, // Adjust width to fit your design
                  child: CarouselSlider.builder(
                    carouselController: _carouselController,
                    itemCount: _titles.length,
                    itemBuilder: (context, index, realIndex) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_titles[index], style: AppTextStyles.midBody1),
                          const SizedBox(height: 4),
                          Text(_values[index], style: AppTextStyles.lightBody1),
                        ],
                      );
                    },
                    options: CarouselOptions(
                      height: 60, // Adjust height to fit content
                      autoPlay: true,
                      enlargeCenterPage: true,
                      viewportFraction: 1.0,
                      onPageChanged: (index, reason) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),

            // Right-side button
            TextButton(
              onPressed: widget.onSetLimit,
              child: Text(widget.dailyLimit == "0.00"?"Set Limit":"Edit Limit", style: AppTextStyles.smallButton2),
            ),
          ],
        ),
      ),
    );
  }
}
