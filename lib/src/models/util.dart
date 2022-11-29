import 'package:flutter/material.dart';

Size toSize(Map<dynamic, dynamic> data) {
  final width = data['width'];
  final height = data['height'];
  return Size(width, height);
}

List<Offset>? toCorners(List<dynamic>? data) {
  if (data != null) {
    return List.unmodifiable(data.map((e) => Offset(e['x'], e['y'])));
  } else {
    return null;
  }
}

