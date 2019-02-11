import 'package:flutter/material.dart';
import 'package:image_tap_coordinates/image_tap_coordinates.dart';

void main() {

  ImageTapController controller = ImageTapController();

  runApp(
    MaterialApp(
      home: Scaffold(
        body: ImageTapCoordinates(
          AssetImage('images/squirrel.jpg'),
          placeholder: const Center(child: const CircularProgressIndicator()),
          backgroundColor: Colors.red,
          tapCallback: (Offset tapCoordinates){
            print("Tao on " + tapCoordinates.toString());
            print("Controller scale: " + controller.scale.toString());
            //controller.scale = 0.11;
            controller.scale = 0.12;
            controller.center = Offset(40,40);
          },
          maxScale: 0.35,
          minScale: 0.05,
          initScale: 0.10,
          controller: controller,
        ),
      ),
    ),
  );
}
