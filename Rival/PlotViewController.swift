//
//  PlotViewController.swift
//  Rival
//
//  Created by Yannik Schroeder on 22.04.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import UIKit
import Charts

//This is used for the y-axis label
@IBDesignable
class RotationLabel: UILabel {
    @IBInspectable
    var rotation: Int {
        get {
            return 0
        }
        set {
            let radians = Float.pi / 180.0 * Float(newValue)
            self.transform = CGAffineTransform(rotationAngle: CGFloat(radians))
        }
    }
}

class MyFormatter: DefaultValueFormatter {
    override func stringForValue(_ value: Double, entry: ChartDataEntry, dataSetIndex: Int, viewPortHandler: ViewPortHandler?) -> String {
        if value != 0 {
            return super.stringForValue(value, entry: entry, dataSetIndex: dataSetIndex, viewPortHandler: viewPortHandler)
        }
        return ""
    }
}

class PlotViewController: UIViewController {
    
    //MARK: - Types
     
    enum PlotType {
        case Bar
        case Line
        case Pie
    }
    
    //MARK: - Properties
     
    @IBOutlet weak var lineChartView: LineChartView!
    @IBOutlet weak var detailItem: UINavigationItem!
    @IBOutlet weak var dateButton: UIButton!
    var toPlot: Activity? {
        didSet {
            self.refreshPlot()
        }
    }
     
    let filesystem = Filesystem.shared
    var selectedPlotType: PlotType = .Line
    var startDate: Date = Date().addingTimeInterval(TimeInterval(exactly: 86400 * 7 * -1)!)
    var endDate: Date = Date()
    var selectedGranularity: Calendar.Component = .day
    var selectedPeriodTemplate: Date.PeriodTemplate = .last7Days
    var xAxis: XAxis!
    var yAxis: YAxis!
    var oldFormatter = IndexAxisValueFormatter()
    var selectedPlotTitleState: PlotTitleState = .sum
    var timeMultiplicationFactor: Double = 1.0
    var ignoreZeros: Bool = false

    //MARK: - Initialization
     
     override func viewDidLoad() {
        super.viewDidLoad()
        lineChartView.noDataText = "Keine Aktivität ausgewählt"
        lineChartView.noDataFont = UIFont.systemFont(ofSize: 18)
        self.xAxis = self.lineChartView.xAxis
        self.yAxis = self.lineChartView.leftAxis
        let activities = filesystem.root.orderedActivities
        toPlot = activities.first
        if toPlot == nil {
            detailItem.title = "Aktivität: " + selectedPeriodTemplate.rawValue
        }
     }
     
    //MARK: - Public Methods
     
    func refreshPlot() {
        guard let activity = self.toPlot else {
            if let chart = self.lineChartView {
                chart.data = nil
            }
            return
        }
        if self.selectedPeriodTemplate == .custom {
            self.detailItem.title = activity.name + ": " + startDate.dateString() + "-" + endDate.dateString()
        }
        else {
            self.detailItem.title = activity.name + ": " + self.selectedPeriodTemplate.rawValue
        }
        
        let (set, labels, yTitle) = self.generatePlotInformation(from: activity)
        if labels.isEmpty {
            lineChartView.data = nil
            lineChartView.noDataText = "Keine Daten verfügbar"
            return
        }

        xAxis.valueFormatter = IndexAxisValueFormatter(values: labels)
        xAxis.granularity = 1
        xAxis.labelPosition = .bottom
        lineChartView.rightAxis.enabled = false
        
        var position = MyYAxisRenderer.Position.top
        if set.entries[0].y-set.yMin > (set.yMax-set.yMin) / 2 {
            position = .bottom
        }
        if toPlot!.measurementMethod == .yesNo {
            position = MyYAxisRenderer.Position.top
            yAxis.axisMaximum = 1
            yAxis.axisMinimum = 0
            yAxis.labelCount = 2
            yAxis.valueFormatter = IndexAxisValueFormatter(values: ["Nein", "Ja"])
            yAxis.labelFont = UIFont.boldSystemFont(ofSize: 12)
            set.drawValuesEnabled = false
        }
        else {
            yAxis.resetCustomAxisMax()
            yAxis.resetCustomAxisMin()
            yAxis.labelCount = 6
            yAxis.labelFont = UIFont.systemFont(ofSize: 12)
            yAxis.valueFormatter = nil
        }
        
        lineChartView.xAxisRenderer = MyXAxisRenderer(title: "", base: lineChartView)
        lineChartView.legend.enabled = false
        lineChartView.pinchZoomEnabled = true
        lineChartView.dragEnabled = true
        
        set.setCircleColor(UIColor.black)
        set.drawCircleHoleEnabled = false
        set.valueTextColor = UIColor.gray
        set.valueFont = UIFont.boldSystemFont(ofSize: 12)
        set.valueFormatter = MyFormatter(decimals: 2)
        
        set.circleRadius = 5
        set.setColor(UIColor.black)
        let data = LineChartData(dataSet: set)
        lineChartView.data = data
        lineChartView.leftYAxisRenderer = MyYAxisRenderer(title: yTitle, plotTitle: getTitle(), base: lineChartView, position: position)
    }
     
