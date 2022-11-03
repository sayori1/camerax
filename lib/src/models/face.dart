
import 'dart:convert';

Face faceFromJson(String str) => Face.fromJson(json.decode(str));

String faceToJson(Face data) => json.encode(data.toJson());

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
    });

    List<Landmark> landmarks;
    BoundingBox boundingBox;
    double headEulerAngleX;
    double headEulerAngleY;
    double headEulerAngleZ;
    double rightEyeOpenProbability;
    double leftEyeOpenProbability;
    double smilingProbability;

    factory Face.fromJson(Map<String, dynamic> json) => Face(
        landmarks: List<Landmark>.from(json["landmarks"].map((x) => Landmark.fromJson(x))),
        boundingBox: BoundingBox.fromJson(json["boundingBox"]),
        headEulerAngleX: json["headEulerAngleX"].toDouble(),
        headEulerAngleY: json["headEulerAngleY"].toDouble(),
        headEulerAngleZ: json["headEulerAngleZ"].toDouble(),
        rightEyeOpenProbability: json["rightEyeOpenProbability"].toDouble(),
        leftEyeOpenProbability: json["leftEyeOpenProbability"].toDouble(),
        smilingProbability: json["smilingProbability"].toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "landmarks": List<dynamic>.from(landmarks.map((x) => x.toJson())),
        "boundingBox": boundingBox.toJson(),
        "headEulerAngleX": headEulerAngleX,
        "headEulerAngleY": headEulerAngleY,
        "headEulerAngleZ": headEulerAngleZ,
        "rightEyeOpenProbability": rightEyeOpenProbability,
        "leftEyeOpenProbability": leftEyeOpenProbability,
        "smilingProbability": smilingProbability,
    };
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

    factory BoundingBox.fromJson(Map<String, dynamic> json) => BoundingBox(
        top: json["top"],
        bottom: json["bottom"],
        left: json["left"],
        right: json["right"],
    );

    Map<String, dynamic> toJson() => {
        "top": top,
        "bottom": bottom,
        "left": left,
        "right": right,
    };
}

class Landmark {
    Landmark({
        required this.type,
        required this.point,
    });

    int type;
    Point point;

    factory Landmark.fromJson(Map<String, dynamic> json) => Landmark(
        type: json["type"],
        point: Point.fromJson(json["point"]),
    );

    Map<String, dynamic> toJson() => {
        "type": type,
        "point": point.toJson(),
    };
}

class Point {
    Point({
        required this.x,
        required this.y,
    });

    double x;
    double y;

    factory Point.fromJson(Map<String, dynamic> json) => Point(
        x: json["x"].toDouble(),
        y: json["y"].toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "x": x,
        "y": y,
    };
}