//
//  AppDelegate.swift
//  StudyPop
//
//  Created by Nicholas Park on 5/16/16.
//  Copyright © 2016 Nicholas Park. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    struct Constants{
        static let StoryboardName = "Main"
        static let UserEntity = "User"
        static let StoryboardLoginView = "LoginView"
        static let StoryboardGroupsView = "GroupsView"
        static let StoryboardHomeTab = "HomeTab"
    }


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        //Check for a logged in user first
        let sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext
        let request = NSFetchRequest(entityName: Constants.UserEntity)
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "logged == %@", true)
        do{
           let results = try sharedContext.executeFetchRequest(request)
            if results.count > 0{
                //A user was found!
                //Send them to the tabcontroller
                print("You found a user?")
                let storyboard = UIStoryboard.init(name: Constants.StoryboardName, bundle: nil)
                let hc = storyboard.instantiateViewControllerWithIdentifier(Constants.StoryboardHomeTab) as UIViewController
                self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
                self.window?.rootViewController = hc
                self.window?.makeKeyAndVisible()
            }else{
                print("The user wasn't logged in")
                //No logged in user
                let storyboard = UIStoryboard.init(name: Constants.StoryboardName, bundle: nil)
                let lc = storyboard.instantiateViewControllerWithIdentifier(Constants.StoryboardLoginView) as UIViewController
                self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
                self.window?.rootViewController = lc
                self.window?.makeKeyAndVisible()
            }
        } catch {
            let fetchError = error as NSError
            print("The error was \(fetchError)")
        }
        
        return true
    }

    func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
        
        let urlString = url.absoluteString
        let data = urlString.componentsSeparatedByString("/")
        if data.count > 0{
            if data[2] == "login"{
                
                //Check the login safekey
                let defaults = NSUserDefaults.standardUserDefaults()
                let safekey = defaults.objectForKey(User.Keys.Token)
                if safekey == nil{
                    print("Error: Nothing was found")
                }else{
                    let userDetails = [User.Keys.Name:"",User.Keys.Email: defaults.objectForKey(User.Keys.Email)!,User.Keys.Logged:true,User.Keys.Token:safekey!,User.Keys.SafeKey: safekey!]
                    let user = User.init(dictionary: userDetails, context: CoreDataStackManager.sharedInstance().managedObjectContext)
                    print("You have a user with email: \(user.email)")
                    CoreDataStackManager.sharedInstance().saveContext()
                    //Close all windows and open to the groups
                    let storyboard = UIStoryboard.init(name:Constants.StoryboardName, bundle: nil)
                    let hc = storyboard.instantiateViewControllerWithIdentifier(Constants.StoryboardHomeTab)
                    self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
                    self.window?.rootViewController = hc
                    self.window?.makeKeyWindow()
                    print("you have gotten here")
                }
                /*
                print("You observed it. Now broadcast it")
                let center = NSNotificationCenter.defaultCenter()
                let notification = NSNotification(name: StudyPopClient.Constants.LoginNotification, object: self, userInfo: [StudyPopClient.Constants.LoginKey:data[3]])
                center.postNotification(notification)
 */
            }
        }
        return true
    }
    
    //Get the locale
    /*
        On the StudyPop API (Which I unfortunately made...)
            all locales are based on language_CountryCode
            
    */
    func getLocale() -> String{
        let locale = NSLocale.currentLocale()
        let countryCode = locale.objectForKey(NSLocaleCountryCode) as! String
        var language:String = "en-US"
        language = locale.objectForKey(NSLocaleLanguageCode) as! String
        language = "\(language)_\(countryCode)"
        return language
    }

 
}