    //MARK: - Private Methods
    
    private func getTitle() -> String {
        guard let data = lineChartView.data else {
            return ""
        }
        let set = data.dataSets.first! as! LineChartDataSet
        let sum = set.entries.reduce(0, {$0 + $1.y*(1.0/timeMultiplicationFactor)})
        var title = selectedPlotTitleState.rawValue + ": "
        switch(selectedPlotTitleState) {
        case .sum:
            title += "\(toPlot!.getPracticeAmountString(measurement: sum))"
        case .average:
            title += "\(toPlot!.getPracticeAmountString(measurement: sum/Double(set.entries.count)))"
        case .median:
            let entries = set.entries.sorted(by: {$0.y < $1.y})
            let median = entries[Int(entries.count/2)].y*(1.0/timeMultiplicationFactor)
            title += "\(toPlot!.getPracticeAmountString(measurement: median))"
        case .min:
            title += "\(toPlot!.getPracticeAmountString(measurement: set.yMin*(1.0/timeMultiplicationFactor)))"
        case .max:
            title += "\(toPlot!.getPracticeAmountString(measurement: set.yMax*(1.0/timeMultiplicationFactor)))"
        }
        return title
    }
    
    private func generatePlotInformation(from activity: Activity) -> (set: LineChartDataSet, labels: [String], yTitle: String) {
        let (entries, labels) = activity.createDataEntries(from: self.startDate, to: self.endDate, granularity: self.selectedGranularity, ignoreZeros: ignoreZeros)
        guard !entries.isEmpty else {
            return (LineChartDataSet(entries), labels, "")
        }
        let title: String
        let maximum = entries.max(by: {$0.y < $1.y})!.y
        timeMultiplicationFactor = 1.0
        switch(activity.measurementMethod) {
        case .doubleWithUnit:
            title = activity.name + " [" + activity.unit + "]"
        case .intWithoutUnit:
            title = ""
        case .time:
            let (hours, minutes, _) = Date.split(Int(maximum))
            if hours > 0 {
                title = "Zeit [h]"
                timeMultiplicationFactor = 1.0/3600
            }
            else if minutes > 0 {
                title = "Zeit [m]"
                timeMultiplicationFactor = 1.0/60
            }
            else {
                title = "Zeit [s]"
            }
            for dataEntry in entries {
                dataEntry.y *= timeMultiplicationFactor
            }
        case .yesNo:
            title = ""
        }
        
        let set = LineChartDataSet(entries)
        return (set, labels, title)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let owningNavigationController = segue.destination as! UINavigationController
        if segue.identifier == "PlotSelection" {
            let folderController = owningNavigationController.topViewController as! FolderTableViewController
            folderController.mode = .plotSelection
            folderController.selectionCallback = { (activity: Activity) in
                self.toPlot = activity
            }
            folderController.selectedActivity = self.toPlot
        }
        else if segue.identifier == "DateSelection" {
            let dateController = owningNavigationController.topViewController as! TimePeriodSelectionTableViewController
            dateController.startDate = self.startDate
            dateController.endDate = self.endDate
            dateController.selectedPeriodTemplate = self.selectedPeriodTemplate
            dateController.selectedGranularity = self.selectedGranularity
            dateController.selectionCallback = {(startDate: Date, endDate: Date, granularity: Calendar.Component, periodTemplate: Date.PeriodTemplate) in
                self.startDate = startDate
                self.endDate = endDate
                self.selectedGranularity = granularity
                self.selectedPeriodTemplate = periodTemplate
                self.refreshPlot()
            }
            dateController.activity = toPlot
        }
        else if segue.identifier == "PlotOptions" {
            let optionsController = owningNavigationController.topViewController as! PlotOptionsTableViewController
            optionsController.selectedPlotTitleState = selectedPlotTitleState
            optionsController.plotTitleSelectionCallback = { (state: PlotTitleState) in
                self.selectedPlotTitleState = state
                self.refreshPlot()
            }
            optionsController.ignoreZeros = ignoreZeros
            optionsController.ignoreZerosCallback = { (ignoreZeros: Bool) in
                self.ignoreZeros = ignoreZeros
                self.refreshPlot()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //print("PlotView appears with startDate = \(startDate), endDate = \(endDate) and selectedGranularity = \(selectedGranularity)")
    }
}
