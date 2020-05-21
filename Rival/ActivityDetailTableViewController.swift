//
//  ActivityDetailTableViewController.swift
//  Rival
//
//  Created by Yannik Schroeder on 15.04.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import UIKit

class ActivityDetailTableViewController: UITableViewController, UITextFieldDelegate, UITextViewDelegate {
    
    //MARK: - Properties
    
    @IBOutlet weak var activityNameTextField: UITextField!
    @IBOutlet weak var unitTextField: UITextField!
    @IBOutlet weak var commentTextView: UITextView!
    @IBOutlet weak var quantityView: QuantityView!
    @IBOutlet weak var pathNavigationItem: UINavigationItem!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var middleButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var addAttachmentButton: UIButton!
    @IBOutlet weak var moveButton: UIButton!
    
    var activity: Activity!
    var selectDateCallback: ((Date) -> ())!
    var chosenDate: Date! {
        didSet {
            if let view = self.quantityView {
                view.chosenDate = self.chosenDate
                self.setDateButtonDate()
                self.updateTimerButtonStates()
                self.commentTextView.text = self.activity[self.chosenDate].comment
                self.selectDateCallback(self.chosenDate)
            }
        }
    }
    var backButton: UIBarButtonItem!
    let filesystem = Filesystem.shared
    var timer: Timer!

