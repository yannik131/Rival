//
//  PlotEngine.swift
//  Rival
//
//  Created by Yannik Schroeder on 04.06.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import Foundation
import Charts
import os.log

enum PlotError: Error {
    case DateRangeError(String)
}

extension Double {
    func roundedTo(_ n: Double) -> Double {
        return Double((pow(10.0, n)*self).rounded()/pow(10.0, n))
    }
}

class PlotEngine {
    
    //MARK: - Properties
    
    let options = Options.getInstance()
    var activity: Activity?
    var folder: Folder?
    var folderMethod: MeasurementMethod? {
        return folder?.activities.values.first!.measurementMethod ?? nil
    }
    var folderUnit: String? {
        return folder?.activities.values.first!.unit ?? nil
    }
    var rangeString: String? {
        if options.startDate == nil {
            return nil
        }
        return options.startDate.dateString(with: DateFormats.shortYear) + "-" + options.endDate.dateString(with: DateFormats.shortYear)
    }
    var plotType: PlotType {
        return options.plotType
    }
    private(set) var timeMultiplicationFactor: Double! = 1.0
    var ready: Bool {
        return lineChartDataSet != nil && options.plotType == .line || barChartDataSet != nil && options.plotType == .bar || pieChartDataSet != nil && options.plotType == .pie
    }
    
    private(set) var lineChartDataSet: LineChartDataSet?
    private(set) var barChartDataSet: BarChartDataSet?
    private(set) var pieChartDataSet: PieChartDataSet?
    private(set) var ylabel: String?
    private(set) var plotTitle: String?
    private(set) var labels: [String]?
    
    private let factorStrings: [Double:String] = [1.0/3600:"h", 1.0/60:"m", 1.0:"s"]
    
    static let shared = PlotEngine()
    
    init() {
        changePeriodTemplate(to: options.periodTemplate)
        if let id = options.activityID {
            activity = Filesystem.shared.activities[id]
        }
        if let url = options.folderURL {
            folder = Filesystem.shared.getFolder(at: url)
        }
    }
    
    //MARK: - Public Methods
    
    ///This method requires that either activity or folder are not equal nil.
    func update() {
        guard activity != nil && plotType == .line || folder != nil && plotType != .line else {
            return
        }
        timeMultiplicationFactor = 1.0
        if plotType == .line {
            let (entries, labels) = createDataEntries(from: activity!, ignoreZeros: options.ignoreZeros)
            normalizeTimeEntries(entries: [entries])
            lineChartDataSet = LineChartDataSet(entries: entries)
            self.labels = labels
        }
        else {
            var names: [String] = []
            var chartEntries: [[ChartDataEntry]] = []
            for activity in folder!.orderedActivities {
                let (entries, labels) = createDataEntries(from: activity, ignoreZeros: false)
                self.labels = labels
                chartEntries.append(entries)
            }
            normalizeTimeEntries(entries: chartEntries)
            for (n, activity) in folder!.orderedActivities.enumerated() {
                let entries = chartEntries[n]
                var name: String
                if plotType == .bar {
                    name = activity.name + " \(String((entries.reduce(0, {$0 + $1.y})).roundedTo(2)))"
                    if activity.measurementMethod == .time {
                        name += factorStrings[timeMultiplicationFactor]!
                    }
                    else {
                        name += activity.unit
                    }
                }
                else {
                    name = activity.name
                }
                names.append(name)
            }
            var zeroIndexes: [Int] = []
            if plotType == .bar {
                var barChartEntries: [BarChartDataEntry] = []
                for i in 0..<labels!.count {
                    var stack: [Double] = []
                    for j in 0..<chartEntries.count {
                        stack.append(chartEntries[j][i].y)
                    }
                    if stack.reduce(0, {$0+$1}) == 0 && options.ignoreZeros {
                        zeroIndexes.append(i)
                    }
                    else {
                        barChartEntries.append(BarChartDataEntry(x: Double(barChartEntries.count), yValues: stack))
                    }
                }
                //Remove zeroIndexes from labels
                for i in stride(from: labels!.count-1, to: 0, by: -1) {
                    if zeroIndexes.contains(i) {
                        labels!.remove(at: i)
                    }
                }
                barChartDataSet = BarChartDataSet(entries: barChartEntries)
                barChartDataSet!.stackLabels = names
                barChartDataSet!.label = folder!.name
            }
            else if plotType == .pie {
                var pieChartEntries: [PieChartDataEntry] = []
                var totalSum: Double = 0.0
                for i in 0..<chartEntries.count {
                    let sum = chartEntries[i].reduce(0.0, {$0 + $1.y})
                    totalSum += sum
                    pieChartEntries.append(PieChartDataEntry(value: sum.roundedTo(2), label: names[i]))
                }
                for (i, entry) in pieChartEntries.enumerated() {
                    entry.label = names[i]
                    entry.label! += ": \((entry.y / totalSum * 100).roundedTo(2))%"
                }
                if options.ignoreZeros {
                    pieChartEntries.removeAll(where: {$0.y == 0})
                }
                
                pieChartDataSet = PieChartDataSet(entries: pieChartEntries)
                pieChartDataSet!.label = folder!.name
                pieChartDataSet!.entryLabelColor = UIColor.black
            }
        }
        ylabel = generateYLabel()
        plotTitle = generatePlotTitle()
        options.save()
    }
    
