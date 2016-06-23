//
//  GroupPicIndexViewController.swift
//  StudyPop
//
//  Created by Nicholas Park on 6/23/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

@objc protocol GroupPicProtocol{
    func addPic()
}

class GroupPicIndexViewController: UIViewController {

    struct Constants{
        static let Controller = "groups"
        static let TheType = "\(2)"
    }
    
    
    
    var loading = false
    var canLoadMore = true
    var thumbs = [Thumb]()
    var group:Group?
    var user:User?
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    @IBOutlet var loadingView: UIActivityIndicatorView!
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if group != nil{
            title = "\(group!.name!) Pics"
        }
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(GroupPicProtocol.addPic))
        
        indexThumbs()
    }


    // MARK: - Index Thumbs from Server
    func indexThumbs(){
        if !loading{
            
            loading = true
            let params = [StudyPopClient.ParameterKeys.Controller: StudyPopClient.ParameterValues.PicsController,
                          StudyPopClient.ParameterKeys.Method: StudyPopClient.ParameterValues.IndexMethod,
                          StudyPopClient.ParameterKeys.ApiKey: StudyPopClient.Constants.ApiKey,
                          StudyPopClient.ParameterKeys.ApiSecret: StudyPopClient.Constants.ApiSecret,
                          StudyPopClient.ParameterKeys.Offset: "\(thumbs.count)",
                          StudyPopClient.ParameterKeys.Token : user!.token!,
                          StudyPopClient.ParameterKeys.SafeKey : group!.safekey!,
                          StudyPopClient.ParameterKeys.TheController: Constants.Controller,
                          Photo.Keys.TheType : Constants.TheType
            ]
            self.loadingView.startAnimating()
            StudyPopClient.sharedInstance.httpGet("", parameters: params){(results,error) in
                
                self.loading = false
                
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
                    if let thumbsDict = results![StudyPopClient.JSONReponseKeys.Thumbs] as? [[String:AnyObject]]{
                        for i in thumbsDict{
                            let dict = i as Dictionary<String,AnyObject>
                            let thumb = Thumb.init(dictionary: dict, context: self.sharedContext)
                            self.thumbs.append(thumb)
                        }
                        if thumbsDict.count < 10{
                            self.canLoadMore = false
                        }else{
                            self.canLoadMore = true
                        }
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
            self.loadingView.stopAnimating()
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
