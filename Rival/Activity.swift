//
//  Activity.swift
//  Rival
//
//  Created by Yannik Schroeder on 13.04.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import Foundation
import os.log
import Charts

open class Activity: Codable {
    
    // MARK: - Properties
    
    var name: String {
        didSet {
            saved = false
        }
    }
    let measurementMethod: MeasurementMethod
    let attachmentType: AttachmentType
    var unit: String
    public var saved: Bool
    private var dayData = [String:DailyContent]() {
        didSet {
            saved = false
        }
    }
    let id: UUID
    
    //MARK: - Initialization
    
    init?(name: String, measurementMethod: MeasurementMethod, unit: String = "", attachmentType: AttachmentType = .none, id: UUID? = nil) {
        guard !name.isEmpty || !(measurementMethod == .doubleWithUnit && unit.isEmpty) else {
            return nil
        }
        if let id = id {
            self.id = id
        }
        else {
            self.id = UUID()
        }
        self.attachmentType = attachmentType
        self.name = name
        self.measurementMethod = measurementMethod
        self.unit = unit
        saved = false
        if measurementMethod == .time {
            //fillWithTimeData()
        }
    }
    
    //MARK: - Types
    
    struct DailyContent: Codable {
        var measurement: Double = 0
        var comment: String = ""
        var photo: Data? = nil
        var audio: Data? = nil
        var video: Data? = nil
    }
    
    enum MeasurementMethod: String, CaseIterable, Codable {
        case yesNo //Yes, I played piano today.
        case time //I played guitar for 25 minutes.
        case doubleWithUnit //I ran 3.2 kilometers.
        case intWithoutUnit //I did 25 pushups.
    }
    
    enum AttachmentType: String, CaseIterable, Codable {
        case none
        case photo
        case audio
        case video
    }
    
    //MARK: - Public Methods
    
    subscript(date: Date) -> DailyContent {
        get {
            let dateString = date.dateString()
            if self.dayData[dateString] == nil {
                self.dayData[dateString] = DailyContent()
            }
            return self.dayData[dateString]!
        }
        set {
            let dateString = date.dateString()
            if self.dayData[dateString] == nil {
                self.dayData[dateString] = DailyContent()
            }
            self.dayData[dateString] = newValue
        }
    }
    
    func getPracticeAmountString(date: Date) -> String {
        let measurement = self[date].measurement
        
        switch(self.measurementMethod) {
        case .yesNo:
            if measurement == 0 {
                return "Nein"
            }
            else {
                return "Ja"
            }
        case .doubleWithUnit:
            return "\(measurement) \(self.unit)"
        case .time:
            return Date.timeString(Int(measurement))
        case .intWithoutUnit:
            return "\(Int(measurement))"
        }
    }
    
    func createDataEntries(from startDate: Date, to endDate: Date, summationGranularity: Date.Granularity) -> (entries: [ChartDataEntry], labels: [String]) {
        guard startDate < endDate else {
            fatalError()
        }
        //If stepWidth is week/month/year, then we start with the first day/week/month of the week/month/year that startDate is part of and end vice versa on endDate
        var entries: [ChartDataEntry] = []
        var labels: [String] = []
        var counter: Int = 0
        var current: Date
        switch(summationGranularity) {
        case .day:
            var endDate = endDate
            endDate.addDays(days: 1)
            current = startDate
            while !Calendar.current.isDate(current, equalTo: endDate, toGranularity: .day) {
                entries.append(ChartDataEntry(x: Double(counter), y: self[current].measurement))
                labels.append(current.dateString(with: DateFormats.dayMonth))
                current.addDays(days: 1)
                counter += 1
            }
        case .week:
            let start = startDate.startOfWeek
            current = start
            let end = endDate.endOfWeek
            var currentWeekNumber = -1
            while !Calendar.current.isDate(current, equalTo: end, toGranularity: .day) {
                let weekNumber = Calendar.iso.component(.weekOfYear, from: current)
                if currentWeekNumber != weekNumber {
                    currentWeekNumber = weekNumber
                    entries.append(ChartDataEntry(x: Double(entries.count), y: 0.0))
                    labels.append(current.startOfWeek.dateString(with: DateFormats.dayOnly) + "-" + current.endOfWeek.dateString(with: DateFormats.dayOnly))
                }
                entries[entries.count-1].y += self[current].measurement
                current.addDays(days: 1)
            }
        case .month:
            fallthrough
        case .year:
            fatalError()
        }
        
        return (entries, labels)
    }
    
    //MARK: - Private Methods
    
    func fillWithTimeData() {
        var date = Date()
        let times: [Double] = [3600, 2745, 3711, 4000, 2000, 600, 400]
        for i in 0..<times.count {
            self[date].measurement = times[i]
            date.addDays(days: -1)
        }
        saved = false
    }
}
