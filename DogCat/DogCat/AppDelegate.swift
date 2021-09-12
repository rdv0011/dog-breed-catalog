//
// Copyright © 2021 Dmitry Rybakov. All rights reserved. 
    

import UIKit
import Combine

/// Represents application life cycle events
/// - Tag: AppLifecycleEvent
enum AppLifecycleEvent {
    case applicationWillEnterForeground(UIApplication)
    case applicationDidEnterBackground(UIApplication)
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    private let appLifecycleSubject = PassthroughSubject<AppLifecycleEvent, Never>()
    var appLifecycle: AnyPublisher<AppLifecycleEvent, Never> {
        appLifecycleSubject.eraseToAnyPublisher()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        appLifecycleSubject.send(.applicationWillEnterForeground(application))
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        appLifecycleSubject.send(.applicationDidEnterBackground(application))
    }
}
