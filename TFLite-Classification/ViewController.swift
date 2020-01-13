//
//  ViewController.swift
//  TFLite-Classification
//
//  Created by Phoom Punpeng on 11/1/2563 BE.
//  Copyright © 2563 Phoom Punpeng. All rights reserved.
//

import UIKit
import AVKit
import Vision
import Firebase

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var outputLabel: UILabel!
    @IBOutlet weak var confidenceLabel: UILabel!
    
    @IBAction func reClassify(_ sender: UIButton) {
        viewDidLoad()
    }
    
    var uiImage: UIImage?
    var ciImage: CIImage?
    
    func getImage(fromSourceType sourceType: UIImagePickerController.SourceType) {
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = sourceType
            self.present(imagePickerController, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        guard let image = info[.editedImage] as? UIImage else {
            print("No image found")
            return
        }
        
        uiImage = image
        ciImage = CIImage(image: uiImage!)

        classify()
        print(image.size) // checking to see if it actually works.
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.allowsEditing = true
        vc.delegate = self
        present(vc, animated: true)
    }
    
    func classify() {
        
// Following code is commented, Firebase is having a bug where tflite models cannot be uploaded. Therefore, the model was imported directly to this project for now.
        
//        let remoteModel = CustomRemoteModel(
//          name: "your_remote_model"  // The model name in Firebase
//        )
        
//        let downloadConditions = ModelDownloadConditions(
//          allowsCellularAccess: true,
//          allowsBackgroundDownloading: true
//        )
//
//        let downloadProgress = ModelManager.modelManager().download(
//          remoteModel,
//          conditions: downloadConditions
//        )
        
        // Import local model: rock_paper_scissors.tflite
        guard let modelPath = Bundle.main.path(
          forResource: "rock_paper_scissors",
          ofType: "tflite"
        ) else {
            print("error 0")
            return }
        
        let ioOptions = ModelInputOutputOptions()
        do {
            try ioOptions.setInputFormat(index: 0, type: .float32, dimensions: [1, 300, 300, 3]) // model's inputSize
            try ioOptions.setOutputFormat(index: 0, type: .float32, dimensions: [1, 3]) // [1, # of output classes]
        } catch let error as NSError {
            print("Failed to set input or output format with error: \(error.localizedDescription)")
        }
        
        let localModel = CustomLocalModel(modelPath: modelPath)
        let interpreter = ModelInterpreter.modelInterpreter(localModel: localModel)
        
        // Converts picked image from UIImage to CGImage
        let ciContext = CIContext(options: nil)
        let image: CGImage = ciContext.createCGImage(ciImage!, from: ciImage!.extent)!
        guard let context = CGContext(
          data: nil,
          width: image.width, height: image.height,
          bitsPerComponent: 8, bytesPerRow: image.width * 4,
          space: CGColorSpaceCreateDeviceRGB(),
          bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
          print("error 1")
          return
        }

        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        guard let imageData = context.data else { print("error 2")
            return }

        let inputs = ModelInputs()
        var inputData = Data()
        
        // Data Normalization
        do {
          for row in 0 ..< 300 {
            for col in 0 ..< 300 {
              let offset = 4 * (col * context.width + row)
              let red = imageData.load(fromByteOffset: offset+1, as: UInt8.self)
              let green = imageData.load(fromByteOffset: offset+2, as: UInt8.self)
              let blue = imageData.load(fromByteOffset: offset+3, as: UInt8.self)
                
              var normalizedRed = Float32(red) / 255.0
              var normalizedGreen = Float32(green) / 255.0
              var normalizedBlue = Float32(blue) / 255.0

              let elementSize = MemoryLayout.size(ofValue: normalizedRed)
              var bytes = [UInt8](repeating: 0, count: elementSize)
              memcpy(&bytes, &normalizedRed, elementSize)
              inputData.append(&bytes, count: elementSize)
              memcpy(&bytes, &normalizedGreen, elementSize)
              inputData.append(&bytes, count: elementSize)
              memcpy(&bytes, &normalizedBlue, elementSize)
              inputData.append(&bytes, count: elementSize)
            }
          }
          try inputs.addInput(inputData)
        } catch let error {
          print("Failed to add input: \(error)")
        }
        
        // Run the model!
        interpreter.run(inputs: inputs, options: ioOptions) { outputs, error in
            guard error == nil, let outputs = outputs else { print(error as Any)
                return }
            let output = try? outputs.output(index: 0) as? [[NSNumber]]
            let probabilities = output?[0]
            
            // Available outputs
            let labels = [0: "rock", 1: "paper", 2: "scissors", 3: "Error"]
            var probabilityArray: [Float] = []
            for i in 0 ..< labels.count - 1 {
              if let probability = probabilities?[i] {
                probabilityArray.append(Float(probability))
                let predictionOutput = "\(labels[i]): \(probability)"
                print(predictionOutput)
              }
            }
            
            // Gets the most confident output and confidence percentage
            let mostConfidence = probabilityArray.max()
            let mostConfidenceClass = probabilityArray.firstIndex(of: mostConfidence!)
            print("Predicted: \(mostConfidenceClass)")
            print("Confidence: \(mostConfidence)")
            
            self.outputLabel.text? = "Predicted Output: \(String(labels[mostConfidenceClass ?? 3]!))"
            self.confidenceLabel.text? = "Confidence: \(mostConfidence! * 100) %"

        }
    }
}