    func generateYLabel() -> String {
        guard options.plotType != .pie && (activity != nil || folder != nil) else {
            return ""
        }
        let method: MeasurementMethod
        let name: String
        var unit: String? = nil
        if activity != nil {
            method = activity!.measurementMethod
            name = activity!.name
            if method != .time {
                unit = activity!.unit
            }
        }
        else {
            method = folderMethod!
            name = folder!.name
            if method != .time {
                unit = folderUnit
            }
        }
        guard method == .doubleWithUnit || method == .time else {
            return ""
        }
        if unit == nil {
            return name + " [\(factorStrings[timeMultiplicationFactor]!)]"
        }
        else {
            return name + " [\(unit!)]"
        }
    }
    
    func generatePlotTitle() -> String {
        let activity: Activity
        if let a = self.activity, plotType == .line {
            activity = a
        }
        else if let folder = folder, plotType != .line {
            activity = folder.activities.values.first!
        }
        else {
            return ""
        }
        let set: ChartDataSet
        switch(plotType) {
        case .line:
            set = lineChartDataSet!
        case .bar:
            set = barChartDataSet!
        case .pie:
            set = pieChartDataSet!
        }
        var title = options.plotTitleState.rawValue + ": "
        let sum: Double = set.entries.reduce(0, {$0 + $1.y*1.0/timeMultiplicationFactor})
        if plotType == .line && activity.measurementMethod == .yesNo {
            return "Summe: \(Int(sum))x"
        }
        if(set.isEmpty) {
            return title + "0"
        }
        switch(options.plotTitleState!) {
        case .sum:
            title += "\(activity.measurementToString(measurement: sum))"
        case .average:
            title += "\(activity.measurementToString(measurement: sum/Double(set.entries.count)))"
        case .median:
            let entries = set.entries.sorted(by: {$0.y < $1.y})
            let median = entries[Int(entries.count/2)].y*(1.0/timeMultiplicationFactor)
            title += "\(activity.measurementToString(measurement: median))"
        case .min:
            title += "\(activity.measurementToString(measurement: set.yMin*(1.0/timeMultiplicationFactor)))"
        case .max:
            title += "\(activity.measurementToString(measurement: set.yMax*(1.0/timeMultiplicationFactor)))"
        }
        return title
    }
    
    func headline() -> String {
        var first: String
        if plotType == .line {
            if let activity = activity {
                first = activity.name
                if activity.measurementMethod == .time {
                    first += " [\(factorStrings[timeMultiplicationFactor]!)]"
                }
                else if !activity.unit.isEmpty {
                    first += " [\(activity.unit)]"
                }
            }
            else {
                first = "Aktivität"
            }
        }
        else {
            if let folder = folder {
                first = folder.name
                if folderMethod == .time {
                    first += " [\(factorStrings[timeMultiplicationFactor]!)]"
                }
                else if !folderUnit!.isEmpty {
                    first += " [\(folderUnit!)]"
                }
            }
            else {
                first = "Ordner"
            }
        }
        let second: String
        if options.periodTemplate == .custom {
            second = rangeString!
        }
        else {
            second = options.periodTemplate.rawValue
        }
        return first + ": " + second + ". " + generatePlotTitle()
    }
    
