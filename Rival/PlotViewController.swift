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
     
    let filesystem = Filesystem.getInstance()
    var selectedPlotType: PlotType = .Line
    var startDate: Date = Date().addingTimeInterval(TimeInterval(exactly: 86400 * 7 * -1)!)
    var endDate: Date = Date()
    var selectedGranularity: Date.Granularity = .day
    var selectedPeriodTemplate: Date.PeriodTemplate = .last7Days
    var xAxis: XAxis!
    var yAxis: YAxis!
    var oldFormatter = IndexAxisValueFormatter()
    var rawTotal: Double = 0.0

    //MARK: - Initialization
     
     override func viewDidLoad() {
        super.viewDidLoad()
        self.xAxis = self.lineChartView.xAxis
        self.yAxis = self.lineChartView.leftAxis
        self.toPlot = self.filesystem.getAllActivities()[0]
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

        xAxis.valueFormatter = IndexAxisValueFormatter(values: labels)
        xAxis.granularity = 1
        xAxis.labelPosition = .bottom
        lineChartView.rightAxis.enabled = false
        
        var position = MyYAxisRenderer.Position.top
        if set.entries[0].y > yAxis.axisMaximum / 2 {
            position = .bottom
        }
        if toPlot!.measurementMethod == .YesNo {
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
        
        lineChartView.leftYAxisRenderer = MyYAxisRenderer(title: yTitle, plotTitle: self.getSumString(), base: lineChartView, position: position)
        lineChartView.xAxisRenderer = MyXAxisRenderer(title: "", base: lineChartView)
        lineChartView.legend.enabled = false
        lineChartView.pinchZoomEnabled = true
        lineChartView.dragEnabled = true
        
        set.setCircleColor(UIColor.black)
        set.drawCircleHoleEnabled = false
        set.valueTextColor = UIColor.gray
        set.valueFont = UIFont.boldSystemFont(ofSize: 12)
        set.valueFormatter = DefaultValueFormatter(decimals: 2)
        set.circleRadius = 5
        set.setColor(UIColor.black)
        let data = LineChartData(dataSet: set)
        
        lineChartView.data = data
    }
     
    //MARK: - Private Methods
    
    private func getSumString() -> String {
        switch(toPlot!.measurementMethod) {
        case .YesNo:
            return "Summe: \(Int(rawTotal))x"
        case .Time:
            return "Summe: \(Date.timeString(Int(rawTotal)))"
        case .DoubleWithUnit:
            return "Summe: \(Double(round(rawTotal * 100) / 100)) [\(toPlot!.unit!)]"
        case .IntWithoutUnit:
            return "Summe: \(Int(rawTotal))"
        }
    }
    
    private func generatePlotInformation(from activity: Activity) -> (set: LineChartDataSet, labels: [String], yTitle: String) {
        let (entries, labels) = activity.createDataEntries(from: self.startDate, to: self.endDate, summationGranularity: self.selectedGranularity)
        rawTotal = entries.reduce(0, {$0 + $1.y})
        let title: String
        let maximum = entries.max(by: {$0.y < $1.y})!.y
        switch(activity.measurementMethod) {
        case .DoubleWithUnit:
            title = activity.name + " [" + activity.unit! + "]"
        case .IntWithoutUnit:
            title = activity.name
        case .Time:
            let (hours, minutes, _) = Date.split(Int(maximum))
            let factor: Double
            if hours > 0 {
                title = "Zeit [h]"
                factor = 1.0/3600
            }
            else if minutes > 0 {
                title = "Zeit [m]"
                factor = 1.0/60
            }
            else {
                title = "Zeit [s]"
                factor = 1.0
            }
            for dataEntry in entries {
                dataEntry.y *= factor
            }
        case .YesNo:
            title = ""
        }
        
        let set = LineChartDataSet(entries)
        return (set, labels, title)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let owningNavigationController = segue.destination as! UINavigationController
        if segue.identifier == "plotSelection" {
            let folderController = owningNavigationController.topViewController as! FolderTableViewController
            folderController.mode = .plotSelection
            folderController.selectionCallback = { (activity: Activity) in
                self.toPlot = activity
            }
            folderController.selectedActivity = self.toPlot
        }
        else if segue.identifier == "dateSelection" {
            let dateController = owningNavigationController.topViewController as! TimePeriodSelectionTableViewController
            dateController.startDate = self.startDate
            dateController.endDate = self.endDate
            dateController.selectedPeriodTemplate = self.selectedPeriodTemplate
            dateController.selectedGranularity = self.selectedGranularity
            dateController.selectionCallback = {(startDate: Date, endDate: Date, granularity: Date.Granularity, periodTemplate: Date.PeriodTemplate) in
                self.startDate = startDate
                self.endDate = endDate
                self.selectedGranularity = granularity
                self.selectedPeriodTemplate = periodTemplate
                self.refreshPlot()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //print("PlotView appears with startDate = \(startDate), endDate = \(endDate) and selectedGranularity = \(selectedGranularity)")
    }
}
