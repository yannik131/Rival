//
//  DateFormats.swift
//  Rival
//
//  Created by Yannik Schroeder on 04.05.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import Foundation

open class DateFormats {
    public static let full = DateFormatter()
    public static let dayMonth = DateFormatter()
    public static let shortYear = DateFormatter()
    public static let dayOnly = DateFormatter()
    public static let monthYearFull = DateFormatter()
    public static let monthYearShort = DateFormatter()
    public static let year = DateFormatter()
    
    static func initialize(locale: Locale) {
        DateFormats.set(formatter: DateFormats.full, template: "ddMMyyyy", locale: locale)
        DateFormats.set(formatter: DateFormats.dayMonth, template: "ddMM", locale: locale)
        DateFormats.set(formatter: DateFormats.shortYear, template: "ddMMyy", locale: locale)
        DateFormats.set(formatter: DateFormats.dayOnly, template: "dd", locale: locale)
        DateFormats.set(formatter: DateFormats.monthYearFull, template: "LLLL yyyy", locale: locale)
        DateFormats.set(formatter: DateFormats.monthYearShort, template: "MMyy", locale: locale)
        DateFormats.set(formatter: DateFormats.year, template: "yy", locale: locale)
    }
    
    private static func set(formatter: DateFormatter, template: String, locale: Locale) {
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate(template)
    }
}

extension Calendar {
    public static var iso = Calendar(identifier: .iso8601)
    
    public static func initialize(locale: Locale) {
        Calendar.iso.firstWeekday = 2
        Calendar.iso.locale = locale
    }
}

extension Date {
    
    var startOfWeek: Date {
        return Calendar.iso.date(from: Calendar.iso.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self))!
    }
    
    var endOfWeek: Date {
        return Calendar.iso.date(byAdding: .day, value: 6, to: self.startOfWeek)!
    }
    
    var startOfMonth: Date {
        return Calendar.iso.date(from: Calendar.iso.dateComponents([.year, .month], from: self))!
    }
    
    var endOfMonth: Date {
        return Calendar.iso.date(byAdding: .day, value: -1, to: Calendar.iso.date(byAdding: .month, value: 1, to: self)!.startOfMonth)!
    }
    
    var startOfYear: Date {
        return Calendar.iso.date(from: Calendar.iso.dateComponents([.year], from: self))!
    }
    
    var endOfYear: Date {
        return Calendar.iso.date(byAdding: .day, value: -1, to: Calendar.iso.date(byAdding: .year, value: 1, to: self)!.startOfYear)!
    }
    
    var month: Int {
        return Calendar.iso.component(.month, from: self)
    }
    
    enum PeriodTemplate: String, CaseIterable {
        case last7Days = "Letzte 7 Tage"
        case thisWeek = "Diese Woche"
        case lastWeek = "Letzte Woche"
        case thisMonth = "Dieser Monat"
        case lastMonth = "Letzter Monat"
        case thisYear = "Dieses Jahr"
        case lastYear = "Letztes Jahr"
        case custom = "Manuell"
    }
    
    public func dateString(with formatter: DateFormatter = DateFormats.full) -> String {
        return formatter.string(from: self)
    }
    
    public func isToday() -> Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    public mutating func addDays(days: Int) {
        self = Calendar.current.date(byAdding: .day, value: days, to: self)!
    }
    
    public static func split(_ seconds: Int) -> (hours: Int, minutes: Int, seconds: Int) {
        return (hours: seconds / 3600, minutes: (seconds % 3600) / 60, seconds: (seconds % 3600) % 60)
    }
    
    public static func timeString(_ seconds: Int) -> String {
        let (hours, minutes, seconds) = Date.split(seconds)
        if hours > 0 {
            return "\(hours)h \(minutes)m \(seconds)s"
        }
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
}

