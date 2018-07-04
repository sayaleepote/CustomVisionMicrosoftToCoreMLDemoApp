//
//  ViewController.swift
//  CustomVisionMicrosoftToCoreML
//
//  Created by Sayalee on 6/28/18.
//  Copyright © 2018 Assignment. All rights reserved.
//

import UIKit
import AVKit
import Vision

enum HandSign: String {
    case fiveHand = "FiveHand"
    case fistHand = "FistHand"
    case victoryHand = "VictoryHand"
    case noHand = "NoHand"
}

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet weak var predictionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCamera()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func configureCamera() {
        
        //Start capture session
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        captureSession.startRunning()
        
        // Add input for capture
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let captureInput = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(captureInput)
        
        // Add preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        // Add output for capture
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // Initialise CVPixelBuffer from sample buffer
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        //Initialise Core ML model
        guard let handSignsModel = try? VNCoreMLModel(for: HandSigns().model) else { return }

        // Create a Core ML Vision request
        let request =  VNCoreMLRequest(model: handSignsModel) { (finishedRequest, err) in

            // Dealing with the result of the Core ML Vision request
            guard let results = finishedRequest.results as? [VNClassificationObservation] else { return }

            guard let firstResult = results.first else { return }
            var predictionString = ""
            DispatchQueue.main.async {
                switch firstResult.identifier {
                case HandSign.fistHand.rawValue:
                    predictionString = "Fist👊🏽"
                case HandSign.victoryHand.rawValue:
                    predictionString = "Victory✌🏽"
                case HandSign.fiveHand.rawValue:
                    predictionString = "High Five🖐🏽"
                case HandSign.noHand.rawValue:
                    predictionString = "No Hand ❎"
                default:
                    break
                }
                self.predictionLabel.text = predictionString + "(\(firstResult.confidence))"
            }
        }

        // Perform the above request using Vision Image Request Handler
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }

}

