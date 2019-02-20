import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Signature for when a pointer that will trigger a tap has stopped contacting
/// the screen.
///
/// The tapCoordinates are relative to the X and Y coordinates of the screen.
typedef TapCoordinatesCallback = void Function(Offset tapCoordinates);


class ImageTapCoordinates extends StatefulWidget {

  final ImageProvider image;

  final double maxScale;

  final double minScale;

  /// Initial image scale. Must be between minScale and maxScale, otherwise
  /// will be ignored.
  /// If not present or null, the image will be fitted to the screen.
  final double initScale;

  final TapCoordinatesCallback tapCallback;

  final Color backgroundColor;

  /// Widget shown while loading the image. Tipically a [ProgressIndicator].
  final Widget placeholder;

  /// Whether the tapCallback function should be called if the tap was out of
  /// the image bounds.
  final bool callbackIfOffBounds;

  /// A controller that allows you to programatically set the image scale and
  /// position.
  final ImageTapController controller;


  ImageTapCoordinates(
    this.image, {
    Key key,
    /// Maximum ratio to blow up image pixels. A value of 2.0 means that the
    /// a single device pixel will be rendered as up to 4 logical pixels.
    this.maxScale = 2.0,
    this.minScale = 0.0,
    this.initScale,
    this.tapCallback,
    this.callbackIfOffBounds = true,
    this.backgroundColor = Colors.black,
    this.controller,
    /// Placeholder widget to be used while [image] is being resolved.
    this.placeholder,
  }) : assert(minScale > 0.0),
        super(key: key);

  @override
  _TapCoordinatesState createState() => _TapCoordinatesState();
}

// See /flutter/examples/layers/widgets/gestures.dart
class _TapCoordinatesState extends State<ImageTapCoordinates> {
  ImageTapController controller = ImageTapController();

  ImageStream _imageStream;
  ui.Image _image;
  Size _imageSize;
  RenderBox _box;

  Offset _startingFocalPoint;

  Offset _previousOffset;
  Offset _offset; // where the top left corner of the image is drawn

  double _previousScale;
  double _scale; // multiplier applied to scale the full image

  Orientation _previousOrientation;

  Size _canvasSize;

  @override
  void initState() {
    super.initState();
    if(widget.controller != null){
      controller = widget.controller;
    }
    controller.addListener(controllerListener);
  }

  void _centerAndResetScale() {
    _imageSize = Size(
      _image.width.toDouble(),
      _image.height.toDouble(),
    );

    if(widget.initScale != null && widget.initScale >= widget.minScale && widget.initScale <= widget.maxScale){
      _scale = widget.initScale;
    } else {
      _scale = math.min(
        _canvasSize.width / _imageSize.width,
        _canvasSize.height / _imageSize.height,
      );
    }

    Size fitted = Size(
      _imageSize.width * _scale,
      _imageSize.height * _scale,
    );

    Offset delta = _canvasSize - fitted;
    _offset = delta / 2.0; // Centers the image
  }

  void controllerListener(){
    if(controller.scale != null && controller.scale != _scale) {
      _scale = controller.scale;
//      Size fitted = Size(
//        _imageSize.width * _scale,
//        _imageSize.height * _scale,
//      );
//
//      Offset delta = _canvasSize - fitted;
//      _offset = delta / 2.0;
    }

    if(controller.center != null && controller.center != _offset) {
//      Offset newOffset = Offset(
//        controller.center.dx / 2 * _scale,
//        controller.center.dy / 2 * _scale,
//      );
//
//      _previousOffset = _offset;
      _offset = controller.center ;
      //TODO Correctly handle center changes.
    }

    if(this.mounted) {
      setState(() {});
    }
  }

  void _handleScaleStart(ScaleStartDetails d) {
    _startingFocalPoint = d.focalPoint;
    _previousOffset = _offset;
    _previousScale = _scale;
  }

  void _handleScaleUpdate(ScaleUpdateDetails d) {
    double newScale = _previousScale * d.scale;
    if (newScale > widget.maxScale || newScale < widget.minScale) {
      return;
    }

    // Ensure that item under the focal point stays in the same place despite zooming
    final Offset normalizedOffset =
        (_startingFocalPoint - _previousOffset) / _previousScale;
    final Offset newOffset = d.focalPoint - normalizedOffset * newScale;

    controller.update(newCenter: newOffset, newScale: newScale);

    setState(() {});
  }