    func createDateButtons() {
        self.navigationItem.hidesBackButton = true
        self.pathNavigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.left"), style: .plain, target: self, action: #selector(self.back(_:)))
        let leftArrow = UIBarButtonItem(image: UIImage(systemName: "arrow.left")!, style: .plain, target: self, action: #selector(self.previousDateButtonTapped(_:)))
        leftArrow.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.editButtonItem.isEnabled = false
        self.navigationItem.leftBarButtonItems = [self.editButtonItem, leftArrow]
        let rightArrow = UIBarButtonItem(image: UIImage(systemName: "arrow.right"), style: .plain, target: self, action: #selector(self.nextDateButtonTapped(_:)))
        rightArrow.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.navigationItem.rightBarButtonItems = [self.addButton, rightArrow]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if activity.measurementMethod == .time {
            timer = TimerStore[activity.id]
        }
        self.setActivityAndDate()
        self.commentTextView.delegate = self
        self.activityNameTextField.delegate = self
        self.unitTextField.delegate = self
        self.unitTextField.text = activity.unit
        if activity.measurementMethod != .doubleWithUnit {
            self.unitTextField.isEnabled = false
            self.unitTextField.backgroundColor = UIColor.systemGray6
        }
        self.activityNameTextField.text = self.activity.name
        self.commentTextView.text = self.activity[self.chosenDate].comment
        self.commentTextView.layer.borderWidth = 1
        self.commentTextView.layer.cornerRadius = 10
        setUpButtons()
        self.moveButton.createBorder()
        self.updateTimerButtonStates()
        self.updatePath()
        createDateButtons()
    }
    
    //MARK: - Private Methods
    
    private func setDateButtonDate() {
        self.dateButton.setTitle(self.chosenDate.dateString(), for: .normal)
        if self.chosenDate.isToday() {
            self.dateButton.titleLabel!.font = UIFont.boldSystemFont(ofSize: 18)
        }
        else {
            self.dateButton.titleLabel!.font = UIFont.systemFont(ofSize: 18)
        }
    }
    
    @objc private func back(_ sender: UIBarButtonItem) {
        if let owningNavigationController = self.navigationController {
            owningNavigationController.popViewController(animated: false)
        }
    }
    
    @objc private func previousDateButtonTapped(_ sender: UIButton) {
        self.chosenDate.addDays(days: -1)
    }
    
    @objc private func nextDateButtonTapped(_ sender: UIButton) {
        self.chosenDate.addDays(days: 1)
    }
    
    func setUpButtons() {
        leftButton.createBorder()
        middleButton.createBorder()
        rightButton.createBorder()
        if activity.measurementMethod == .time {
            leftButton.setTitle("Läuft..", for: .selected)
            leftButton.addTarget(self, action: #selector(startTimer(_:)), for: .touchUpInside)
            middleButton.addTarget(self, action: #selector(stopTimer(_:)), for: .touchUpInside)
            rightButton.addTarget(self, action: #selector(deleteTimer(_:)), for: .touchUpInside)
        }
        else if activity.measurementMethod == .intWithoutUnit {
            leftButton.setTitle("+", for: .normal)
            middleButton.setTitle("-", for: .normal)
            leftButton.addTarget(self, action: #selector(addOne), for: .touchUpInside)
            middleButton.addTarget(self, action: #selector(substractOne), for: .touchUpInside)
            rightButton.addTarget(self, action: #selector(reset), for: .touchUpInside)
        }
    }
    
    @objc func addOne() {
        activity[chosenDate].measurement += 1
        quantityView.update(for: chosenDate)
    }
    
    @objc func substractOne() {
        let measurement = activity[chosenDate].measurement
        if measurement > 0 {
            activity[chosenDate].measurement -= 1
        }
        quantityView.update(for: chosenDate)
    }
    
    @objc func reset() {
        activity[chosenDate].measurement = 0
        quantityView.update(for: chosenDate)
    }
    
    func updateTimerButtonStates() {
        if !self.chosenDate.isToday() {
            self.leftButton.isEnabled = false
            self.middleButton.isEnabled = false
            self.rightButton.isEnabled = false
        }
        else if activity.measurementMethod == .time || activity.measurementMethod == .intWithoutUnit {
            self.leftButton.isEnabled = true
            self.middleButton.isEnabled = true
            self.rightButton.isEnabled = true
            if activity.measurementMethod == .time {
                if timer.isRunning {
                    self.setStartButtonRunning()
                }
                else if timer.isPaused {
                    self.setStartButtonPaused()
                }
            }
        }
    }
    
    func setStartButtonPaused() {
        self.leftButton.isSelected = true
        self.leftButton.backgroundColor = UIColor.lightGray
    }
    
    func setStartButtonRunning() {
        self.leftButton.isSelected = true
        self.leftButton.backgroundColor = UIColor.clear
    }
    
    func setStartButtonWaiting() {
        self.leftButton.isSelected = false
        self.leftButton.backgroundColor = UIColor.clear
    }
    
    func setActivityAndDate() {
        self.quantityView.setUpView(activity: self.activity, date: self.chosenDate)
        self.setDateButtonDate()
        self.navigationItem.title = self.chosenDate.dateString()
    }
    
    //MARK: - Actions
    
    @IBAction func dateButtonTouchUpOutside(_ sender: UIButton) {
        self.chosenDate = Date()
    }
    
    @IBAction func addAttachmentButtonTapped(_ sender: UIButton) {
        
    }
    
    @objc func startTimer(_ sender: UIButton) {
        if !timer.isRunning {
            timer.start()
            self.setStartButtonRunning()
        }
        else {
            timer.pause()
            self.setStartButtonPaused()
        }
    }
    
    @objc func stopTimer(_ sender: UIButton) {
        if let seconds = timer.stop() {
            self.setStartButtonWaiting()
            self.quantityView.setTimePickerSeconds(seconds, animated: true)
        }
    }
    
    @objc func deleteTimer(_ sender: UIButton) {
        timer.clear()
        self.setStartButtonWaiting()
        self.quantityView.setTimePickerSeconds(0, animated: true)
        self.activity[self.chosenDate].measurement = 0
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //super.prepare(for: segue, sender: sender)
        let navigationController = segue.destination as! UINavigationController
        switch(segue.identifier ?? "") {
        case "SelectDate":
            let destinationViewController = navigationController.topViewController as! CalendarViewController
            destinationViewController.singleSelectionCallback = {(date: Date) in self.chosenDate = date}
            destinationViewController.firstDate = self.chosenDate
        case "MoveActivity":
            let destinationViewController = navigationController.topViewController as! FolderTableViewController
            destinationViewController.mode = .moveActivity
            destinationViewController.activityToMove = activity
            destinationViewController.moveCallback = {
                self.updatePath()
            }
        default:
            fatalError()
        }
    }
    
    //MARK: - UITextViewDelegate
    
    func textViewDidChange(_ textView: UITextView) {
        self.activity[self.chosenDate].comment = textView.text
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return self.chosenDate.isToday()
    }
    
    //MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == self.activityNameTextField {
            do {
                try filesystem.renameActivity(activity, name: textField.text!)
                updatePath()
            }
            catch {
                presentErrorAlert(presentingViewController: self, error: error)
                textField.text = activity.name
            }
        }
        else if textField == self.unitTextField {
            self.activity!.unit = textField.text!
            self.quantityView.update(for: self.chosenDate)
        }
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    
    //MARK: - Private Methods
    
    private func updatePath() {
        self.pathNavigationItem.title = filesystem.current.url.appendingPathComponent(activity.name).path
    }
}

extension UIButton {
    public func createBorder() {
        self.backgroundColor = .clear
        self.layer.cornerRadius = 5
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.systemBlue.cgColor
    }
}
