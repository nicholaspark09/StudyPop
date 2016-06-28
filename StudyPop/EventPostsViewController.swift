//
//  EventPostsViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/28/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

@objc protocol EventPostsProtocol{
    func addClicked()
}

class EventPostsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate {

    struct Constants{
        static let CellReuseIdentifier = "EventPostCell"
        static let AddEventPostSegue = "AddEventPost Segue"
    }
    
    
    var posts = [EventPost]()
    var event: Event?
    var user:User?
    var canLoadMore = false
    var loading = false
    let threshold = 50.0
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    @IBOutlet var loadingView: UIActivityIndicatorView!
    @IBOutlet var tableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "\(event!.name!) Posts"
        
        let image = UIImage(named: "AddSmall")
        let button = UIButton.init(type: UIButtonType.Custom)
        button.bounds = CGRectMake(0, 0, image!.size.width, image!.size.height)
        button.setImage(image, forState: UIControlState.Normal)
        button.addTarget(self, action: #selector(EventPostsProtocol.addClicked), forControlEvents: UIControlEvents.TouchUpInside)
        let barButton = UIBarButtonItem(customView: button)
        navigationItem.rightBarButtonItem = barButton
        
        
        indexPosts()
    }
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return posts.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.CellReuseIdentifier, forIndexPath: indexPath) as! EventPostTableViewCell
        cell.post = posts[indexPath.row]
        return cell
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let post = posts[indexPath.row]
            deletePost(post.safekey!, index: indexPath.row)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    
    func indexPosts(){
        if loading {
            self.simpleError("Still loading...")
        }else{
            loading = true
            self.loadingView.startAnimating()
            let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.EventPostsController,
                          StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.IndexMethod,
                          StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                          StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                          StudyPopClient.ParameterKeys.Offset: "\(posts.count)",
                          StudyPopClient.ParameterKeys.Token : user!.token!,
                          StudyPopClient.ParameterKeys.SafeKey : event!.safekey!
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
                    if let postsDict = results![StudyPopClient.JSONReponseKeys.EventPosts] as? [[String:AnyObject]]{
                        for i in postsDict{
                            let dict = i as Dictionary<String,AnyObject>
                            let post = EventPost.init(dictionary: dict, context: self.sharedContext)
                            self.posts.append(post)
                        }
                        if postsDict.count < 10{
                            self.canLoadMore = false
                        }else{
                            self.canLoadMore = true
                        }
                    }
                    self.updateUI()
                    performOnMain(){
                        self.loadingView.stopAnimating()
                    }
                }else{
                    sendError("StudyPop Api Returned error: \(results[StudyPopClient.JSONReponseKeys.Error])")
                }
            }
        }
    }
    
    func deletePost(safekey: String, index: Int){
        self.loadingView.startAnimating()
        let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.EventPostsController,
                      StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.DeleteMethod,
                      StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                      StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                      StudyPopClient.ParameterKeys.Token : user!.token!,
                      StudyPopClient.ParameterKeys.SafeKey : safekey
        ]
        StudyPopClient.sharedInstance.httpGet("", parameters: params){(results,error) in
            
            func sendError(error: String){
                self.simpleError(error)
                self.loadingView.stopAnimating()
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
                performOnMain(){
                    self.loadingView.stopAnimating()
                    self.posts.removeAtIndex(index)
                    self.updateUI()
                }
            }else{
                sendError("StudyPop Api Returned error: \(results[StudyPopClient.JSONReponseKeys.Error])")
            }
        }
    }
    
    
    // MARK: -Unwind to EventPostsController
    @IBAction func unwindToEventPosts(sender: UIStoryboardSegue){
        if let svc = sender.sourceViewController as? AddEventPostViewController{
            if let post = svc.post{
                self.posts.insert(post, atIndex: 0)
                updateUI()
            }
        }
    }
    
    // MARK: -ScrollView Delegate
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let contentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height;
        
        if !loading && canLoadMore && (Double(maximumOffset) - Double(contentOffset) <= threshold) {
            // Get more data - API call
            indexPosts()
        }
    }
    
    func updateUI(){
        performOnMain(){
            self.tableView.reloadData()
        }
    }
    
    func addClicked(){
        performSegueWithIdentifier(Constants.AddEventPostSegue, sender: nil)
    }
    
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.AddEventPostSegue{
            if let ac = segue.destinationViewController as? AddEventPostViewController{
                ac.modalPresentationStyle = UIModalPresentationStyle.Popover
                ac.popoverPresentationController!.delegate = self
                ac.event = event!
                ac.user = user!
            }
        }
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    

}
