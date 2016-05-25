//
//  Helpers.swift
//  VirtualTourist
//
//  Created by Nicholas Park on 5/10/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import Foundation
import UIKit

//Allows you to grab the Visible View Controller of a NavController
extension UIViewController{
    
    struct UIViewConstants{
        static let AlertTitle = "Error"
        static let AlertButtonTitle = "OK"
    }
    
    var contentViewController: UIViewController{
        if let navCon = self as? UINavigationController{
            return navCon.visibleViewController!
        }
            return self
    }

    //Simple Error
    func simpleError(message: String){
        performOnMain(){
            let alert = UIAlertController(title: UIViewConstants.AlertTitle, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: UIViewConstants.AlertButtonTitle, style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    
}

//Make sure things are done on the main thread
func performOnMain(updates: () -> Void){
    dispatch_async(dispatch_get_main_queue()){
        updates()
    }
}

