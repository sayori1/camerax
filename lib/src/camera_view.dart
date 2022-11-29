import 'package:flutter/material.dart';

import 'models/camera_args.dart';
import 'camera_controller.dart';

/// A widget showing a live camera preview.
class CameraXView extends StatelessWidget {
  /// The controller of the camera.
  final CameraXController controller;

  /// Create a [CameraXView] with a [controller], the [controller] must has been initialized.
  CameraXView(this.controller);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.args,
      builder: (context, value, child) => _build(context, value as CameraArgs?),
    );
  }

  Widget _build(BuildContext context, CameraArgs? value) {
    if (value == null) {
      return Container(color: Colors.black);
    } else {
      return ClipRect(
        child: Transform.scale(
          scale: value.size.fill(MediaQuery.of(context).size),
          child: Center(
            child: AspectRatio(
              aspectRatio: value.size.aspectRatio,
              child: Container(
                  color: Colors.white,
                  child: Texture(textureId: value.textureId)),
            ),
          ),
        ),
      );
    }
  }
}

extension on Size {
  double fill(Size targetSize) {
    if (targetSize.aspectRatio < aspectRatio) {
      return targetSize.height * aspectRatio / targetSize.width;
    } else {
      return targetSize.width / aspectRatio / targetSize.height;
    }
  }
}
