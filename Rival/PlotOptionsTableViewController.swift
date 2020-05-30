//
//  PlotOptionsTableViewController.swift
//  Rival
//
//  Created by Yannik Schroeder on 04.05.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import UIKit

enum PlotTitleState: String, CaseIterable {
    case sum = "Summe"
    case median = "Median"
    case average = "Durchschnitt"
    case min = "Minimum"
    case max = "Maximum"
}

enum PlotType: String, CaseIterable {
    case bar = "Balken"
    case line = "Linie"
    case pie = "Torte"
}

class PlotOptionsTableViewController: UITableViewController {

    @IBOutlet weak var plotTitlePicker: UIPickerView!
    @IBOutlet weak var plotTypePicker: UIPickerView!
    @IBOutlet weak var ignoreZerosSwitch: UISwitch!
    var selectedPlotTitleState: PlotTitleState!
    var plotTitleSelectionCallback: ((PlotTitleState) -> Void)!
    var selectedPlotType: PlotType!
    var plotTypeSelectionCallback: ((PlotType) -> Void)!
    var ignoreZeros: Bool!
    var ignoreZerosCallback: ((Bool) -> Void)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        plotTitlePicker.delegate = self
        plotTitlePicker.dataSource = self
        plotTitlePicker.selectRow(PlotTitleState.allCases.firstIndex(where: {$0 == selectedPlotTitleState})!, inComponent: 0, animated: true)
        plotTypePicker.delegate = self
        plotTypePicker.dataSource = self
        plotTypePicker.selectRow(PlotType.allCases.firstIndex(where: {$0 == selectedPlotType})!, inComponent: 0, animated: true)
        ignoreZerosSwitch.isOn = ignoreZeros
        ignoreZerosSwitch.addTarget(self, action: #selector(ignoreZerosSwitchTapped), for: .touchUpInside)
        ignoreZerosSwitch.onTintColor = UIColor(red: 0.1, green: 0.7, blue: 0.1, alpha: 1)
    }
    
    //MARK: - Actions
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func ignoreZerosSwitchTapped() {
        ignoreZeros = ignoreZerosSwitch.isOn
        ignoreZerosCallback(ignoreZeros)
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
}

extension PlotOptionsTableViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == plotTitlePicker {
            return PlotTitleState.allCases[row].rawValue
        }
        else if pickerView == plotTypePicker {
            return PlotType.allCases[row].rawValue
        }
        else {
            fatalError()
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == plotTitlePicker {
            plotTitleSelectionCallback(PlotTitleState.allCases[row])
        }
        else if pickerView == plotTypePicker {
            plotTypeSelectionCallback(PlotType.allCases[row])
        }
    }
}

extension PlotOptionsTableViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == plotTitlePicker {
            return PlotTitleState.allCases.count
        }
        else if pickerView == plotTypePicker {
            return PlotType.allCases.count
        }
        else {
            fatalError()
        }
    }
}
