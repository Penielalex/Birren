import 'dart:math';

import 'package:birren/presentation/theme/colors.dart';
import 'package:flutter/material.dart';

class RoundedCardWithCircle extends StatefulWidget {
  final Widget child; // Main content inside the rounded card
  final Widget? circleChild; // Optional widget inside the top circle

  final Color circleColor;
  final double elevation;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const RoundedCardWithCircle({
    Key? key,
    required this.child,
    this.circleChild,

    this.circleColor = Colors.white,
    this.elevation = 4,
    this.backgroundColor = Colors.white,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
  }) : super(key: key);

  @override
  State<RoundedCardWithCircle> createState() => _RoundedCardWithCircleState();
}

class _RoundedCardWithCircleState extends State<RoundedCardWithCircle> with TickerProviderStateMixin{

  late AnimationController _spinController;
  late AnimationController _expandController;
  bool expandPhase = false;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Phase 2: Expand (half → full circle)
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _spinController.forward().then((_) {
      setState(() {
        expandPhase = true;
      });
      _expandController.forward();
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none, // allows the circle to overflow
      alignment: Alignment.topCenter,
      children: [
        // Main rounded container
        Container(
          width: double.infinity,
          //height: double.infinity,
          decoration: BoxDecoration(
            color: Color(0xFF262450),
            border: const Border(
              top: BorderSide(
                color: Color(0xFF524EAE), // Top border color
                width: 1,           // Thickness of top border
              ),
            ),

            //borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: widget.elevation,
                offset: const Offset(0, 2),
              ),
            ],
          ),

          child: widget.child,
        ),

        // Circle overlapping on top center
        Positioned(
          top: -100, // makes it go above
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.background,
            ),

            child: Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_spinController, _expandController]),
                builder: (context, child) {
                return CustomPaint(
                  painter: GradientArcPainter(
                    spinProgress: _spinController.value,
                    expandProgress: _expandController.value,
                    startColor: AppColors.accent,
                    endColor: Colors.green,
                  ),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.textPrimary.withOpacity(0.3)),

                      shape: BoxShape.circle,


                    ),
                    child: Center(child: Container(
                      width: 200 - 50, // subtract border thickness
                      height: 200 - 50,
                      decoration:  BoxDecoration(
                        border: Border.all(color: AppColors.textPrimary.withOpacity(0.3)),
                        color: AppColors.background, // trinner circle color
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: widget.circleChild)
                    ),),
                  ),
                );}
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class GradientArcPainter extends CustomPainter {
  final double spinProgress; // rotation progress (0–1)
  final double expandProgress; // expansion progress (0–1)
  final Color startColor;
  final Color endColor;


  GradientArcPainter({
    required this.spinProgress,
    required this.expandProgress,
    required this.startColor,
    required this.endColor,

  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = size.center(Offset.zero);
    final radius = size.width / 2.3;
    final sweepAngle = pi + (pi * expandProgress);
    final startAngle = spinProgress * 2 * pi;

    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: [startColor, endColor,startColor],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 25
      ..strokeCap = StrokeCap.round;



    // Draw only the curved segment
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(GradientArcPainter oldDelegate) =>
      oldDelegate.spinProgress != spinProgress ||
          oldDelegate.expandProgress != expandProgress;
}