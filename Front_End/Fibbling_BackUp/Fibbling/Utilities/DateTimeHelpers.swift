//
//  DateTimeHelpers.swift
//  Fibbling
//
//  Created on 2025-10-13.
//  Timezone-safe date handling and formatting
//

import Foundation
import SwiftUI

// MARK: - Timezone-Safe Date Extensions

extension Date {
    /// Format date for display - always uses user's current timezone
    func formattedForDisplay(style: DateFormatter.Style = .medium, timeStyle: DateFormatter.Style = .short) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = timeStyle
        formatter.timeZone = TimeZone.current  // Always use user's timezone
        return formatter.string(from: self)
    }
    
    /// Format date for API - always uses UTC
    func formattedForAPI() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: self)
    }
    
    /// Get timezone-safe duration between dates
    func duration(to endDate: Date) -> (hours: Int, minutes: Int, days: Int) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .hour, .minute], from: self, to: endDate)
        return (
            hours: components.hour ?? 0,
            minutes: components.minute ?? 0,
            days: components.day ?? 0
        )
    }
    
    /// Format duration string
    func durationString(to endDate: Date, includesDays: Bool = true) -> String {
        let duration = self.duration(to: endDate)
        
        if includesDays && duration.days > 0 {
            if duration.days == 1 && duration.hours == 0 && duration.minutes == 0 {
                return "Full day"
            }
            return "\(duration.days)d \(duration.hours)h"
        } else if duration.hours > 0 {
            return "\(duration.hours)h \(duration.minutes)m"
        } else {
            return "\(duration.minutes)m"
        }
    }
    
    /// Check if date is a full day event (midnight to midnight, or 24 hours)
    var isFullDayEvent: Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: self)
        let minute = calendar.component(.minute, from: self)
        return hour == 0 && minute == 0
    }
    
    /// Get start of day in user's timezone
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    /// Get end of day in user's timezone
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }
    
    /// Check if event spans multiple days
    func isMultiDay(endDate: Date) -> Bool {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: self)
        let endDay = calendar.startOfDay(for: endDate)
        return startDay != endDay
    }
    
    /// Format date with relative time (e.g., "Today at 3:00 PM")
    var relativeFormatted: String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(self) {
            return "Today at \(formattedForDisplay(style: .none, timeStyle: .short))"
        } else if calendar.isDateInTomorrow(self) {
            return "Tomorrow at \(formattedForDisplay(style: .none, timeStyle: .short))"
        } else if calendar.isDate(self, equalTo: now, toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE 'at' h:mm a"
            formatter.timeZone = TimeZone.current
            return formatter.string(from: self)
        } else {
            return formattedForDisplay()
        }
    }
}

// MARK: - API Date Parsing

extension String {
    /// Parse API date string (UTC) to local date
    func toDateFromAPI() -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: self) ?? {
            // Fallback for dates without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: self)
        }()
    }
}

// MARK: - Duration Formatting

struct DurationFormatter {
    static func format(from start: Date, to end: Date) -> String {
        start.durationString(to: end)
    }
    
    static func formatDetailed(from start: Date, to end: Date) -> String {
        let duration = start.duration(to: end)
        
        if duration.days == 1 && duration.hours == 0 {
            return "Full Day Event"
        } else if duration.days > 1 {
            return "\(duration.days) Days"
        } else if duration.hours > 0 {
            return "\(duration.hours) hour\(duration.hours == 1 ? "" : "s") \(duration.minutes) min"
        } else {
            return "\(duration.minutes) minute\(duration.minutes == 1 ? "" : "s")"
        }
    }
}

