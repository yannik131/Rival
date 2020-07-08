//
//  TimePeriodSelectionTableViewController.swift
//  Rival
//
//  Created by Yannik Schroeder on 05.05.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import UIKit

class TimePeriodSelectionTableViewController: UITableViewController {
    
    //MARK: - Properties
    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var granularityPicker: UIPickerView!
    @IBOutlet weak var periodTemplatePicker: UIPickerView!
    
    var availableComponents: [(Calendar.Component, String)] = [(.day, "Tag"), (.weekOfYear, "Woche"), (.month, "Monat"), (.year, "Jahr")]
    let engine = PlotEngine.shared
    let options = Options.getInstance()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dateButton.createBorder()
        self.granularityPicker.delegate = self
        self.granularityPicker.dataSource = self
        self.periodTemplatePicker.delegate = self
        self.periodTemplatePicker.dataSource = self
        self.granularityPicker.selectRow(availableComponents.firstIndex(where: {$0.0 == options.granularity})!, inComponent: 0, animated: false)
        self.periodTemplatePicker.selectRow(PeriodTemplate.allCases.firstIndex(of: options.periodTemplate)!, inComponent: 0, animated: false)
        dateButton.setTitle(engine.rangeString, for: .normal)
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch(segue.identifier ?? "") {
        case "selectDateRange":
            engine.changePeriodTemplate(to: .custom)
            self.periodTemplatePicker.selectRow(PeriodTemplate.allCases.firstIndex(of: .custom)!, inComponent: 0, animated: false)
            let navigationController = segue.destination as! UINavigationController
            let calendarViewController = navigationController.topViewController as! CalendarViewController
            calendarViewController.selectionMode = .rangeSelection
            calendarViewController.firstDate = options.startDate
            calendarViewController.secondDate = options.endDate
            calendarViewController.rangeSelectionCallback = {
                self.engine.setDateRange(from: $0, to: $1)
            }
            calendarViewController.activity = engine.activity
        default:
            break
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
    
    @IBAction func unwindFromCalendar(sender: UIStoryboardSegue) {
        dateButton.setTitle(engine.rangeString, for: .normal)
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
            return availableComponents.count
        case self.periodTemplatePicker:
            return PeriodTemplate.allCases.count
        default:
            fatalError()
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch(pickerView) {
        case self.granularityPicker:
            return availableComponents[row].1
        case self.periodTemplatePicker:
            return PeriodTemplate.allCases[row].rawValue
        default:
            fatalError()
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch(pickerView) {
        case self.granularityPicker:
            options.granularity = availableComponents[row].0
        case self.periodTemplatePicker:
            engine.changePeriodTemplate(to: PeriodTemplate.allCases[row])
            dateButton.setTitle(engine.rangeString, for: .normal)
        default:
            fatalError()
        }
    }
    
}
