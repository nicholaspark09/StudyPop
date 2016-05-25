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
            }else{
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

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
    }

 
}

