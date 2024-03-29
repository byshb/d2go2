//// Copyright (c) 2020 Facebook, Inc. and its affiliates.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.

import UIKit

struct Prediction {
  let classIndex: Int
  let score: Float
  let rect: CGRect
}

class PrePostProcessor : NSObject {
    // model input image size
    static let inputWidth = 640
    static let inputHeight = 640

    static let outputColumn = 6 // left, top, right, bottom, label, and score
    static let threshold : Float = 0.5 // score above which a detection is generated

    static func cleanDetection(imageView: UIImageView) {
        if let layers = imageView.layer.sublayers {
            for layer in layers {
                if layer is CATextLayer {
                    layer.removeFromSuperlayer()
                }
            }
            for view in imageView.subviews {
                view.removeFromSuperview()
            }
        }
    }
    
    static func outputsToPredictions(image: UIImage, outputs: [NSNumber]) -> (UIImage?, [Prediction]) {
        var rects: [CGRect] = []
        var predictions = [Prediction]()
        for i in 0 ..< outputs.count / 6 {
            if Float(truncating: outputs[i * outputColumn + 4]) > 0.5 {
                let left = Double(truncating: outputs[i * outputColumn])
                let top = Double(truncating: outputs[i * outputColumn + 1])
                let right = Double(truncating: outputs[i * outputColumn + 2])
                let bottom = Double(truncating: outputs[i * outputColumn + 3])

                let x = left
                let y = top
                let width = right - left
                let height = bottom - top
                let rect = CGRect(x: x, y: y, width: width, height: height)
                rects.append(rect)

                let prediction = Prediction(classIndex: 1, score: Float(truncating: outputs[i*outputColumn+4]), rect: rect)
                predictions.append(prediction)
            }
        }
        return (drawRectanglesOnImage(image: image, rectangles: rects), predictions)
    }

    static func drawRectanglesOnImage(image: UIImage, rectangles: [CGRect]) -> UIImage? {
        // 开始一个图形上下文
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        // 在图形上下文中绘制原始图像
        image.draw(at: CGPoint.zero)
        // 获取当前的图形上下文
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        // 渲染矩形
        context.setFillColor(UIColor.red.withAlphaComponent(0.2).cgColor)
        for rect in rectangles {
            context.addRect(rect)
        }
        context.fillPath()
        // 从图形上下文中获取新的UIImage
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        // 结束图形上下文
        UIGraphicsEndImageContext()
        return newImage
    }

//    static func outputsToPredictions(outputs: [NSNumber], imgScaleX: Double, imgScaleY: Double, ivScaleX: Double, ivScaleY: Double, startX: Double, startY: Double) -> [Prediction] {
//        var predictions = [Prediction]()
//        for i in 0..<outputs.count / 6 {
//            if Float(truncating: outputs[i*outputColumn+4]) > threshold {
//                let left = imgScaleX * Double(truncating: outputs[i*outputColumn])
//                let top = imgScaleY * Double(truncating: outputs[i*outputColumn+1])
//                let right = imgScaleX * Double(truncating: outputs[i*outputColumn+2])
//                let bottom = imgScaleY * Double(truncating: outputs[i*outputColumn+3])
//                
//                let rect = CGRect(x: startX+ivScaleX*left, y: startY+top*ivScaleY, width: ivScaleX*(right-left), height: ivScaleY*(bottom-top))
//                
//                let prediction = Prediction(classIndex: Int(truncating: outputs[i*outputColumn+5]) - 1, score: Float(truncating: outputs[i*outputColumn+4]), rect: rect)
//                predictions.append(prediction)
//            }
//        }
//
//        return predictions
//    }
    
    static func showDetection(imageView: UIImageView, nmsPredictions:[Prediction], classes: [String]) {
        for prediction in nmsPredictions {
            let bbox = UIView(frame: prediction.rect)
            bbox.backgroundColor = UIColor.clear
            bbox.layer.borderColor = UIColor.yellow.cgColor
            bbox.layer.borderWidth = 2
            imageView.addSubview(bbox)
            
            let textLayer = CATextLayer()
            textLayer.string = String(format: " %@ %.2f", classes[prediction.classIndex], prediction.score)
            textLayer.foregroundColor = UIColor.white.cgColor
            textLayer.backgroundColor = UIColor.magenta.cgColor
            textLayer.fontSize = 14
            textLayer.frame = CGRect(x: prediction.rect.origin.x, y: prediction.rect.origin.y, width:100, height:20)
            imageView.layer.addSublayer(textLayer)
        }
    }
}
