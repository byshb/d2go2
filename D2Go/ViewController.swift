// Copyright (c) 2020 Facebook, Inc. and its affiliates.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var btnRun: UIButton!

    private var imgIndex = 0

    private var image: UIImage?
    private var inferencer = ObjectDetector()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func runTapped(_ sender: Any) {
        guard let image = image else {
            return
        }

        btnRun.isEnabled = false
        btnRun.setTitle("Running the model...", for: .normal)

        let wi = Int32(PrePostProcessor.inputWidth)
        let he = Int32(CGFloat(PrePostProcessor.inputHeight) * image.size.height / image.size.width)
        let resizedImage = image.resized(to: CGSize(width: CGFloat(wi), height: CGFloat(he)))
        guard var pixelBuffer = resizedImage.normalized() else {
            return
        }

        DispatchQueue.global().async {
            guard let outputs = self.inferencer.module.detect(image: &pixelBuffer, width: wi, height: he) else {
                return
            }
            let result =  PrePostProcessor.outputsToPredictions(image: image, outputs: outputs)
            
            DispatchQueue.main.async {
                self.imageView.image = result.0
                self.btnRun.isEnabled = true
                self.btnRun.setTitle("Detect", for: .normal)
                PrePostProcessor.showDetection(imageView: self.imageView, nmsPredictions: self.transformPredictions(oriPredictions: result.1, image: resizedImage), classes: self.inferencer.classes)
            }
        }
    }

    private func transformPredictions(oriPredictions: [Prediction], image: UIImage) -> [Prediction] {
        var predictions: [Prediction] = []

        for prediction in oriPredictions {
            // 图片实际放置的位置
            var width: CGFloat = 0
            var height: CGFloat = 0
            var x: CGFloat = 0
            var y: CGFloat = 0
            if (image.size.width / image.size.height) > (UIScreen.main.bounds.width / UIScreen.main.bounds.height) {
                width = UIScreen.main.bounds.width
                height = image.size.height / image.size.width * UIScreen.main.bounds.width
                x = 0
                y = (UIScreen.main.bounds.height - height) * 0.5
            } else {
                height = UIScreen.main.bounds.height
                width = image.size.width * UIScreen.main.bounds.height / image.size.height
                y = 0
                x = (UIScreen.main.bounds.width - width) * 0.5
            }
            // 计算缩放比例
            let scaleX = width / image.size.width
            let scaleY = height / image.size.height

            // 计算缩放后的CGRect
            let scaledRect = CGRect(
                x: prediction.rect.origin.x * scaleX + x,
                y: prediction.rect.origin.y * scaleY + y,
                width: prediction.rect.size.width * scaleX,
                height: prediction.rect.size.height * scaleY
            )
            predictions.append(Prediction(classIndex: 1, score: prediction.score, rect: scaledRect))
        }
        return predictions
    }

    @IBAction func photosTapped(_ sender: Any) {
        PrePostProcessor.cleanDetection(imageView: imageView)
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        present(imagePickerController, animated: true, completion: nil)
    }

    @IBAction func cameraTapped(_ sender: Any) {
        PrePostProcessor.cleanDetection(imageView: imageView)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = .camera
            present(imagePickerController, animated: true, completion: nil)
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        image = image!.resized(to: CGSize(width: CGFloat(PrePostProcessor.inputWidth), height: CGFloat(PrePostProcessor.inputHeight) * image!.size.height / image!.size.width))
        imageView.image = image
        dismiss(animated: true, completion: nil)
    }
}
