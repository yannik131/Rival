//
//  TimePeriodSelectionTableViewController.swift
//  Rival
//
//  Created by Yannik Schroeder on 05.05.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import UIKit

class TimePeriodSelectionTableViewController: UITableViewController {
    
    //MARK: - Types
    
    
    
    //MARK: - Properties
    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var granularityPicker: UIPickerView!
    @IBOutlet weak var periodTemplatePicker: UIPickerView!
    
    var selectedGranularity: Date.Granularity!
    var selectedPeriodTemplate: Date.PeriodTemplate! {
        didSet {
            self.update()
        }
    }
    var startDate: Date!
    var endDate: Date!
    
    var selectionCallback: ((Date, Date, Date.Granularity, Date.PeriodTemplate) -> ())!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dateButton.createBorder()
        self.granularityPicker.delegate = self
        self.granularityPicker.dataSource = self
        self.periodTemplatePicker.delegate = self
        self.periodTemplatePicker.dataSource = self
        self.granularityPicker.selectRow(Date.Granularity.allCases.firstIndex(of: self.selectedGranularity)!, inComponent: 0, animated: false)
        self.periodTemplatePicker.selectRow(Date.PeriodTemplate.allCases.firstIndex(of: self.selectedPeriodTemplate)!, inComponent: 0, animated: false)
        self.update()
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch(segue.identifier ?? "") {
        case "selectDateRange":
            self.selectedPeriodTemplate = .custom
            self.periodTemplatePicker.selectRow(Date.PeriodTemplate.allCases.firstIndex(of: self.selectedPeriodTemplate)!, inComponent: 0, animated: false)
            let navigationController = segue.destination as! UINavigationController
            let calendarViewController = navigationController.topViewController as! CalendarViewController
            calendarViewController.selectionMode = .rangeSelection
            calendarViewController.firstDate = startDate
            calendarViewController.secondDate = endDate
            calendarViewController.rangeSelectionCallback = {
                self.startDate = $0
                self.endDate = $1
                self.update()
                self.selectionCallback($0, $1, self.selectedGranularity, self.selectedPeriodTemplate)
            }
        default:
            fatalError()
        }
    }
    
    //MARK: - Private Methods
    
    private func update() {
        var startDate = Date()
        var endDate = Date()
        switch(self.selectedPeriodTemplate) {
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
        case .custom:
            break
        default:
            fatalError()
        }
        if self.selectedPeriodTemplate != .custom {
            self.startDate = startDate
            self.endDate = endDate
        }
        if let button = self.dateButton {
            button.setTitle(self.startDate.dateString(with: DateFormats.shortYear)+"-"+self.endDate.dateString(with: DateFormats.shortYear), for: .normal)
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    //MARK: - Actions
    
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func dateButtonTapped(_ sender: UIButton) {
    }
}

extension TimePeriodSelectionTableViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch(pickerView) {
        case self.granularityPicker:
            return 4
        case self.periodTemplatePicker:
            return 6
        default:
            fatalError()
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch(pickerView) {
        case self.granularityPicker:
            return Date.Granularity.allCases[row].rawValue
        case self.periodTemplatePicker:
            return Date.PeriodTemplate.allCases[row].rawValue
        default:
            fatalError()
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch(pickerView) {
        case self.granularityPicker:
            self.selectedGranularity = Date.Granularity.allCases[row]
        case self.periodTemplatePicker:
            self.selectedPeriodTemplate = Date.PeriodTemplate.allCases[row]
        default:
            fatalError()
        }
        self.selectionCallback(self.startDate, self.endDate, self.selectedGranularity, self.selectedPeriodTemplate)
    }
    
}
