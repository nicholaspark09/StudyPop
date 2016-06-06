//
//  PickImageViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/1/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit

class PickImageViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, WDImagePickerDelegate {

    
    struct Constants{
        static let AlertTitle = "Confirm"
        static let AlertMessage = "Are you sure you want to exit?"
        static let AlertClose = "Close"
        static let AlertDont = "Don't Close"
        
    }
    
    @IBOutlet var imageView: UIImageView!
    var selectedImage:UIImage?
    
    //WDImage
    var imagePicker: WDImagePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancelClicked(sender: AnyObject) {
        if selectedImage != nil{
            let cancelAlert = UIAlertController(title: Constants.AlertTitle, message: Constants.AlertMessage, preferredStyle: UIAlertControllerStyle.Alert)
            
            cancelAlert.addAction(UIAlertAction(title: Constants.AlertClose, style: .Default, handler: { (action: UIAlertAction!) in
                self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
            }))
            
            cancelAlert.addAction(UIAlertAction(title: Constants.AlertDont, style: .Cancel, handler:nil))
            
            presentViewController(cancelAlert, animated: true, completion: nil)
        }else{
            self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    @IBAction func imageButtonClicked(sender: UIButton){
        /*
        if sender.tag == 0{
            pickAnImage(UIImagePickerControllerSourceType.Camera)
        }else{
            pickAnImage(UIImagePickerControllerSourceType.PhotoLibrary)
        }
 */
        self.imagePicker = WDImagePicker()
        self.imagePicker.cropSize = CGSizeMake(280, 280)
        self.imagePicker.delegate = self
        self.presentViewController(self.imagePicker.imagePickerController, animated: true, completion: nil)
    }
    
    
    //Open the camera or gallery
    func pickAnImage(sourceType: UIImagePickerControllerSourceType){
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = sourceType
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    //Get the Image back from the pickercontroller
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        dismissViewControllerAnimated(true, completion: nil)
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage{
            selectedImage = image
            imageView.image = image
            imageView.contentMode = UIViewContentMode.ScaleAspectFit
            self.navigationItem.leftBarButtonItem?.enabled = true
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
