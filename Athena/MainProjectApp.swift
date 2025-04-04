//
//  MainProjectApp.swift
//  Athena
//
//  Created by Dhruv Bansal on 3/25/25.
//

import FirebaseCore
import FirebaseFirestore
import GoogleSignIn
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_: UIApplication,
                     didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool
    {
        FirebaseApp.configure()
        return true
    }

    func application(_: UIApplication, open url: URL,
                     options _: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool
    {
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
                    .environmentObject(firestoreManager) // Inject into environment
//                    .environmentObject(authViewModel) // ✅ Inject it here
            }
        }
    }
}
