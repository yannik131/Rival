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
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var pathNavigationItem: UINavigationItem!
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
                self.handleViewStates()
                self.commentTextView.text = self.activity[self.chosenDate].comment
                self.selectDateCallback(self.chosenDate)
            }
        }
    }
    var backButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setActivityAndDate()
        self.commentTextView.delegate = self
        self.activityNameTextField.delegate = self
        self.unitTextField.delegate = self
        if let unit = self.activity.unit {
            self.unitTextField.text = unit
        }
        else {
            self.unitTextField.isEnabled = false
            if self.activity.measurementMethod == .Time {
                self.unitTextField.text = "s"
            }
            self.unitTextField.backgroundColor = UIColor.systemGray6
        }
        self.activityNameTextField.text = self.activity.name
        self.commentTextView.text = self.activity[self.chosenDate].comment
        self.commentTextView.layer.borderWidth = 1
        self.commentTextView.layer.cornerRadius = 10
        
        self.moveButton.createBorder()
        self.startButton.createBorder()
        self.stopButton.createBorder()
        self.deleteButton.createBorder()
        self.startButton.setTitle("Läuft..", for: [.selected, .highlighted])
        
        self.handleViewStates()
        self.updatePath()
        self.navigationItem.hidesBackButton = true
        self.pathNavigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.left"), style: .plain, target: self, action: #selector(self.back(_:)))
        let leftArrow = UIBarButtonItem(image: UIImage(systemName: "arrow.left")!, style: .plain, target: self, action: #selector(self.previousDateButtonTapped(_:)))
        leftArrow.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.editButtonItem.isEnabled = false
        self.navigationItem.leftBarButtonItems = [self.editButtonItem, leftArrow]
        let rightArrow = UIBarButtonItem(image: UIImage(systemName: "arrow.right"), style: .plain, target: self, action: #selector(self.nextDateButtonTapped(_:)))
        rightArrow.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.navigationItem.rightBarButtonItems = [self.addButton, rightArrow]
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
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
    
    func handleViewStates() {
        if self.activity.measurementMethod != .Time || !self.chosenDate.isToday() {
            self.startButton.isEnabled = false
            self.stopButton.isEnabled = false
            self.deleteButton.isEnabled = false
        }
        else {
            self.startButton.isEnabled = true
            self.stopButton.isEnabled = true
            self.deleteButton.isEnabled = true
            if Timer.getInstance().isRunning {
                self.setStartButtonRunning()
            }
            else if Timer.getInstance().isPaused {
                self.setStartButtonPaused()
            }
        }
    }
    
    func setStartButtonPaused() {
        self.startButton.isSelected = true
        self.startButton.backgroundColor = UIColor.lightGray
    }
    
    func setStartButtonRunning() {
        self.startButton.isSelected = true
        self.startButton.backgroundColor = UIColor.clear
    }
    
    func setStartButtonWaiting() {
        self.startButton.isSelected = false
        self.startButton.backgroundColor = UIColor.clear
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
    
    @IBAction func startButtonTapped(_ sender: UIButton) {
        if !Timer.getInstance().isRunning {
            Timer.getInstance().start()
            self.setStartButtonRunning()
        }
        else {
            Timer.getInstance().pause()
            self.setStartButtonPaused()
        }
    }
    
    @IBAction func stopButtonTapped(_ sender: UIButton) {
        if let seconds = Timer.getInstance().stop() {
            self.setStartButtonWaiting()
            self.quantityView.setTimePickerSeconds(seconds, animated: true)
        }
    }
    
    @IBAction func deleteButtonTapped(_ sender: UIButton) {
        Timer.getInstance().clear()
        self.setStartButtonWaiting()
        self.quantityView.setTimePickerSeconds(0, animated: true)
        self.activity[self.chosenDate].measurement = 0
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
        case "calendarPopup2":
            let navigationController = segue.destination as? UINavigationController
            let destinationViewController = navigationController!.topViewController as! CalendarViewController
            destinationViewController.selectDateCallback = {(date: Date) in self.chosenDate = date}
            destinationViewController.firstDate = self.chosenDate
        case "moveActivity":
            let navigationController = segue.destination as! UINavigationController
            let destinationViewController = navigationController.topViewController as! FolderTableViewController
            destinationViewController.mode = .moveActivity
            destinationViewController.moveCallback = {(folder: Filesystem.Folder) in
                Filesystem.getInstance().addActivityToFolder(activity: self.activity, folder: folder)
                Filesystem.getInstance().openFolder(pathComponents: folder.pathComponents)
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
        if textField.text!.isEmpty {
            return false
        }
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if textField == self.activityNameTextField {
            self.activity!.name = textField.text!
            self.updatePath()
        }
        else if textField == self.unitTextField {
            self.activity!.unit = textField.text!
            self.quantityView.update(for: self.chosenDate)
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 6
    }
    
    //MARK: - Private Methods
    
    private func updatePath() {
        self.pathNavigationItem.title = Filesystem.getInstance().currentPath + self.activity.name
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
