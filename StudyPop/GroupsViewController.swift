//
//  GroupsViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 5/27/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

class GroupsViewController: UIViewController, UIPopoverPresentationControllerDelegate {

    struct Constants{
        static let LogoutAlertTitle = "Logout Confirmation"
        static let LogoutAlertMessage = "Are you sure you want to logout?"
        static let LogoutCancel = "Cancel"
        static let LogoutTitle = "Logout"
        static let CityPickerSegue = "CityPicker Segue"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: SharedContext
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    @IBAction func logoutClicked(sender: UIButton) {
        var logoutAlert = UIAlertController(title: Constants.LogoutAlertTitle, message: Constants.LogoutAlertMessage, preferredStyle: .Alert)
        //Add a cancel button
        logoutAlert.addAction(UIAlertAction(title: Constants.LogoutCancel, style: .Cancel, handler: nil))
        //Logout is confirmed
        logoutAlert.addAction(UIAlertAction(title: Constants.LogoutTitle, style: .Default, handler: {(action: UIAlertAction!) in
            //Get the user first
            let request = NSFetchRequest(entityName: "User")
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "logged == %@", true)
            do{
                let users = try self.sharedContext.executeFetchRequest(request) as! [User]
                if users.count > 0{
                    users[0].logged = false
                    users[0].safekey = ""
                    CoreDataStackManager.sharedInstance().saveContext()
                    self.navigationController?.popToRootViewControllerAnimated(true)
                }
            } catch let error as NSError{
                print("The error was \(error.localizedDescription)")
            }
        }))
        
        presentViewController(logoutAlert, animated: true, completion: nil)
    }

    
    // MARK: - Navigation
    //Prep time
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.CityPickerSegue{
            if let cvc = segue.destinationViewController as? CityPickerViewController{
                cvc.modalPresentationStyle = UIModalPresentationStyle.Popover
                cvc.popoverPresentationController!.delegate = self
            }
        }
    }
    
    //Ensure the Popover is just the right size
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }

}
