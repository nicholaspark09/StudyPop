//
//  PickDateViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/10/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit

class PickDateViewController: UIViewController {

    struct Constants{
        static let UnwindToAddGroupEventSegue = "UnwindToAddGroupEvent Segue"
    }
    
    
    @IBOutlet var datePicker: UIDatePicker!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var doneButton: UIButton!
    
    var currentDate: String?
    var previousController = ""
    var previousAction = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }

    
    @IBAction func cancelClicked(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    @IBAction func doneClicked(sender: UIButton) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        currentDate = dateFormatter.stringFromDate(datePicker.date)
        performSegueWithIdentifier(Constants.UnwindToAddGroupEventSegue, sender: nil)
    }
    

    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    }
    
    
    override var preferredContentSize: CGSize {
        get{
            return super.preferredContentSize
        }
        set{
            super.preferredContentSize = newValue
        }

    }

}
