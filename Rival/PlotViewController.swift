//
//  PlotViewController.swift
//  Rival
//
//  Created by Yannik Schroeder on 22.04.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import UIKit
import Charts

///A formatter that disables value labels for zeros
class NoZerosFormatter: DefaultValueFormatter {
    override func stringForValue(_ value: Double, entry: ChartDataEntry, dataSetIndex: Int, viewPortHandler: ViewPortHandler?) -> String {
        if value != 0 {
            return super.stringForValue(value, entry: entry, dataSetIndex: dataSetIndex, viewPortHandler: viewPortHandler)
        }
        return ""
    }
}

class UnitFormatter: DefaultValueFormatter {
    var unit = ""
    let engine = PlotEngine.shared
    
    override func stringForValue(_ value: Double, entry: ChartDataEntry, dataSetIndex: Int, viewPortHandler: ViewPortHandler?) -> String {
        if engine.folderMethod! != .time {
            return super.stringForValue(value, entry: entry, dataSetIndex: dataSetIndex, viewPortHandler: viewPortHandler) + unit
        }
        else {
            let seconds: Int = Int(1.0/engine.timeMultiplicationFactor * value)
            return Date.timeString(seconds)
        }
    }
}

class PlotViewController: UIViewController {
    
    //MARK: - Properties
     
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var detailItem: UINavigationItem!
    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var sourceButton: UIBarButtonItem!
    let pieChartView = PieChartView()
    let barChartView = BarChartView()
    let lineChartView = LineChartView()
    let filesystem = Filesystem.shared
    let engine = PlotEngine.shared
    var xAxis: XAxis!
    var yAxis: YAxis!
    var oldFormatter = IndexAxisValueFormatter()
    let colors: [UIColor] = [.blue, .red, .green, .brown, .cyan, .gray, .black]
    let noDataText: String = "Keine Daten verfügbar."

    //MARK: - Initialization
     
     override func viewDidLoad() {
        chartSetup()
        loadChartView()
     }
     
    //MARK: - Public Methods
    
    private func chartSetup() {
        //Line chart
        lineChartView.rightAxis.enabled = false
        lineChartView.xAxis.labelPosition = .bottom
        lineChartView.xAxis.granularity = 1
        lineChartView.pinchZoomEnabled = true
        lineChartView.legend.enabled = false
        lineChartView.dragEnabled = true
        lineChartView.sizeToFit()
        noDataPrep(lineChartView)
        
        //Bar chart
        barChartView.rightAxis.enabled = false
        barChartView.xAxis.labelPosition = .top
        barChartView.xAxis.granularity = 1
        barChartView.pinchZoomEnabled = true
        barChartView.legend.enabled = true
        barChartView.dragEnabled = true
        noDataPrep(barChartView)
        
        //Pie chart
        pieChartView.drawHoleEnabled = false
        noDataPrep(pieChartView)
    }
    
    private func noDataPrep(_ base: ChartViewBase) {
        base.noDataText = noDataText
        base.noDataFont = UIFont.boldSystemFont(ofSize: 18)
    }
    
    func loadChartView() {
        if stackView.arrangedSubviews.count > 0 {
            stackView.removeArrangedSubview(stackView.arrangedSubviews.first!)
        }
        switch(engine.plotType) {
        case .line:
            stackView.addArrangedSubview(lineChartView)
            xAxis = lineChartView.xAxis
            yAxis = lineChartView.leftAxis
        case .bar:
            stackView.addArrangedSubview(barChartView)
            xAxis = barChartView.xAxis
            yAxis = barChartView.leftAxis
        case .pie:
            stackView.addArrangedSubview(pieChartView)
            xAxis = nil
            yAxis = nil
        }
    }
    
