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
        if name == "5km Lauf" {
            fillWithTimeData()
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
    
    func getPracticeAmountString(date: Date! = nil, measurement: Double! = nil) -> String {
        var measurement: Double! = measurement
        if measurement == nil {
            measurement = self[date].measurement
        }
        
        switch(self.measurementMethod) {
        case .yesNo:
            if measurement == 0 {
                return "Nein"
            }
            else if Int(measurement) == 1 {
                return "Ja"
            }
            else {
                return String(Int(measurement)) + "x"
            }
        case .doubleWithUnit:
            return "\(Double(round(measurement! * 100) / 100)) \(self.unit)"
        case .time:
            return Date.timeString(Int(measurement))
        case .intWithoutUnit:
            return "\(Int(measurement))"
        }
    }
    
    func createDataEntries(from startDate: Date, to endDate: Date, granularity: Calendar.Component, ignoreZeros: Bool) -> (entries: [ChartDataEntry], labels: [String]) {
        guard startDate < endDate else {
            fatalError()
        }
        var entries: [ChartDataEntry] = []
        var labels: [String] = []
        let start: Date
        let end: Date
        let formatter: ((Date) -> String)
        switch (granularity) {
        case .day:
            start = startDate
            end = endDate
            formatter = { $0.dateString(with: DateFormats.dayMonth) }
        case .weekOfYear:
            start = startDate.startOfWeek
            end = endDate.endOfWeek
            formatter = { $0.startOfWeek.dateString(with: DateFormats.dayOnly) + "-" + $0.endOfWeek.dateString(with: DateFormats.dayOnly) }
        case .month:
            start = startDate.startOfMonth
            end = endDate.endOfMonth
            formatter = { $0.dateString(with: DateFormats.monthYearShort) }
        case .year:
            start = startDate.startOfYear
            end = endDate.endOfYear
            formatter = { $0.dateString(with: DateFormats.year) }
        default:
            fatalError()
        }
        var current = start
        var currentNumber = -1
        while !Calendar.iso.isDate(current, equalTo: end, toGranularity: .day) {
            let number = Calendar.iso.component(granularity, from: current)
            if number != currentNumber {
                currentNumber = number
                entries.append(ChartDataEntry(x: Double(entries.count), y: 0.0))
                labels.append(formatter(current))
            }
            entries.last!.y += self[current].measurement
            current.addDays(days: 1)
        }
        
        if ignoreZeros {
            for i in stride(from: entries.count - 1, through: 0, by: -1) {
                if entries[i].y == 0 {
                    entries.remove(at: i)
                    labels.remove(at: i)
                }
            }
            for (index, entry) in entries.enumerated() {
                entry.x = Double(index)
            }
        }
        
        return (entries, labels)
    }
    
    //MARK: - Private Methods
    
    private func set(_ min: Double, _ sec: Double) {
        self[start].measurement = min * 60 + sec
        start.addDays(days: 2)
    }
    
    func fillWithTimeData() {
        set(24, 24)
        set(24, 52)
        set(25, 46)
        set(24, 26)
        set(25, 8)
        set(24, 18)
        set(23, 44)
        set(23, 20)
        set(22, 0)
        set(23, 45)
        set(24, 26)
        self[DateFormats.shortYear.date(from: "23.04.20")!].measurement = 26*60+8
        self[DateFormats.shortYear.date(from: "26.04.20")!].measurement = 24*60+31
        self[DateFormats.shortYear.date(from: "28.04.20")!].measurement = 25*60+35
        saved = false
    }
}

var start = DateFormats.shortYear.date(from: "02.05.20")!
