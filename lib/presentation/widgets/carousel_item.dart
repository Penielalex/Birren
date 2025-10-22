import 'package:birren/presentation/theme/text_style.dart';
import 'package:flutter/material.dart';

class CarouselItem extends StatelessWidget {
  final String imageUrl;
  final String description;

  const CarouselItem({
    Key? key,
    required this.imageUrl,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      //height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.transparent,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        //mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            flex:3,
            child: Image.asset(
              imageUrl,
              fit: BoxFit.contain,

            ),
          ),
          const SizedBox(height: 20),
          Flexible(
            flex:1,
            child: Text(
              description,
              style: AppTextStyles.headline1,
              textAlign: TextAlign.center,
            ),
          ),


        ],
      ),
    );
  }
}
