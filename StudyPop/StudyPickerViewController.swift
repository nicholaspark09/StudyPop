//
//  StudyPickerViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 5/29/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

class StudyPickerViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {

    
    struct Constants{
        static let CellReuseIdentifier = "SubjectCell"
        static let UnwindToGroupsSegue = "UnwindSubject Segue"
    }
    
    var subjectName = ""
    var subjectKey = ""
    var locale = "en_US"
    var subjects = [Subject]()
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    @IBOutlet var subjectLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        (subjectName,subjectKey) = appDelegate.getSubject()
        
        
        if subjectKey != ""{
            subjectLabel.text = subjectName
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        
        subjects = indexSubjects()
        if subjects.count < 1 {
            //There are no subjects, get them from the server
            getSubjects()
        }else{
            tableView.reloadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getSubjects(){
        subjects.removeAll()
        updateUI()
        CoreDataStackManager.sharedInstance().saveContext()
        let params = [
            StudyPopClient.ParameterKeys.Controller : StudyPopClient.ParameterValues.SubjectsController,
            StudyPopClient.ParameterKeys.Method : StudyPopClient.ParameterValues.IndexMethod,
            StudyPopClient.ParameterKeys.ApiKey : StudyPopClient.Constants.ApiKey,
            StudyPopClient.ParameterKeys.ApiSecret : StudyPopClient.Constants.ApiSecret,
            StudyPopClient.ParameterKeys.Locale:locale
        ]
        StudyPopClient.sharedInstance.httpGet("", parameters: params){ (results,error) in
            func sendError(error: String){
                self.simpleError(error)
            }
            
            guard error == nil else{
                sendError("Error: \(error!.localizedDescription)")
                return
            }
            
            guard let stat = results[StudyPopClient.JSONReponseKeys.Result] as? String where stat == StudyPopClient.JSONResponseValues.Success else{
                sendError("StudyPop Api Returned error: \(results[StudyPopClient.JSONReponseKeys.Error])")
                return
            }
            
            
            if let subjectDictionary = results![StudyPopClient.JSONReponseKeys.Subjects] as? [[String:AnyObject]]{
                //First city should be blank in case the use doesn't want any city
                for i in subjectDictionary{
                    let dict = i as Dictionary<String,AnyObject>
                    let subject = Subject.init(dictionary: dict, context: self.sharedContext)
                    self.subjects.append(subject)
                }
                performOnMain(){
                    CoreDataStackManager.sharedInstance().saveContext()
                }
                self.updateUI()
                /*
                 let _ = cityDictionary.map(){ (dictionary: [String:AnyObject]) -> City in
                 let city = City(dictionary: dictionary, context: self.tempContext)
                 self.cities.append(city)
                 return city
                 }
                 performOnMain(){
                 self.tableView.reloadData()
                 }
                 */
            }
        }
    }
    
    func indexSubjects() -> [Subject]{
        let fetchRequest = NSFetchRequest(entityName: "Subject")
        do{
            return try sharedContext.executeFetchRequest(fetchRequest) as! [Subject]
        } catch let error as NSError{
            print("The error was: \(error.localizedDescription)")
            return [Subject]()
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return subjects.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.CellReuseIdentifier, forIndexPath: indexPath) as! SubjectTableViewCell
        cell.subject = subjects[indexPath.row]
        return cell
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let subject = subjects[indexPath.row]
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(StudyPopClient.Constants.Subject, forKey: subject.name!)
        defaults.setObject(StudyPopClient.Constants.SubjectKey, forKey: subject.user!)
        defaults.synchronize()
        subjectKey = subject.user!
        performSegueWithIdentifier(Constants.UnwindToGroupsSegue, sender: nil)
    }
    
    func updateUI(){
        performOnMain(){
            self.tableView.reloadData()
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