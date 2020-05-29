//
//  Activity.swift
//  Rival
//
//  Created by Yannik Schroeder on 13.04.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import Foundation
import Charts

enum MeasurementMethod: String, CaseIterable, Codable {
    case yesNo //Yes, I played piano today.
    case time //I played guitar for 25 minutes.
    case doubleWithUnit //I ran 3.2 kilometers.
    case intWithoutUnit //I did 25 pushups.
    //TODO: case GPSkm, case syncWithStepCounter, use other sensors
}

enum AttachmentType: String, CaseIterable, Codable {
    case none
    case photo
    case audio
    case video
}

///Convenience struct to simplify serialization
struct ActivityMetaData: Codable {
    var name: String
    var unit: String
    let id: UUID
    let measurementMethod: MeasurementMethod
    let attachmentType: AttachmentType
}

class Activity: Codable {
    
    // MARK: - Properties
    
    // MARK: Measurements
    
    var measurementsSaved: Bool
    var measurements: [String:Double] = [:] {
        didSet {
            measurementsSaved = false
        }
    }
    
    // MARK: Comments
    
    var commentsSaved: Bool
    var comments: [String:String] = [:] {
        didSet {
            commentsSaved = false
        }
    }
    
    //MARK: General Information
    
    var infoSaved: Bool
    var name: String {
        didSet {
            infoSaved = false
        }
    }
    var unit: String {
        didSet {
            infoSaved = false
        }
    }
    let id: UUID
    let measurementMethod: MeasurementMethod
    let attachmentType: AttachmentType
    
    var info: ActivityMetaData {
        return ActivityMetaData(name: name, unit: unit, id: id, measurementMethod: measurementMethod, attachmentType: attachmentType)
    }
    
    //MARK: - Initialization
    
    init(info: ActivityMetaData) {
        id = info.id
        name = info.name
        measurementMethod = info.measurementMethod
        attachmentType = info.attachmentType
        unit = info.unit
        measurementsSaved = false
        commentsSaved = false
        infoSaved = false
        if name == "5km Lauf" {
            fillWithTimeData()
        }
    }
    
    //MARK: - Public Methods
    
    ///Because activity.measurements[date.dateString()] is the most frequently accessed attribute, this subscript shortens the whole thing to activity[date]
    subscript(date: Date) -> Double {
        get {
            return measurements[date.dateString(), default: 0]
        }
        set {
            measurements[date.dateString()] = newValue
        }
    }
    
    func measurementToString(date: Date! = nil, measurement: Double! = nil) -> String {
        var measurement: Double! = measurement
        if measurement == nil {
            measurement = self[date]
        }
        
        switch(info.measurementMethod) {
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
            return "\(Double(round(measurement! * 100) / 100)) \(info.unit)"
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
        var end: Date
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
        //Because a while loop is used, the end date would  be excluded without this
        end.addDays(days: 1)
        var current = start
        var currentNumber = -1
        while !Calendar.iso.isDate(current, equalTo: end, toGranularity: .day) {
            let number = Calendar.iso.component(granularity, from: current)
            if number != currentNumber {
                currentNumber = number
                entries.append(ChartDataEntry(x: Double(entries.count), y: 0.0))
                labels.append(formatter(current))
            }
            entries.last!.y += measurements[current.dateString(), default: 0]
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
    
    //MARK: Sample data for debug purposes
    private func set(_ min: Double, _ sec: Double) {
        measurements[start.dateString()] = min * 60 + sec
        start.addDays(days: 2)
    }
    
    private func fillWithTimeData() {
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
        set(23, 29)
        set(22, 58)
        set(23, 36)
        self[DateFormats.shortYear.date(from: "23.04.20")!] = 26*60+8
        self[DateFormats.shortYear.date(from: "26.04.20")!] = 24*60+31
        self[DateFormats.shortYear.date(from: "28.04.20")!] = 25*60+35
        measurementsSaved = false
    }
}

var start = DateFormats.shortYear.date(from: "02.05.20")!
