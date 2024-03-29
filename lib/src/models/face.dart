import 'package:flutter/painting.dart';

class Face {
  Face({
    required this.landmarks,
    required this.boundingBox,
    required this.headEulerAngleX,
    required this.headEulerAngleY,
    required this.headEulerAngleZ,
    required this.rightEyeOpenProbability,
    required this.leftEyeOpenProbability,
    required this.smilingProbability,
    required this.contours,
  });

  List<Landmark> landmarks;
  BoundingBox boundingBox;
  double headEulerAngleX;
  double headEulerAngleY;
  double headEulerAngleZ;
  double rightEyeOpenProbability;
  double leftEyeOpenProbability;
  double smilingProbability;
  Contours? contours;

  factory Face.fromJson(Map<dynamic, dynamic> json) {
    if (json['contours']['face'] != null) {
      return Face(
          landmarks: List<Landmark>.from(
              json['landmarks'].map((x) => Landmark.fromJson(x))),
          boundingBox: BoundingBox.fromJson(json['boundingBox']),
          headEulerAngleX: json['headEulerAngleX'].toDouble(),
          headEulerAngleY: json['headEulerAngleY'].toDouble(),
          headEulerAngleZ: json['headEulerAngleZ'].toDouble(),
          rightEyeOpenProbability:
              (json['rightEyeOpenProbability'] ?? 0).toDouble(),
          leftEyeOpenProbability:
              (json['leftEyeOpenProbability'] ?? 0).toDouble(),
          smilingProbability: (json['smilingProbability'] ?? 0).toDouble(),
          contours: Contours(
            face: json['contours']['face']['points']
                .map<Offset>(
                    (x) => Offset(x['x'].toDouble(), x['y'].toDouble()))
                .toList(),
            leftEye: json['contours']['leftEye']['points']
                .map<Offset>(
                    (x) => Offset(x['x'].toDouble(), x['y'].toDouble()))
                .toList(),
            leftEyebrowBottom: json['contours']['leftEyebrowBottom']['points']
                .map<Offset>(
                    (x) => Offset(x['x'].toDouble(), x['y'].toDouble()))
                .toList(),
            lowerLipTop: json['contours']['lowerLipTop']['points']
                .map<Offset>(
                    (x) => Offset(x['x'].toDouble(), x['y'].toDouble()))
                .toList(),
            noseBottom: json['contours']['noseBottom']['points']
                .map<Offset>(
                    (x) => Offset(x['x'].toDouble(), x['y'].toDouble()))
                .toList(),
            noseBridge: json['contours']['noseBridge']['points']
                .map<Offset>(
                    (x) => Offset(x['x'].toDouble(), x['y'].toDouble()))
                .toList(),
            rightEye: json['contours']['rightEye']['points']
                .map<Offset>(
                    (x) => Offset(x['x'].toDouble(), x['y'].toDouble()))
                .toList(),
            rightEyebrowBottom: json['contours']['rightEyebrowBottom']['points']
                .map<Offset>(
                    (x) => Offset(x['x'].toDouble(), x['y'].toDouble()))
                .toList(),
            rightEyebrowTop: json['contours']['rightEyebrowTop']['points']
                .map<Offset>(
                    (x) => Offset(x['x'].toDouble(), x['y'].toDouble()))
                .toList(),
            upperLipBottom: json['contours']['upperLipBottom']['points']
                .map<Offset>(
                    (x) => Offset(x['x'].toDouble(), x['y'].toDouble()))
                .toList(),
            upperLipTop: json['contours']['upperLipTop']['points']
                .map<Offset>(
                    (x) => Offset(x['x'].toDouble(), x['y'].toDouble()))
                .toList(),
          ));
    } else {
      return Face(
        landmarks: List<Landmark>.from(
            json['landmarks'].map((x) => Landmark.fromJson(x))),
        boundingBox: BoundingBox.fromJson(json['boundingBox']),
        headEulerAngleX: json['headEulerAngleX'].toDouble(),
        headEulerAngleY: json['headEulerAngleY'].toDouble(),
        headEulerAngleZ: json['headEulerAngleZ'].toDouble(),
        rightEyeOpenProbability: json['rightEyeOpenProbability'].toDouble(),
        leftEyeOpenProbability: json['leftEyeOpenProbability'].toDouble(),
        smilingProbability: json['smilingProbability'].toDouble(),
        contours: null,
      );
    }
  }
}

class Contours {
  Contours({
    required this.face,
    required this.leftEye,
    required this.leftEyebrowBottom,
    required this.lowerLipTop,
    required this.noseBottom,
    required this.noseBridge,
    required this.rightEye,
    required this.rightEyebrowBottom,
    required this.rightEyebrowTop,
    required this.upperLipBottom,
    required this.upperLipTop,
  });

  late final List<Offset> face;
  late final List<Offset> leftEye;
  late final List<Offset> leftEyebrowBottom;
  late final List<Offset> lowerLipTop;
  late final List<Offset> noseBottom;
  late final List<Offset> noseBridge;
  late final List<Offset> rightEye;
  late final List<Offset> rightEyebrowBottom;
  late final List<Offset> rightEyebrowTop;
  late final List<Offset> upperLipBottom;
  late final List<Offset> upperLipTop;
}

class BoundingBox {
  BoundingBox({
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
  });

  int top;
  int bottom;
  int left;
  int right;

  factory BoundingBox.fromJson(Map<dynamic, dynamic> json) => BoundingBox(
        top: json['top'],
        bottom: json['bottom'],
        left: json['left'],
        right: json['right'],
      );

  Map<String, dynamic> toJson() => {
        'top': top,
        'bottom': bottom,
        'left': left,
        'right': right,
      };
}

class Landmark {
  Landmark({
    required this.type,
    required this.point,
  });

  int type;
  Offset point;

  factory Landmark.fromJson(Map<dynamic, dynamic> json) => Landmark(
      type: json['type'],
      point: Offset(json['point']['x'], json['point']['y']));
}
