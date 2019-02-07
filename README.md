# Flutter image_tap_coordinates

A Flutter package to provide tap coordinates relative to the image pixels size.

Based on [flutter zoomable_image](https://github.com/perlatus/flutter_zoomable_image).

## Getting Started

1. Add to your pubspec.yaml file:

```
image_tap_coordinates:
  git:
    url: git://github.com/georgerappel/flutter_image_tap_coordinates

```

2. Import:

```
import 'package:image_tap_coordinates/image_tap_coordinates.dart';
```

3. Use:

```
ImageTapCoordinates(
  AssetImage('images/filename.abc'), // You can use any ImageProvider
  placeholder: const Center(child: const CircularProgressIndicator()),
  backgroundColor: Colors.red,
  tapCallback: (Offset tapCoordinates){
    print("Tao on " + tapCoordinates.toString());
  },
)
```