    func changePeriodTemplate(to template: PeriodTemplate) {
        var startDate = Date()
        var endDate = Date()
        options.set(&options.periodTemplate, template)
        switch(template) {
        case .last7Days:
            startDate = Calendar.iso.date(byAdding: .day, value: -7, to: endDate)!
        case .thisWeek:
            startDate = startDate.startOfWeek
            endDate = startDate.endOfWeek
        case .lastWeek:
            startDate = Calendar.iso.date(byAdding: .weekOfMonth, value: -1, to: startDate)!.startOfWeek
            endDate = startDate.endOfWeek
        case .thisMonth:
            startDate = startDate.startOfMonth
            endDate = startDate.endOfMonth
        case .lastMonth:
            startDate = Calendar.iso.date(byAdding: .month, value: -1, to: startDate)!.startOfMonth
            endDate = startDate.endOfMonth
        case .thisYear:
            startDate = startDate.startOfYear
            endDate = endDate.endOfYear
        case .lastYear:
            startDate = Calendar.iso.date(byAdding: .year, value: -1, to: startDate)!.startOfYear
            endDate = startDate.endOfYear
        case .custom:
            return
        }
        options.set(&options.startDate, startDate)
        options.set(&options.endDate, endDate)
    }
    
    func setDateRange(from startDate: Date, to endDate: Date) {
        options.set(&options.startDate, startDate)
        options.set(&options.endDate, endDate)
        changePeriodTemplate(to: .custom)
    }
    
    //MARK: - Private Methods
    
    private func normalizeTimeEntries(entries: [[ChartDataEntry]]) {
        if let activity = activity {
            guard activity.measurementMethod == .time else {
                return
            }
        }
        else if let folder = folder {
            guard folder.activities.values.first!.measurementMethod == .time else {
                return
            }
        }
        var maximum = entries[0].max(by: { $0.y < $1.y })?.y ?? 0.0
        for i in 1..<entries.count {
            let max = entries[i].max(by: { $0.y < $1.y })!.y
            if max > maximum {
                maximum = max
            }
        }
        let (hours, minutes, _) = Date.split(Int(maximum))
        if hours > 0 {
            timeMultiplicationFactor = 1.0/3600
        }
        else if minutes > 0 {
            timeMultiplicationFactor = 1.0/60
        }
        else {
            timeMultiplicationFactor = 1.0
        }
        for entry in entries {
            for value in entry {
                value.y *= timeMultiplicationFactor
            }
        }
    }
    
    //TODO: Give option to calculate mean/min/max/med instead of sum
    func createDataEntries(from activity: Activity, ignoreZeros: Bool, from firstDate: Date? = nil, to secondDate: Date? = nil, granularity: Calendar.Component? = nil, method: PlotTitleState = .sum) -> (entries: [ChartDataEntry], labels: [String]) {
        let chosenGranularity: Calendar.Component = granularity ?? options.granularity
        let start: Date
        var end: Date
        let startDate: Date! = firstDate ?? options.startDate
        let endDate: Date! = secondDate ?? options.endDate
        let formatter: ((Date) -> String)
        switch (chosenGranularity) {
        case .day:
            start = startDate
            end = endDate
            formatter = { $0.dateString(with: DateFormats.dayMonth) }
        case .weekOfYear:
            start = startDate.startOfWeek
            end = endDate.endOfWeek
            formatter = { $0.startOfWeek.dateString(with: DateFormats.dayMonth) + "-" + $0.endOfWeek.dateString(with: DateFormats.dayOnly) }
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
        //Add one to not exclude endDate, and again to compensate for the fact that if currentNumber changes, the day before gets added to entries
        end.addDays(days: 2)
        var current = start
        var currentNumber = Calendar.iso.component(chosenGranularity, from: current)
        var entries: [ChartDataEntry] = []
        var labels: [String] = []
        var sum: Double = 0.0
        while !Calendar.iso.isDate(current, equalTo: end, toGranularity: .day) {
            let number = Calendar.iso.component(chosenGranularity, from: current)
            if number != currentNumber {
                if sum != 0 && ignoreZeros || !ignoreZeros {
                    entries.append(ChartDataEntry(x: Double(entries.count), y: sum))
                    labels.append(formatter(current.addingDays(days: -1)))
                }
                currentNumber = number
                sum = 0.0
            }
            sum += activity[current]
            current.addDays(days: 1)
        }
        return (entries, labels)
    }
}
