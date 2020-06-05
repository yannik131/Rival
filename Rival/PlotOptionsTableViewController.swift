//
//  PlotOptionsTableViewController.swift
//  Rival
//
//  Created by Yannik Schroeder on 04.05.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import UIKit

class PlotOptionsTableViewController: UITableViewController {

    @IBOutlet weak var plotTitlePicker: UIPickerView!
    @IBOutlet weak var plotTypePicker: UIPickerView!
    @IBOutlet weak var ignoreZerosSwitch: UISwitch!
    
    let engine = PlotEngine.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        plotTitlePicker.delegate = self
        plotTitlePicker.dataSource = self
        plotTitlePicker.selectRow(PlotTitleState.allCases.firstIndex(where: {$0 == engine.plotTitleState})!, inComponent: 0, animated: true)
        plotTypePicker.delegate = self
        plotTypePicker.dataSource = self
        plotTypePicker.selectRow(PlotType.allCases.firstIndex(where: {$0 == engine.plotType})!, inComponent: 0, animated: true)
        ignoreZerosSwitch.isOn = engine.ignoreZeros
        ignoreZerosSwitch.addTarget(self, action: #selector(ignoreZerosSwitchTapped), for: .touchUpInside)
        ignoreZerosSwitch.onTintColor = UIColor(red: 0.1, green: 0.7, blue: 0.1, alpha: 1)
    }
    
    //MARK: - Actions
    
    @objc private func ignoreZerosSwitchTapped() {
        engine.ignoreZeros = ignoreZerosSwitch.isOn
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
            engine.plotTitleState = PlotTitleState.allCases[row]
        }
        else if pickerView == plotTypePicker {
            engine.plotType = PlotType.allCases[row]
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
