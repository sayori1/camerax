import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'models/camera_args.dart';
import 'models/camera_facing.dart';
import 'models/face.dart';
import 'models/torch_state.dart';
import 'models/util.dart';

abstract class CameraXController {
  factory CameraXController([CameraFacing facing = CameraFacing.back]) =>
      _CameraXController(facing);

  Future<void> startAsync();
  Future<File> takePicture();

  void torch();
  void dispose();

  ValueNotifier<CameraArgs?> get args;
  Stream<List<Face>?> get faces;

  Size? size;
}

class _CameraXController implements CameraXController {
  //По этому каналу отправляем вызовы методов
  static const MethodChannel method =
      MethodChannel('yanshouwang.dev/camerax/method');

  //По этому каналу получаем события
  static const EventChannel event =
      EventChannel('yanshouwang.dev/camerax/event');

  static const undetermined = 0;
  static const authorized = 1;
  static const denied = 2;
  static const analyze_none = 0;
  static const analyze_face = 1;

  static int? id;
  static StreamSubscription? subscription;

  final CameraFacing facing;
  @override
  final ValueNotifier<CameraArgs?> args;
  final ValueNotifier<TorchState> torchState;

  @override
  Stream<List<Face>?> get faces => facesController.stream;
  late StreamController<List<Face>?> facesController;

  Size? size;
  String? path;
  bool torchable;
  bool faceFound = false;
  bool _isActive = false;

  _CameraXController(this.facing)
      : args = ValueNotifier(null),
        torchState = ValueNotifier(TorchState.off),
        torchable = false {
    // In case new instance before dispose.
    if (id != null) {
      stop();
    }
    id = hashCode;

    facesController = StreamController.broadcast(
      onListen: () => tryAnalyze(analyze_face),
      onCancel: () => tryAnalyze(analyze_none),
    );

    subscription =
        event.receiveBroadcastStream().listen((data) => handleEvent(data));
  }

  void handleEvent(Map<dynamic, dynamic> event) {
    final name = event['name'];
    final data = event['data'];
    print(name);
    switch (name) {
      case 'torchState':
        final state = TorchState.values[data];
        torchState.value = state;
        break;
      case 'face':
        faceFound = true;
        List<Face> faces = data.map<Face>((face) {
          return Face.fromJson(face);
        }).toList();
        facesController.add(faces);

        break;
      case 'no_face':
        facesController.add(null);
        break;
      case 'photoSuccess':
        path = data;
        break;
      case 'photoError':
        path = 'error';
        break;
      default:
        throw UnimplementedError();
    }
  }

  void tryAnalyze(int mode) {
    if (hashCode != id) {
      return;
    }
    method.invokeMethod('analyze', mode);
  }

  @override
  Future<void> startAsync() async {
    ensure('startAsync');
    var state = await method.invokeMethod('state');
    if (state == undetermined) {
      final result = await method.invokeMethod('request');
      state = result ? authorized : denied;
    }
    if (state != authorized) {
      throw PlatformException(code: 'NO ACCESS TO CAMERA');
    }
    // Start camera.
    final answer =
        await method.invokeMapMethod<String, dynamic>('start', facing.index);
    final textureId = answer?['textureId'];
    size = toSize(answer?['size']);
    args.value = CameraArgs(textureId, size!);
    torchable = answer?['torchable'];
  }

  @override
  void torch() {
    ensure('torch');
    if (!torchable) {
      return;
    }
    var state =
        torchState.value == TorchState.off ? TorchState.on : TorchState.off;
    method.invokeMethod('torch', state.index);
  }

  @override
  void dispose() {
    if (hashCode == id) {
      stop();
      subscription?.cancel();
      subscription = null;
      id = null;
    }
    facesController.close();
  }

  void stop() => method.invokeMethod('stop');

  void ensure(String name) {
    final message =
        'CameraController.$name called after CameraController.dispose\n'
        'CameraController methods should not be used after calling dispose.';
    assert(hashCode == id, message);
  }

  @override
  Future<File> takePicture() async {
    if (_isActive) throw Exception('The camera is capturing already');
    _isActive = true;

    await method.invokeMethod('cameraCapture');

    while (path == null) {
      await Future.delayed(Duration(milliseconds: 100));
    }
    if (path == 'error') throw Exception('Unable to make photo');

    var _path = path!;
    _isActive = false;
    path = null;

    return File.fromUri(Uri.parse(_path));
  }
}
