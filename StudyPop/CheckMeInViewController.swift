//
//  CheckMeInViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 7/3/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import AVFoundation

class CheckMeInViewController: UIViewController {

    struct Constants{
        
    }
    
    
    var event:Event?
    var user:User?
    var member:EventMember?
    var qrCodeImage: CIImage!
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var slider: UISlider!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Check Me In"
        generateQRImage()
    }
    
    // Creates the QR Image
    func generateQRImage(){
        let data = member!.safekey!.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter!.setValue(data, forKey: "inputMessage")
        filter!.setValue("Q", forKey: "inputCorrectionLevel")
        qrCodeImage = filter?.outputImage
        displayQRCodeImage()
    }

    //Adjusts QRImage to ImageView Size
    func displayQRCodeImage(){
        let scaleX = imageView.frame.size.width / qrCodeImage.extent.size.width
        let scaleY = imageView.frame.size.height / qrCodeImage.extent.size.height
        
        let transformedImage = qrCodeImage.imageByApplyingTransform(CGAffineTransformMakeScale(scaleX, scaleY))
        
        imageView.image = UIImage(CIImage: transformedImage)
    }
    
    // MARK: - Transforms QRImage
    // Makes it bigger or smaller
    @IBAction func changeImageViewScale(sender:AnyObject){
        imageView.transform = CGAffineTransformMakeScale(CGFloat(slider.value), CGFloat(slider.value))
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
