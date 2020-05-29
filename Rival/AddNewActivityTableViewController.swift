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
    
    var selectedMeasurementMethod = MeasurementMethod.allCases[0]
    var selectedAttachmentType = AttachmentType.allCases[0]
    let numberOfSettingsCells = 6
    let filesystem = Filesystem.shared
    var completionCallback: (() -> Void)!
    
    //MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.measurementTypePicker.delegate = self
        self.measurementTypePicker.dataSource = self
        self.attachmentTypePicker.delegate = self
        self.attachmentTypePicker.dataSource = self
        self.nameTextField.delegate = self
        self.unitTextField.delegate = self
        nameTextField.clearButtonMode = .whileEditing
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
            return MeasurementMethod.allCases.count
        }
        else { //attachmentTypePicker
            return AttachmentType.allCases.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == self.measurementTypePicker {
            switch(MeasurementMethod.allCases[row]) {
            case .doubleWithUnit:
                return "Kommazahl"
            case .intWithoutUnit:
                return "Anzahl"
            case .time:
                return "Zeitangabe"
            case .yesNo:
                return "Ja/Nein"
            }
        }
        else {
            switch(AttachmentType.allCases[row]) {
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
            self.selectedMeasurementMethod = MeasurementMethod.allCases[row]
            self.updateUnitTextfieldState()
            self.updateSaveButtonState()
        case self.attachmentTypePicker:
            self.selectedAttachmentType = AttachmentType.allCases[row]
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
    
    @IBAction func saveButtonTapped(_ sender: UIBarButtonItem) {
        do {
            try filesystem.createActivity(name: nameTextField.text!, measurementMethod: selectedMeasurementMethod, unit: unitTextField.text!, attachmentType: selectedAttachmentType)
            completionCallback()
            dismiss(animated: true, completion: nil)
        }
        catch {
            presentErrorAlert(presentingViewController: self, error: error)
        }
    }
    
    
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
        if segue.identifier == "ConfigureFolder" {
         let destinationViewController = segue.destination as! FolderTableViewController
            destinationViewController.folderToCreate = Folder(nameTextField.text!, parent: filesystem.current)
            destinationViewController.folderCreationCallback = completionCallback
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "ConfigureFolder" && !self.folderSwitch.isOn || self.nameTextField.text!.isEmpty {
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
            enabled = !(unit.isEmpty && self.selectedMeasurementMethod == .doubleWithUnit)
        }
        
        self.saveButton.isEnabled = enabled
    }
    
    private func updateUnitTextfieldState() {
        switch(self.selectedMeasurementMethod) {
        case .yesNo:
            fallthrough
        case .intWithoutUnit:
            self.unitTextField.text = ""
            self.unitTextField.isEnabled = false
        case .time:
            self.unitTextField.text = "s"
            self.unitTextField.isEnabled = false
        case .doubleWithUnit:
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
