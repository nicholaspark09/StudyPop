//
//  AttendanceViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 7/3/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

@objc protocol AttendanceViewProtocol{
    func qrCheck()
}

class AttendanceViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    struct Constants{
        static let CellReuseIdentifier = "Attendance Cell"
        static let QRSegue = "QR Segue"
    }
    
    
    var event:Event?
    var user:User?
    var eventMember: EventMember?
    var attendants = [Attendance]()
    var loading = false
    var canLoadMore = true
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var loadingView: UIActivityIndicatorView!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Attendance: \(event!.name!)"
        
        
        if eventMember?.role?.intValue < 3{
            let image = UIImage(named: "CheckIn")
            let button = UIButton.init(type: UIButtonType.Custom)
            button.bounds = CGRectMake(0, 0, image!.size.width, image!.size.height)
            button.setImage(image, forState: UIControlState.Normal)
            button.addTarget(self, action: #selector(AttendanceViewProtocol.qrCheck), forControlEvents: UIControlEvents.TouchUpInside)
            let checkInButton = UIBarButtonItem(customView: button)
            navigationItem.rightBarButtonItem = checkInButton
        }
        
        indexAttendances()
    }

    func qrCheck(){
        performSegueWithIdentifier(Constants.QRSegue, sender: nil)
    }

    
    
    // MARK: - TableView Delegates
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if attendants.count < 1{
            return "No one has checked in"
        }
        return nil
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return attendants.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.CellReuseIdentifier, forIndexPath: indexPath) as! AttendanceTableViewCell
        let attendance = attendants[indexPath.row]
        
        cell.attendance = attendance
        
        return cell
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            if eventMember!.role!.intValue < 3{
                deleteAttendance(attendants[indexPath.row].safekey!)
                attendants.removeAtIndex(indexPath.row)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }else{
                self.simpleError("Only Admins can edit attendance")
            }
            
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    func updateUI(){
        self.tableView.reloadData()
    }
    
    func indexAttendances(){
        if !loading && canLoadMore{
            let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.AttendancesController,
                          StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.IndexMethod,
                          StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                          StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                          StudyPopClient.ParameterKeys.Offset: "\(attendants.count)",
                          StudyPopClient.ParameterKeys.SafeKey : event!.safekey!,
                          StudyPopClient.ParameterKeys.Token : user!.token!
            ]
            StudyPopClient.sharedInstance.httpGet("", parameters:params){(results,error) in
                self.loading = false
                func sendError(error: String){
                    self.simpleError(error)
                    self.canLoadMore = false
                    performOnMain(){
                        self.loadingView.stopAnimating()
                    }
                }
                
                guard error == nil else{
                    sendError(error!.localizedDescription)
                    return
                }
                
                guard let stat = results[StudyPopClient.JSONReponseKeys.Result] as? String else{
                    sendError("Got nothing back")
                    return
                }
                
                guard stat == StudyPopClient.JSONResponseValues.Success else{
                    sendError("StudyPop Api Returned error: \(results[StudyPopClient.JSONReponseKeys.Error])")
                    return
                }
                
                performOnMain(){
                    if let attDictionary = results![StudyPopClient.JSONReponseKeys.Attendances] as? [[String:AnyObject]]{
                        for i in attDictionary{
                            let dict = i as Dictionary<String,AnyObject>
                            let attendance = Attendance.init(dictionary: dict, context: self.sharedContext)
                            self.attendants.append(attendance)
                        }
                        if attDictionary.count < 10{
                            print("can't Keep going")
                            self.canLoadMore = false
                        }else{
                            print("Keep going")
                            self.canLoadMore = true
                        }
                        self.updateUI()
                    }
                }
            }
        }
    }
    
    // MARK: - Delete Attendance
    func deleteAttendance(safekey: String){
        let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.AttendancesController,
                      StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.DeleteMethod,
                      StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                      StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                      StudyPopClient.ParameterKeys.SafeKey: safekey,
                      StudyPopClient.ParameterKeys.Token : self.user!.token!
        ]
        StudyPopClient.sharedInstance.httpGet("", parameters: params){ (results,error) in
            func sendError(error: String){
                self.simpleError(error)
            }
            
            guard error == nil else{
                sendError(error!.localizedDescription)
                return
            }
            
            guard let stat = results[StudyPopClient.JSONReponseKeys.Result] as? String where stat == StudyPopClient.JSONResponseValues.Success else{
                sendError("StudyPop Api Returned error: \(results[StudyPopClient.JSONReponseKeys.Error]!)")
                return
            }
            
        }
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.QRSegue{
            if let cvc = segue.destinationViewController as? CheckInViewController{
                cvc.event = event!
                cvc.user = user!
                cvc.member = eventMember!
            }
        }
    }


}
