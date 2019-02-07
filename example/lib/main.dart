import 'package:flutter/material.dart';
import 'package:image_tap_coordinates/image_tap_coordinates.dart';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        body: ImageTapCoordinates(
          AssetImage('images/squirrel.jpg'),
          placeholder: const Center(child: const CircularProgressIndicator()),
          backgroundColor: Colors.red,
          tapCallback: (Offset tapCoordinates){
            print("Tao on " + tapCoordinates.toString());
          },
          initScale: 0.15,
          maxScale: 0.35,
          minScale: 0.05,
        ),
      ),
    ),
  );
}
