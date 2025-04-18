//
//  NotificationManager.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/4/25.
//

import Logging
import SwiftUI
import UserNotifications

typealias NotificationActionHandler = (UNNotificationResponse) -> Void

struct NotificationAction {
    let identifier: String
    let title: String
    let options: UNNotificationActionOptions
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
    private let logger = Logger(label: "athena.NotificationManager")

    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func registerCategory(_ category: NotificationCategory) {
        categories[category.identifier] = category

        // Store action handlers
        for action in category.actions {
            actionHandlers[action.identifier] = action.handler
        }

        // Create notification actions
        let notificationActions = category.actions.map { action in
            UNNotificationAction(
                identifier: action.identifier,
                title: action.title,
                options: action.options
            )
        }

        // Create and register the category
        let notificationCategory = UNNotificationCategory(
            identifier: category.identifier,
            actions: notificationActions,
            intentIdentifiers: [],
            options: []
        )

        // Get existing categories and add the new one
        UNUserNotificationCenter.current().getNotificationCategories { categories in
            var updatedCategories = categories
            updatedCategories.insert(notificationCategory)
            UNUserNotificationCenter.current().setNotificationCategories(updatedCategories)
        }
    }

    func requestPermission(completion: @escaping (Bool, Error?) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge, .provisional],
            completionHandler: completion
        )
    }

    private func scheduleBasicNotification(
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

        scheduleNotification(content: content, trigger: trigger)
    }

    func scheduleBasicNotification(
        title: String,
        body: String,
        userInfo: [AnyHashable: Any] = [:],
        date: Date,
        repeats: Bool = false
    ) {
        let trigger = createCalendarTrigger(from: date, repeats: repeats)
        scheduleBasicNotification(title: title, body: body, userInfo: userInfo, trigger: trigger)
    }

    private func scheduleInteractiveNotification(
        title: String,
        body: String,
        categoryIdentifier: String,
        userInfo: [AnyHashable: Any] = [:],
        trigger: UNNotificationTrigger
    ) {
        guard categories[categoryIdentifier] != nil else {
            logger.error("Error: Category \(categoryIdentifier) not registered")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = categoryIdentifier
        content.userInfo = userInfo

        scheduleNotification(content: content, trigger: trigger)
    }

    func scheduleInteractiveNotification(
        title: String,
        body: String,
        categoryIdentifier: String,
        userInfo: [AnyHashable: Any] = [:],
        date: Date,
        repeats: Bool = false
    ) {
        let trigger = createCalendarTrigger(from: date, repeats: repeats)
        scheduleInteractiveNotification(
            title: title,
            body: body,
            categoryIdentifier: categoryIdentifier,
            userInfo: userInfo,
            trigger: trigger
        )
    }

    private func createCalendarTrigger(from date: Date, repeats: Bool) -> UNCalendarNotificationTrigger {
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: date
        )
        return UNCalendarNotificationTrigger(dateMatching: components, repeats: repeats)
    }

    private func scheduleNotification(content: UNNotificationContent, trigger: UNNotificationTrigger) {
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                self.logger.error("Failed to schedule notification: \(error.localizedDescription)")
            } else {
                self.logger.info("Notification scheduled successfully.")
            }
        }
    }

    func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

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