  void _handleTapUp(TapUpDetails details){
    _box = context.findRenderObject();
    // Get tap position relative to the Widget wrapping the image
    Offset _tapPos = _box.globalToLocal(details.globalPosition);
    Offset tapCoordinates = Offset((_tapPos.dx - _offset.dx)/_scale, (_tapPos.dy - _offset.dy)/_scale);

    if(widget.tapCallback != null) {
      if(!widget.callbackIfOffBounds){
        if(tapCoordinates.dx < 0 || tapCoordinates.dx > _imageSize.width
          || tapCoordinates.dy < 0 || tapCoordinates.dy > _imageSize.height){
          return; // Return without calling if coordinates are off-bounds
        }
      }
      widget.tapCallback(tapCoordinates);
    }
  }

  @override
  Widget build(BuildContext ctx) {
    Widget paintWidget() {
      return new CustomPaint(
        child: new Container(color: widget.backgroundColor),
        foregroundPainter: new _ZoomableImagePainter(
          image: _image,
          offset: _offset,
          scale: _scale,
        ),
      );
    }

    if (_image == null) {
      return widget.placeholder ?? Center(child: CircularProgressIndicator());
    }

    return new LayoutBuilder(builder: (ctx, constraints) {
      Orientation orientation = MediaQuery.of(ctx).orientation;
      if (orientation != _previousOrientation) {
        _previousOrientation = orientation;
        _canvasSize = constraints.biggest;
        _centerAndResetScale();
      }

      return new GestureDetector(
        child: paintWidget(),
        onScaleStart: _handleScaleStart,
        onScaleUpdate: _handleScaleUpdate,
        onTapUp: _handleTapUp,
      );
    });
  }

  @override
  void didChangeDependencies() {
    if(_imageStream == null) {
      _resolveImage();
    }
    super.didChangeDependencies();
  }

  @override
  void reassemble() {
    _resolveImage(); // in case the image cache was flushed
    super.reassemble();
  }

  void _resolveImage() {
    _imageStream = widget.image.resolve(createLocalImageConfiguration(context));
    _imageStream.addListener(_handleImageLoaded);
  }

  void _handleImageLoaded(ImageInfo info, bool synchronousCall) {
    print("image loaded: $info");
    setState(() {
      _image = info.image;
    });
  }

  @override
  void dispose() {
    _imageStream.removeListener(_handleImageLoaded);
    controller.dispose();
    super.dispose();
  }
}

class _ZoomableImagePainter extends CustomPainter {
  const _ZoomableImagePainter({this.image, this.offset, this.scale});

  final ui.Image image;
  final Offset offset;
  final double scale;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    Size imageSize = new Size(image.width.toDouble(), image.height.toDouble());
    Size targetSize = imageSize * scale;

    paintImage(
      canvas: canvas,
      rect: offset & targetSize,
      image: image,
      fit: BoxFit.fill,
    );
  }

  @override
  bool shouldRepaint(_ZoomableImagePainter old) {
    return old.image != image || old.offset != offset || old.scale != scale;
  }
}

class ImageTapController extends ValueNotifier<ImageTapControllerValue> {
  ImageTapController({ Offset center })
    : super(ImageTapControllerValue(center: center, scale: 0));

  Offset get center => value.center;
  /// The image coordinates, in pixels, that should be centered on the screen.
  set center(Offset newCenter) {
    value = value.copyWith(center: newCenter);
  }

  double get scale => value.scale;
  /// Change the image scale
  set scale(double newScale) {
    value = value.copyWith(scale: newScale);
  }

  /// Update more than one variables at the same time. Recommended for
  /// better performance.
  void update({Offset newCenter, double newScale}){
    value = value.copyWith(
        center: newCenter ?? value.center,
        scale: newScale ?? value.scale
    );
  }
}

@immutable
class ImageTapControllerValue {
  const ImageTapControllerValue({
    @required this.center,
    @required this.scale,
  });

  final Offset center;
  final double scale;

  /// Creates a copy of this value but with the given fields replaced with the new values.
  ImageTapControllerValue copyWith({
    Offset center,
    double scale,
  }) {
    return ImageTapControllerValue(
        center: center ?? this.center,
        scale: scale ?? this.scale,
    );
  }
}


