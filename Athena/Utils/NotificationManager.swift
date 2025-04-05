//
//  NotificationManager.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/4/25.
//

import SwiftUI
import UserNotifications

typealias NotificationActionHandler = (UNNotificationResponse) -> Void

struct NotificationAction {
    let identifier: String
    let title: String
    let options: UNNotificationActionOptions // example: .authenticationRequire, .foreground, .destructive
    let handler: NotificationActionHandler
}

struct NotificationCategory {
    let identifier: String
    let actions: [NotificationAction]
}

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private var categories: [String: NotificationCategory] = [:]
    private var actionHandlers: [String: NotificationActionHandler] = [:]

    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func registerCategory(_ category: NotificationCategory) {
        categories[category.identifier] = category

        for action in category.actions {
            actionHandlers[action.identifier] = action.handler
        }

        let notificationActions = category.actions.map { action in
            UNNotificationAction(
                identifier: action.identifier,
                title: action.title,
                options: action.options
            )
        }

        // create and register the category
        let notificationCategory = UNNotificationCategory(
            identifier: category.identifier,
            actions: notificationActions,
            intentIdentifiers: [],
            options: []
        )

        // get existing categories and add the new one
        UNUserNotificationCenter.current().getNotificationCategories { categories in
            var updatedCategories = categories
            updatedCategories.insert(notificationCategory)
            UNUserNotificationCenter.current().setNotificationCategories(updatedCategories)
        }
    }

    func requestPermission(completion: @escaping (Bool, Error?) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge, .provisional], completionHandler: completion
        )
    }

    // handles notifications while the app is in foreground
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) ->
            Void
    ) {
        completionHandler([.banner, .sound])
    }

    // Basic notification without actions
    func scheduleBasicNotification(
        title: String,
        body: String,
        userInfo: [AnyHashable: Any] = [:],
        trigger: UNNotificationTrigger
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.userInfo = userInfo

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled successfully.")
            }
        }
    }

    // interactive notification with category and actions
    func scheduleInteractiveNotification(
        title: String,
        body: String,
        categoryIdentifier: String,
        userInfo: [AnyHashable: Any] = [:],
        trigger: UNNotificationTrigger
    ) {
        guard categories[categoryIdentifier] != nil else {
            print("Error: Category \(categoryIdentifier) not registered")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = categoryIdentifier
        content.userInfo = userInfo

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled successfully.")
            }
        }
    }

    func scheduleBasicNotification(
        title: String,
        body: String,
        userInfo: [AnyHashable: Any] = [:],
        timeInterval: TimeInterval,
        repeats: Bool = false
    ) {
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval, repeats: repeats
        )
        scheduleBasicNotification(
            title: title,
            body: body,
            userInfo: userInfo,
            trigger: trigger
        )
    }

    func scheduleBasicNotification(
        title: String,
        body: String,
        userInfo: [AnyHashable: Any] = [:],
        date: Date,
        repeats: Bool = false
    ) {
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: repeats)
        scheduleBasicNotification(
            title: title,
            body: body,
            userInfo: userInfo,
            trigger: trigger
        )
    }

    func scheduleInteractiveNotification(
        title: String,
        body: String,
        categoryIdentifier: String,
        userInfo: [AnyHashable: Any] = [:],
        timeInterval: TimeInterval,
        repeats: Bool = false
    ) {
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval, repeats: repeats
        )
        scheduleInteractiveNotification(
            title: title,
            body: body,
            categoryIdentifier: categoryIdentifier,
            userInfo: userInfo,
            trigger: trigger
        )
    }

    func scheduleInteractiveNotification(
        title: String,
        body: String,
        categoryIdentifier: String,
        userInfo: [AnyHashable: Any] = [:],
        date: Date,
        repeats: Bool = false
    ) {
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: repeats)
        scheduleInteractiveNotification(
            title: title,
            body: body,
            categoryIdentifier: categoryIdentifier,
            userInfo: userInfo,
            trigger: trigger
        )
    }

    // notification response when user taps an action
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let handler = actionHandlers[response.actionIdentifier] {
            handler(response)
        }
        completionHandler()
    }
}
