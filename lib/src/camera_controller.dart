import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:camerax/src/models/face.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'camera_args.dart';
import 'camera_facing.dart';
import 'torch_state.dart';
import 'util.dart';

/// A camera controller.
abstract class CameraController {
  ValueNotifier<CameraArgs?> get args;

  ValueNotifier<TorchState> get torchState;

  factory CameraController([CameraFacing facing = CameraFacing.back]) =>
      _CameraController(facing);

  Future<void> startAsync();

  void torch();

  void dispose();

  Stream<Face> get faces;

  //Executed each frame when a face is found
  Function(List<Face>)? onFaceFound;

  //Executed once when no person is found
  Function? onFaceNotFound;

  Size? size;
}

class _CameraController implements CameraController {
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
  @override
  final ValueNotifier<TorchState> torchState;

  bool torchable;
  late StreamController<Face> facesController;

  @override
  Stream<Face> get faces => facesController.stream;

  Size? size;

  bool faceFound = false;

  _CameraController(this.facing)
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
        
        if (onFaceFound != null) onFaceFound!(faces);
        break;
      case 'no_face':
        if (onFaceFound != null && faceFound) {
          faceFound = false;
          if (onFaceNotFound != null) onFaceNotFound!();
        }
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
    // Check authorization state.
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
  Function(List<Face>)? onFaceFound;

  @override
  Function? onFaceNotFound;
}
