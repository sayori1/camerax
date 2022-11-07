//
//  Util.swift
//  camerax
//
//  Created by 闫守旺 on 2021/2/6.
//

import UIKit
import AVFoundation
import Flutter
import Foundation
import MLKitFaceDetection
import MLKitVision

extension Error {
    func throwNative(_ result: FlutterResult) {
        let error = FlutterError(code: localizedDescription, message: nil, details: nil)
        result(error)
    }
}

extension CVBuffer {
    var image: UIImage {
        let ciImage = CIImage(cvPixelBuffer: self)
        let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent)
        return UIImage(cgImage: cgImage!)
    }
    
    var image1: UIImage {
        // Lock the base address of the pixel buffer
        CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags.readOnly)
        // Get the number of bytes per row for the pixel buffer
        let baseAddress = CVPixelBufferGetBaseAddress(self)
        // Get the number of bytes per row for the pixel buffer
        let bytesPerRow = CVPixelBufferGetBytesPerRow(self)
        // Get the pixel buffer width and height
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)
        // Create a device-dependent RGB color space
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        // Create a bitmap graphics context with the sample buffer data
        var bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue
        bitmapInfo |= CGImageAlphaInfo.premultipliedFirst.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
        //let bitmapInfo: UInt32 = CGBitmapInfo.alphaInfoMask.rawValue
        let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
        // Create a Quartz image from the pixel data in the bitmap graphics context
        let quartzImage = context?.makeImage()
        // Unlock the pixel buffer
        CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags.readOnly)
        // Create an image object from the Quartz image
        return  UIImage(cgImage: quartzImage!)
    }
}

extension UIDeviceOrientation {
    func imageOrientation(position: AVCaptureDevice.Position) -> UIImage.Orientation {
        switch self {
        case .portrait:
            return position == .front ? .leftMirrored : .right
        case .landscapeLeft:
            return position == .front ? .downMirrored : .up
        case .portraitUpsideDown:
            return position == .front ? .rightMirrored : .left
        case .landscapeRight:
            return position == .front ? .upMirrored : .down
        default:
            return .up
        }
    }
}

extension Face{
    var data: [String: Any?]{
        return [
            "headEulerAngleX": headEulerAngleX,
            "headEulerAngleY": headEulerAngleY,
            "headEulerAngleZ": headEulerAngleZ,
            "rightEyeOpenProbability": rightEyeOpenProbability,
            "leftEyeOpenProbability": leftEyeOpenProbability,
            "smilingProbability": smilingProbability,
            "boundingBox" : frame.data,
            "landmarks": landmarks.map({$0.data}),
            "contours": [
                "face": self.contour(ofType: .face)?.data,
                "leftEyebrowBottom": self.contour(ofType: .leftEyebrowBottom)?.data,
                "leftEyebrowTop": self.contour(ofType: .leftEyebrowTop)?.data,
                "lowerLipBottom": self.contour(ofType: .lowerLipBottom)?.data,
                "lowerLipTop": self.contour(ofType: .lowerLipTop)?.data,
                "noseBottom": self.contour(ofType: .noseBottom)?.data,
                "noseBridge": self.contour(ofType: .noseBridge)?.data,
                "rightEye": self.contour(ofType: .rightEye)?.data,
                "rightEyebrowBottom": self.contour(ofType: .rightEyebrowBottom)?.data,
                "rightEyebrowTop": self.contour(ofType: .rightEyebrowTop)?.data,
                "upperLipBottom": self.contour(ofType: .upperLipBottom)?.data,
                "upperLipTop": self.contour(ofType: .upperLipTop)?.data,
            ]
        ]
    }
}

extension CGRect{
    var data: [String: Any?]{
        return [
            "top": self.maxY,
            "bottom": self.minY,
            "left": self.minX,
            "right": self.maxX
        ]
    }
}

extension FaceLandmark{
    var data: [String: Any?]{
        return [
            "type": type,
            "point": position.data
        ]
    }
}

extension VisionPoint{
    var data:[String: CGFloat]{
        return [
            "x": x,
            "y": y
        ]
    }
}

extension FaceContour{
    var data:[String: Any?]{
        return [
            "points": self.points.map({$0.data})
        ]
    }
}