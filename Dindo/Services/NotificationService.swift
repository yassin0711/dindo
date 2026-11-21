import UserNotifications

/// Rappels locaux de vaccination (notifications du téléphone, sans serveur)
enum NotificationService {

    /// Demande l'autorisation au premier lancement
    static func requestPermission() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }

    /// Rappel le jour du vaccin à 8 h (rien si la date est déjà passée)
    static func scheduleVaccine(id: String, name: String, flockName: String, date: Date) {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = 8
        guard let reminderDate = Calendar.current.date(from: components), reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "vaccine.reminder.title".localized
        content.body = String(format: "vaccine.reminder.body".localized, name, flockName)
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func cancel(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}
