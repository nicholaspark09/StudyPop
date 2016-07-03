//
//  CheckInViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 7/3/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import AVFoundation

/**
        This is for Event Admins Only
            Simply Scan a QR Code
    
            Double check it with the Database to check users into an event
            Timestamped and everything!
 **/
class CheckInViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    
    var user:User?
    var event:Event?
    var member: EventMember?
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
 

        let input :AVCaptureDeviceInput
        do {
            input = try AVCaptureDeviceInput.init(device: captureDevice)
            //Begin Capturing the QR Code
            captureSession = AVCaptureSession()
            captureSession!.addInput(input as AVCaptureInput)
            
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession!.addOutput(captureMetadataOutput)
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer!)
            //Start throwing the video onto the view!
            captureSession!.startRunning()

            //Initialize QR Frame to highlight QR
            qrCodeFrameView = UIView()
            qrCodeFrameView?.layer.borderColor = UIColor.greenColor().CGColor
            qrCodeFrameView?.layer.borderWidth = 2
            view.addSubview(qrCodeFrameView!)
            view.bringSubviewToFront(qrCodeFrameView!)
        } catch{
            let foundError = error as NSError
            self.simpleError("Error: \(foundError.localizedDescription)")
        }
    }

    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects == nil || metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRectZero
            self.title = "No QR code is detected"
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if metadataObj.type == AVMetadataObjectTypeQRCode {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObjectForMetadataObject(metadataObj as AVMetadataMachineReadableCodeObject) as! AVMetadataMachineReadableCodeObject
            qrCodeFrameView?.frame = barCodeObject.bounds;
            
            if metadataObj.stringValue != nil {
                self.title = metadataObj.stringValue
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
