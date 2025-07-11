import Foundation

extension Date {
    /// Дата в 00:00 текущего дня
    var atStartOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    /// Дата в 23:59:59 текущего дня
    var atEndOfDay: Date {
        Calendar.current.date(
            bySettingHour:   23,
            minute:          59,
            second:          59,
            of:               self
        )!
    }
}
