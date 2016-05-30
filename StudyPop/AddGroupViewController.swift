//
//  AddGroupViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 5/31/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit

class AddGroupViewController: UIViewController {

    struct Constants{
        static let AlertTitle = "Confirm"
        static let AlertMessage = "Are you sure you want to exit?"
        static let AlertClose = "Close"
        static let AlertDont = "Don't Close"
        static let PickCitySegue = "PickCity Segue"
        static let Controller = "AddGroup"
        
    }
    
    @IBOutlet var cityLabel: UILabel!
    
    var currentCityKey = ""
    var currentCityName = ""
    
    var user: User?{
        didSet{
            print("You got the user with an email of \(user!.email!)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancelClicked(sender: UIBarButtonItem) {
        
        let cancelAlert = UIAlertController(title: Constants.AlertTitle, message: Constants.AlertMessage, preferredStyle: UIAlertControllerStyle.Alert)
        
        cancelAlert.addAction(UIAlertAction(title: Constants.AlertClose, style: .Default, handler: { (action: UIAlertAction!) in
            self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
        }))
        
        cancelAlert.addAction(UIAlertAction(title: Constants.AlertDont, style: .Cancel, handler:nil))
        
        presentViewController(cancelAlert, animated: true, completion: nil)
        
    }
    
    // MARK: - Unwind From other Segues to Here
    @IBAction func unwindToAdd(sender: UIStoryboardSegue){
        if let sourceViewController = sender.sourceViewController as? CityPickerViewController{
            currentCityKey = sourceViewController.currentCityKey
            currentCityName = sourceViewController.cityName
            cityLabel.text = currentCityName
        }else if let svc = sender.sourceViewController as? StudyPickerViewController{
           
        }
   
    }


    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.PickCitySegue{
            if let pvc = segue.destinationViewController as? CityPickerViewController{
                pvc.previousController = Constants.Controller
            }
        }
    }


}
