//
//  QuantityStackView.swift
//  Rival
//
//  Created by Yannik Schroeder on 15.04.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import UIKit
import os.log

class QuantityView: UIView, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, DoneButton {

    //MARK: - Properties
    
    var picker: UIPickerView?
    var yesNoSwitch: UISwitch?
    var doubleTextField: UITextField?
    var activity: Activity!
    var chosenDate: Date! {
        didSet {
            self.update(for: self.chosenDate)
        }
    }
    
    //UIPickerViewDataSource
    var timeRange = [[String](), [String](), [String]()]
    
    //MARK: - Initializers
    
    required init(coder: NSCoder) {
        super.init(coder: coder)!
    }
    
    //MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        self.setPracticeAmount()
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.text = nil
    }
    
    //MARK: - UIPickerViewDelegate
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        if self.activity.measurementMethod == .intWithoutUnit {
            return 1
        }
        return 3
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.timeRange[component].count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.timeRange[component][row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.setPracticeAmount()
    }
    
    
    //MARK: - Public Methods
    
    private func createYesNoSwitch() {
        let yesNoSwitch = UISwitch()
        yesNoSwitch.offImage = UIImage(systemName: "xmark.circle")
        yesNoSwitch.onImage = UIImage(systemName: "checkmark.circle")
        yesNoSwitch.addTarget(self, action: #selector(setPracticeAmount), for: .allTouchEvents)
        yesNoSwitch.onTintColor = UIColor(red: 0.1, green: 0.7, blue: 0.1, alpha: 1)
        self.addUIView(view: yesNoSwitch)
        self.yesNoSwitch = yesNoSwitch
    }
    
    private func createDoubleTextField() {
        let doubleTextField = UITextField()
        doubleTextField.translatesAutoresizingMaskIntoConstraints = false
        doubleTextField.heightAnchor.constraint(equalToConstant: 30).isActive = true
        doubleTextField.widthAnchor.constraint(equalToConstant: 100).isActive = true
        doubleTextField.delegate = self
        doubleTextField.borderStyle = .roundedRect
        if self.activity.measurementMethod == .intWithoutUnit {
            doubleTextField.keyboardType = .numberPad
        }
        else {
            doubleTextField.keyboardType = .decimalPad
        }
        doubleTextField.clearButtonMode = .whileEditing
        self.addUIView(view: doubleTextField)
        self.doubleTextField = doubleTextField
        addDoneButton(parentView: self, to: doubleTextField)
    }
    
    private func createPicker() {
        for i in 0...23 {
            self.timeRange[0].append("\(i)h")
        }
        for i in 0...59 {
            self.timeRange[1].append("\(i)m")
            self.timeRange[2].append("\(i)s")
        }
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        self.picker = picker
        self.addUIView(view: picker)
    }
    
    func setUpView(activity: Activity, date: Date) {
        self.activity = activity
        self.chosenDate = date
        
        switch(self.activity.measurementMethod) {
        case .yesNo:
            self.createYesNoSwitch()
        case .intWithoutUnit:
            fallthrough
        case .doubleWithUnit:
            self.createDoubleTextField()
        case .time:
            self.createPicker()
        }
        self.update(for: self.chosenDate)
    }
    
    public func update(for date: Date) {
        var view: UIView?
        if let yesNoSwitch = self.yesNoSwitch {
            yesNoSwitch.isOn = self.activity[date] != 0.0
            view = yesNoSwitch as UIView
        }
        else if let textField = self.doubleTextField {
            textField.text = self.activity.measurementToString(date: date)
            view = textField as UIView
        }
        else if let picker = self.picker {
            self.setTimePickerSeconds(Int(self.activity[date]))
            view = picker as UIView
        }
        if let view = view {
            view.isUserInteractionEnabled = true
            if self.chosenDate.isToday() {
                view.backgroundColor = UIColor.clear
            }
            else {
                view.backgroundColor = UIColor.systemGray6
                view.layer.cornerRadius = 13
            }
        }
    }
    
    @objc func doneCallback() {
        self.endEditing(true)
        self.setPracticeAmount()
        self.doubleTextField!.text = self.activity.measurementToString(date: self.chosenDate)
    }
    
    func setTimePickerSeconds(_ seconds: Int, animated: Bool = false) {
        guard let picker = self.picker else {
            fatalError()
        }
        let (hours, minutes, seconds): (Int, Int, Int) = (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
        picker.selectRow(hours, inComponent: 0, animated: animated)
        picker.selectRow(minutes, inComponent: 1, animated: animated)
        picker.selectRow(seconds, inComponent: 2, animated: animated)
    }
    
    private func addUIView(view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(view)
        
        if let view = view as? UISwitch {
            let constraints = [
                view.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                view.centerYAnchor.constraint(equalTo: self.centerYAnchor)
            ]
            NSLayoutConstraint.activate(constraints)
        }
        if let view = view as? UITextField {
            let constraints = [
                view.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                view.centerYAnchor.constraint(equalTo: self.centerYAnchor)
            ]
            NSLayoutConstraint.activate(constraints)

        }
        if let view = view as? UIPickerView {
            let leftConstraint = NSLayoutConstraint(
                //-- the object that we want to constrain
                    item: view,
                //-- the attribute of the object we want to constrain
                    attribute: NSLayoutConstraint.Attribute.left,
                //-- how we want to relate THIS object to A DIFF object
                    relatedBy: NSLayoutConstraint.Relation.equal,
                //-- this is the different object we want to constrain to
                    toItem: self,
                //-- the attribute of the different object
                    attribute: NSLayoutConstraint.Attribute.left,
                    multiplier: 1,
                    constant: 0
                )
            let rightConstraint = NSLayoutConstraint(item: view,
                    attribute: NSLayoutConstraint.Attribute.right,
                    relatedBy: NSLayoutConstraint.Relation.equal,
                    toItem: self,
                    attribute: NSLayoutConstraint.Attribute.right,
                    multiplier: 1,
                    constant: 0
                )
            let topConstraint = NSLayoutConstraint(
                    item: view,
                    attribute: NSLayoutConstraint.Attribute.top,
                    relatedBy: NSLayoutConstraint.Relation.equal,
                    toItem: self,
                    attribute: NSLayoutConstraint.Attribute.top,
                    multiplier: 1,
                    constant: 0
                )
            let bottomConstraint = NSLayoutConstraint(
                    item: view,
                    attribute: NSLayoutConstraint.Attribute.bottom,
                    relatedBy: NSLayoutConstraint.Relation.equal,
                    toItem: self,
                    attribute: NSLayoutConstraint.Attribute.bottom,
                    multiplier: 1,
                    constant: 0
                )
            let constraints = [leftConstraint, rightConstraint, topConstraint, bottomConstraint]
            NSLayoutConstraint.activate(constraints)
        }
    }
    
    //MARK: - Private Methods
    
    @objc private func setPracticeAmount() {
        let measurementMethod = self.activity.measurementMethod
        
        var amount: Double = 0
        
        switch(measurementMethod) {
        case .yesNo:
            if self.yesNoSwitch!.isOn {
                amount = 1
            }
        case .time:
            guard let picker = self.picker else {
                return
            }
            let hours = picker.selectedRow(inComponent: 0)
            let minutes = picker.selectedRow(inComponent: 1)
            let seconds = picker.selectedRow(inComponent: 2)
            amount = Double(hours * 3600 + minutes * 60 + seconds)
        case .intWithoutUnit:
            fallthrough
        case .doubleWithUnit:
            if let userInput = self.doubleTextField!.text {
                if let input = Double(userInput.replacingOccurrences(of: ",", with: ".")) {
                    amount = input
                }
            }
        }
        
        self.activity[self.chosenDate] = amount
    }
}
