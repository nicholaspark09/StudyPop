//
//  GroupsViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 5/27/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

class GroupsViewController: UIViewController {

    struct Constants{
        static let LogoutAlertTitle = "Logout Confirmation"
        static let LogoutAlertMessage = "Are you sure you want to logout?"
        static let LogoutCancel = "Cancel"
        static let LogoutTitle = "Logout"
        static let CityPickerSegue = "CityPicker Segue"
        static let CityPickedButton = "CityBlue"
        static let CityUnpickedButton = "CityWhite"
        static let SubjectPickedButton = "SubjectBlue"
        static let SubjectUnpickedButton = "SubjectWhite"
    }
    
    /**
        Variables Section
    */
    // MARK: SharedContext
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()

    var cityKey = ""
    var subjectKey = ""
    /**     
        IBOutlets

    **/
    @IBOutlet var searchButton: UIButton!
    @IBOutlet var cityButton: UIButton!
    @IBOutlet var subjectButton: UIButton!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Grab the city first
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        (_,cityKey) = appDelegate.getCity()
        if cityKey != ""{
            cityButton!.setImage(UIImage(named:Constants.CityPickedButton), forState: .Normal)
        }
        (_,subjectKey) = appDelegate.getSubject()
        if subjectKey != ""{
            subjectButton.setImage(UIImage(named: Constants.SubjectPickedButton), forState: .Normal)
        }else{
            subjectButton.setImage(UIImage(named: Constants.SubjectUnpickedButton), forState: .Normal)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
    @IBAction func logoutClicked(sender: UIButton) {
        let logoutAlert = UIAlertController(title: Constants.LogoutAlertTitle, message: Constants.LogoutAlertMessage, preferredStyle: .Alert)
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
    
    
    // MARK: - Unwind From other Segues to Here
    @IBAction func unwindToGroups(sender: UIStoryboardSegue){
        if let sourceViewController = sender.sourceViewController as? CityPickerViewController{
            cityKey = sourceViewController.currentCityKey
            if cityKey != ""{
                cityButton.setImage(UIImage(named: Constants.CityPickedButton), forState: .Normal)
            }else{
                cityButton.setImage(UIImage(named: Constants.CityUnpickedButton), forState: .Normal)
            }
            print("You got a citykey back of id: \(cityKey)")
        }else if let svc = sender.sourceViewController as? StudyPickerViewController{
            subjectKey = svc.subjectKey
            if subjectKey != ""{
                subjectButton.setImage(UIImage(named: Constants.SubjectPickedButton), forState: .Normal)
            }else{
                subjectButton.setImage(UIImage(named: Constants.SubjectUnpickedButton), forState: .Normal)
            }
        }
    }

    
    // MARK: - Navigation
    //Prep time
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
    }
    
    //Ensure the Popover is just the right size
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }

}
