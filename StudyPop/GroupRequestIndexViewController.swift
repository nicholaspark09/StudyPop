//
//  GroupRequestIndexViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/22/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

class GroupRequestIndexViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, GroupRequestDelegate {

    struct Constants{
        static let CellReuseIdentifier = "GroupRequest Cell"
        static let ProfileViewSegue = "ProfileView Segue"
        static let Accepted = 2
        static let Rejected = 1
    }
    
    /***
            Since the requests will constantly be in flux,
     
                Don't save any of this in core stack
    ***/
    
    
    var group:Group?
    var user:User?
    var requests = [GroupRequest]()
    var loading = false
    var canLoadMore = false
    let threshold = 50.0
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var loadingView: UIActivityIndicatorView!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if group != nil{
            title = "\(group!.name!) Requests"
        }
        indexRequests()
    }
    
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return requests.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.CellReuseIdentifier, forIndexPath: indexPath) as! GroupRequestTableViewCell
        cell.delegate = self
        cell.index = indexPath.row
        cell.request = requests[indexPath.row]
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let request = requests[indexPath.row]
        if request.safekey != nil && request.safekey != ""{
            performSegueWithIdentifier(Constants.ProfileViewSegue, sender: request)
        }
    }
    
    // MARK: - Index Group Requests
    
    func indexRequests(){
        if !loading{
            self.loadingView.startAnimating()
            loading = true
            let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.GroupRequestsController,
                          StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.IndexMethod,
                          StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                          StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                          StudyPopClient.ParameterKeys.Offset: "\(requests.count)",
                          StudyPopClient.ParameterKeys.Token : user!.token!,
                          StudyPopClient.ParameterKeys.SafeKey : group!.safekey!
            ]
            StudyPopClient.sharedInstance.httpGet("", parameters: params){(results,error) in
                
                self.loading = false
                
                func sendError(error: String){
                    self.simpleError(error)
                    performOnMain(){
                        self.loadingView.stopAnimating()
                    }
                }
                
                guard error == nil else{
                    sendError(error!.localizedDescription)
                    return
                }
                
                guard let stat = results[StudyPopClient.JSONReponseKeys.Result] as? String else{
                    sendError("Got nothing from the server. Please try again")
                    return
                }
                
                if stat == StudyPopClient.JSONResponseValues.Success{
                    if let requestsDict = results![StudyPopClient.JSONReponseKeys.GroupRequests] as? [[String:AnyObject]]{
                        for i in requestsDict{
                            let dict = i as Dictionary<String,AnyObject>
                            let request = GroupRequest.init(dictionary: dict, context: self.sharedContext)
                            self.requests.append(request)
                        }
                        if requestsDict.count < 10{
                            self.canLoadMore = false
                        }else{
                            self.canLoadMore = true
                        }
                    }
                    if self.requests.count < 1{
                        let dict = [GroupRequest.Keys.SafeKey : "", GroupRequest.Keys.Name : "No Requests"]
                        let request = GroupRequest.init(dictionary: dict, context: self.sharedContext)
                        self.requests.append(request)
                    }
                    self.updateUI()
                }else{
                    sendError("StudyPop Api Returned error: \(results[StudyPopClient.JSONReponseKeys.Error])")
                }
            }
        }
    }

    func updateUI(){
        performOnMain(){
            self.tableView.reloadData()
            self.loadingView.stopAnimating()
        }
    }
    
    func acceptIt(index:Int){
        let request = requests[index]
        self.loadingView.startAnimating()
        let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.GroupRequestsController,
                      StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.ResponseMethod,
                      StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                      StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                      StudyPopClient.ParameterKeys.Offset: "\(requests.count)",
                      StudyPopClient.ParameterKeys.Token : user!.token!,
                      StudyPopClient.ParameterKeys.SafeKey : request.safekey!,
                         GroupRequest.Keys.Accepted : "\(Constants.Accepted)",
        ]
        StudyPopClient.sharedInstance.httpGet("", parameters: params){(results,error) in
            
            performOnMain(){
                self.loadingView.stopAnimating()
            }
            
            func sendError(error: String){
                self.simpleError(error)
                
            }
            
            guard error == nil else{
                sendError(error!.localizedDescription)
                return
            }
            
            guard let stat = results[StudyPopClient.JSONReponseKeys.Result] as? String else{
                sendError("Got nothing from the server. Please try again")
                return
            }
            
            if stat == StudyPopClient.JSONResponseValues.Success{
                
                self.requests.removeAtIndex(index)
                self.simpleError("Added new member!")
                self.updateUI()
            }else{
                sendError("StudyPop Api Returned error: \(results[StudyPopClient.JSONReponseKeys.Error])")
            }
        }
    }
    
    func rejectIt(index: Int) {
        let request = requests[index]
        let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.GroupRequestsController,
                      StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.ResponseMethod,
                      StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                      StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                      StudyPopClient.ParameterKeys.Offset: "\(requests.count)",
                      StudyPopClient.ParameterKeys.Token : user!.token!,
                      StudyPopClient.ParameterKeys.SafeKey : request.safekey!,
                      GroupRequest.Keys.Accepted : "\(Constants.Rejected)",
                      ]
        self.loadingView.startAnimating()
        StudyPopClient.sharedInstance.httpGet("", parameters: params){(results,error) in
            
            performOnMain(){
                self.loadingView.stopAnimating()
            }
            
            func sendError(error: String){
                self.simpleError(error)
                
            }
            
            guard error == nil else{
                sendError(error!.localizedDescription)
                return
            }
            
            guard let stat = results[StudyPopClient.JSONReponseKeys.Result] as? String else{
                sendError("Got nothing from the server. Please try again")
                return
            }
            
            if stat == StudyPopClient.JSONResponseValues.Success{
                self.requests.removeAtIndex(index)
                self.updateUI()
            }else{
                sendError("StudyPop Api Returned error: \(results[StudyPopClient.JSONReponseKeys.Error])")
            }
        }
    }

    
    // MARK: -ScrollView Delegate
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let contentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height;
        
        if !loading && canLoadMore && (Double(maximumOffset) - Double(contentOffset) <= threshold) {
            // Get more data - API call
            indexRequests()
        }
    }

    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.ProfileViewSegue{
            let request = sender as! GroupRequest
            if let pvc = segue.destinationViewController as? ProfileViewController{
                pvc.user = user!
                pvc.profileUser = request.user!
            }
        }
    }
    

}