    func refreshPlot() {
        engine.update()
        detailItem?.title = engine.headline()
        if engine.plotType == .line {
            sourceButton?.title = "Aktivität"
        }
        else {
            sourceButton?.title = "Ordner"
        }
        guard engine.ready else {
            return
        }
        loadChartView()
        switch(engine.plotType) {
        case .line:
            guard let set = engine.lineChartDataSet, containsData(set) else {
                lineChartView.data = nil
                return
            }
            if engine.activity!.measurementMethod == .yesNo {
                yAxis.axisMaximum = 1
                yAxis.axisMinimum = 0
                yAxis.labelCount = 2
                yAxis.valueFormatter = IndexAxisValueFormatter(values: ["Nein", "Ja"])
                yAxis.labelFont = UIFont.boldSystemFont(ofSize: 12)
                set.drawValuesEnabled = false
                //lineChartView.leftYAxisRenderer = MyYAxisRenderer(ylabel: engine.ylabel!, plotTitle: engine.plotTitle!, base: lineChartView)
            }
            else {
                xAxis.valueFormatter = IndexAxisValueFormatter(values: engine.labels!)
                yAxis.resetCustomAxisMax()
                yAxis.resetCustomAxisMin()
                yAxis.labelCount = 6
                yAxis.labelFont = UIFont.systemFont(ofSize: 12)
                yAxis.valueFormatter = nil
                var position = MyYAxisRenderer.Position.top
                if set.entries[0].y-set.yMin > (set.yMax-set.yMin) / 2 {
                    position = .bottom
                }
                //lineChartView.leftYAxisRenderer = MyYAxisRenderer(ylabel: engine.ylabel!, plotTitle: engine.plotTitle!, base: lineChartView, position: position)
            }
            set.setCircleColor(UIColor.black)
            set.drawCircleHoleEnabled = false
            set.valueTextColor = UIColor.gray
            set.valueFont = UIFont.boldSystemFont(ofSize: 12)
            set.valueFormatter = NoZerosFormatter(decimals: 2)
            set.circleRadius = 5
            set.setColor(UIColor.black)
            lineChartView.data = LineChartData(dataSet: set)
            
        case .bar:
            guard let set = engine.barChartDataSet, containsData(set) else {
                barChartView.data = nil
                return
            }
            xAxis.valueFormatter = IndexAxisValueFormatter(values: engine.labels!)
            set.colors = Array(colors.prefix(set.stackLabels.count))
            set.valueFormatter = NoZerosFormatter(decimals: 2)
            barChartView.data = BarChartData(dataSet: engine.barChartDataSet)
        case .pie:
            guard let set = engine.pieChartDataSet, containsData(set) else {
                pieChartView.data = nil
                return
            }
            set.colors = Array(colors.prefix(set.count))
            pieChartView.data = PieChartData(dataSet: engine.pieChartDataSet)
            let data = pieChartView.data!
            let formatter = UnitFormatter(decimals: 2)
            formatter.unit = engine.folderUnit!
            data.setValueFormatter(formatter)
            data.setValueTextColor(.black)
        }
    }
    
    private func containsData(_ set: ChartDataSet) -> Bool {
        return !set.isEmpty && set.yMax != 0
    }

    // MARK: - Navigation
    
    @IBAction func unwindToPlotView(sender: UIStoryboardSegue) {
        refreshPlot()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let owningNavigationController = segue.destination as! UINavigationController
        if segue.identifier == "PlotSelection" {
            let folderController = owningNavigationController.topViewController as! FolderTableViewController
            if engine.plotType == .line {
                folderController.mode = .singlePlotSelection
                folderController.selectionCallback = { (activity, folder) in
                    self.engine.activity = activity!
                }
            }
            else {
                folderController.mode = .multiplePlotSelection
                folderController.selectionCallback = { (activity, folder) in
                    self.engine.folder = folder!
                }
            }
            folderController.selectedActivity = engine.activity
        }
        else if segue.identifier == "DateSelection" {
            let dateController = owningNavigationController.topViewController as! TimePeriodSelectionTableViewController
            
        }
        else if segue.identifier == "PlotOptions" {
            let optionsController = owningNavigationController.topViewController as! PlotOptionsTableViewController
        }
    }
}
