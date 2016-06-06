//
//  PeopleViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/6/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

class PeopleViewController: UIViewController {

    struct Constants{
        static let MyProfileSegue = "MyProfile Segue"
    }
    
    
    var user:User?
    var currentCityName = ""
    var currentCityKey = ""
    var currentSubjectName = ""
    var currentSubjectKey = ""
    
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        getUser()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.MyProfileSegue{
            print("YOu should be performing Segue")
            if let pvc = segue.destinationViewController as? ProfileViewController{
                pvc.user = user!
            }
        }
    }

    
    func getUser(){
        let request = NSFetchRequest(entityName: "User")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "logged == %@", true)
        do{
            let results = try sharedContext.executeFetchRequest(request)
            if results.count > 0{
                if let temp = results[0] as? User{
                    user = temp
                }
            }
        } catch {
            let fetchError = error as NSError
            print("The error was \(fetchError)")
        }
    }

}
