//
//  AppDelegate.swift
//  Where I Roam
//
//  Created by James Lorenzo on 7/16/15.
//  Copyright (c) 2015 James Lorenzo. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    // xxx - is this necessary? hold a reference to the singleton
    var roamMgr: RoamingMgr?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        NSLog("application did finish ")
        // Override point for customization after application launch.
         roamMgr = RoamingMgr.sharedInstance
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        NSLog("application will resign active")
    }

    func applicationDidEnterBackground(application: UIApplication) {
        NSLog("application did enter background")
        RoamingMgr.sharedInstance.enableBackgroundMode()
        self.cdh.saveContext()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        NSLog("application will enter foreground")
 //       RoamingMgr.sharedInstance.enableForegroundMode()
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        NSLog("application did become active")
    }

    func applicationWillTerminate(application: UIApplication) {
        // Saves changes in the application's managed object context before the application terminates.
        NSLog("application will terminate")
        self.cdh.saveContext()
    }

    lazy var cdstore: CoreDataStore = {
        let cdstore = CoreDataStore()
        return cdstore
        }()
    
    lazy var cdh: CoreDataHelper = {
        let cdh = CoreDataHelper()
        return cdh
        }()

}

