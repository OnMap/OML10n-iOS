//
//  AppDelegate.swift
//  LocalizationExample
//
//  Created by Alex Alexandrovych on 16/08/2017.
//  Copyright © 2017 Alex Alexandrovych. All rights reserved.
//

import UIKit
import OMLocalization

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    enum Storyboard: String {
        case main

        var name: String {
            return self.rawValue.capitalized
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Localization.setupCurrentLanguage()
        let appId = "f635ba15-0adf-42bc-b13e-88499a433f37"
        let token =  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0eXBlIjoidGVsZW1hcmtldGluZyIsInVzZXJfaWQiOiJTSmdPVmNsa3oiLCJjcmVhdGVkIjoxNTEwMTUxMzY3MTg0LCJqdGkiOiJTeUpDVnFla00iLCJpYXQiOjE1MTAxNTEzNjcsImV4cCI6MTUxMjc0MzM2NywiaXNzIjoiT25NYXAgTFREIn0.-1L6za1Mh2mu5zoUykG-ZTnDeNDy9kqE4O37h74l6mo"
        LiveUpdatesNetworkService.setup(appId: appId, token: token)
        return true
    }

    func launchStoryboard(_ storyboard: Storyboard) {
        let storyboard = UIStoryboard(name: storyboard.name, bundle: nil)
        let viewController = storyboard.instantiateInitialViewController()
        window?.rootViewController = viewController
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}
