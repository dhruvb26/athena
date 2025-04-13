//
//  MainProjectApp.swift
//  Athena
//
//  Created by Dhruv Bansal on 3/25/25.
//

import FirebaseCore
import FirebaseFirestore
import GoogleSignIn
import Logging
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()

        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)

            #if DEBUG
                handler.logLevel = .trace // Show everything in dev
            #else
                handler.logLevel = .warning // Only warning, error, critical in prod
            #endif

            return handler
        }

        NotificationManager.shared.requestPermission { success, error in
            if success {
                print("Notification permission granted.")
            } else if let error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
        return true
    }

    func application(
        _: UIApplication, open url: URL,
        options _: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }
}

final class FirestoreManager: ObservableObject {
    let db: Firestore

    init() {
        db = Firestore.firestore()
    }
}

@main
struct MainProjectApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var firestoreManager = FirestoreManager() // Initialize FirestoreManager
    @StateObject var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
                    .environmentObject(firestoreManager)
                    .environmentObject(authViewModel)
            }
        }
    }
}
