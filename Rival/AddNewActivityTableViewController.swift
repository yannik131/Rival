//
//  AddNewActivityTableViewController.swift
//  Rival
//
//  Created by Yannik Schroeder on 14.04.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import UIKit
import os.log

class AddNewActivityTableViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    //MARK: - Properties
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var measurementTypePicker: UIPickerView!
    @IBOutlet weak var attachmentTypePicker: UIPickerView!
    @IBOutlet weak var unitTextField: UITextField!
    @IBOutlet weak var folderSwitch: UISwitch!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var navigationBar: UINavigationItem!
    
    var activity: Activity?
    var selectedMeasurementMethod = Activity.MeasurementMethod.allCases[0]
    var selectedAttachmentType = Activity.AttachmentType.allCases[0]
    let numberOfSettingsCells = 6
    
    //MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.measurementTypePicker.delegate = self
        self.measurementTypePicker.dataSource = self
        self.attachmentTypePicker.delegate = self
        self.attachmentTypePicker.dataSource = self
        self.nameTextField.delegate = self
        self.unitTextField.delegate = self
        self.folderSwitch.isOn = false
        self.folderSwitch.onTintColor = UIColor(red: 0.1, green: 0.7, blue: 0.1, alpha: 1)
        self.folderSwitch.addTarget(self, action: #selector(self.folderSwitchTapped), for: .allTouchEvents)
        self.updateSaveButtonState()
        self.updateUnitTextfieldState()
    }
    
    //MARK: - UIPickerViewDelegate
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == self.measurementTypePicker {
            return Activity.MeasurementMethod.allCases.count
        }
        else { //attachmentTypePicker
            return Activity.AttachmentType.allCases.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == self.measurementTypePicker {
            switch(Activity.MeasurementMethod.allCases[row]) {
            case .DoubleWithUnit:
                return "Kommazahl"
            case .IntWithoutUnit:
                return "Anzahl"
            case .Time:
                return "Zeitangabe"
            case .YesNo:
                return "Ja/Nein"
            }
        }
        else {
            switch(Activity.AttachmentType.allCases[row]) {
            case .none:
                return "Nichts"
            case .audio:
                return "Audio"
            case .photo:
                return "Foto"
            case .video:
                return "Video"
            }
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch(pickerView) {
        case self.measurementTypePicker:
            self.selectedMeasurementMethod = Activity.MeasurementMethod.allCases[row]
            self.updateUnitTextfieldState()
            self.updateSaveButtonState()
        case self.attachmentTypePicker:
            self.selectedAttachmentType = Activity.AttachmentType.allCases[row]
        default:
            os_log("Unknown picker selected: %s", pickerView)
            return
        }
        
    }
    
    //MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.updateSaveButtonState()
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        self.updateSaveButtonState()
    }
    
    //MARK: - Actions
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func folderSwitchTapped() {
        let isFolder = self.folderSwitch.isOn
        self.unitTextField.isEnabled = !isFolder
        self.attachmentTypePicker.isUserInteractionEnabled = !isFolder
        self.measurementTypePicker.isUserInteractionEnabled = !isFolder
        self.updateSaveButtonState()
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let tappedButton = sender as? UIBarButtonItem, tappedButton == self.saveButton  {
            self.activity = Activity(name: self.nameTextField.text!, measurementMethod: self.selectedMeasurementMethod, unit: self.unitTextField.text, attachmentType: self.selectedAttachmentType)
        }
        else if let destinationViewController = segue.destination as? FolderTableViewController {
            destinationViewController.folder = Filesystem.Folder(name: self.nameTextField.text!)
            destinationViewController.folder!.pathComponents = Filesystem.getInstance().currentFolder.pathComponents + [nameTextField.text!]
        }
        else {
            fatalError()
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "configureFolder" && !self.folderSwitch.isOn || self.nameTextField.text!.isEmpty {
            return false
        }
        return true
    }
    
    //MARK: - Private Methods
    
    private func updateSaveButtonState() {
        let name = self.nameTextField.text ?? ""
        if !name.isEmpty {
            self.navigationBar.title = name
        }
        else if self.folderSwitch.isOn {
            self.navigationBar.title = "Ordner erstellen"
        }
        else {
            self.navigationBar.title = "Aktivität erstellen"
        }
        
        var enabled = !self.folderSwitch.isOn && !name.isEmpty
        
        if enabled {
            let unit = self.unitTextField.text ?? ""
            enabled = !(unit.isEmpty && self.selectedMeasurementMethod == .DoubleWithUnit)
        }
        
        self.saveButton.isEnabled = enabled
    }
    
    private func updateUnitTextfieldState() {
        switch(self.selectedMeasurementMethod) {
        case .YesNo:
            fallthrough
        case .IntWithoutUnit:
            self.unitTextField.text = ""
            self.unitTextField.isEnabled = false
        case .Time:
            self.unitTextField.text = "s"
            self.unitTextField.isEnabled = false
        case .DoubleWithUnit:
            self.unitTextField.text = ""
            self.unitTextField.isEnabled = true
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.numberOfSettingsCells
    }

}
