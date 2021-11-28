//
//  ActivityDetailTableViewController.swift
//  Rival
//
//  Created by Yannik Schroeder on 15.04.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import UIKit
//AVPlayer
import AVFoundation
//kuTTypeMovie
import MobileCoreServices
//AVPlayerViewController
import AVKit
import os.log

class ActivityDetailTableViewController: UITableViewController, UITextFieldDelegate, UITextViewDelegate, DoneButton {
    
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
    @IBOutlet weak var moveButton: UIButton!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var attachmentLabel: UILabel!
    
    var activity: Activity!
    var selectDateCallback: ((Date) -> ())!
    var chosenDate: Date! {
        didSet {
            if let view = self.quantityView {
                view.chosenDate = self.chosenDate
                self.setDateButtonDate()
                self.updateButtonStates()
                self.commentTextView.text = activity.comments[chosenDate.dateString()]
                self.selectDateCallback(self.chosenDate)
            }
            mediaStore.date = chosenDate
        }
    }
    var backButton: UIBarButtonItem!
    let filesystem = Filesystem.shared
    var stopWatch: StopWatch!
    var timer: Timer! = nil
    var mediaStore = MediaHandler.shared
    var lastAddAmount: Double = 0.0
    var lastSubstractAmount: Double = 0.0
    
    //MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if activity.measurementMethod == .time {
            stopWatch = StopWatchStore[activity.id]
            stopWatch.fireAction = {
                guard Calendar.iso.isDate(Date(), equalTo: self.chosenDate, toGranularity: .day) else {
                    return
                }
                self.stopWatch.update()
                self.activity[self.chosenDate] = self.stopWatch.elapsedTime
                self.quantityView.setTimePickerSeconds(Int(self.stopWatch.elapsedTime), animated: true)
            }
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
        self.commentTextView.text = self.activity.comments[chosenDate.dateString()]
        self.commentTextView.layer.borderWidth = 1
        self.commentTextView.layer.cornerRadius = 10
        addDoneButton(parentView: self, to: commentTextView)
        setUpButtons()
        self.updateButtonStates()
        self.updatePath()
        createDateButtons()
        mediaStore.delegate = self
        mediaStore.activity = activity
        mediaStore.date = chosenDate
        createButton.createBorder()
        playButton.createBorder()
        switch(activity.attachmentType) {
        case .audio:
            mediaStore.assignAudioButtons(recordButton: createButton, playButton: playButton)
            attachmentLabel.text = "Audio"
        case .photo:
            mediaStore.assignPhotoButtons(recordButton: createButton, seeButton: playButton)
            attachmentLabel.text = "Foto"
        case .video:
            mediaStore.assignVideoButtons(recordButton: createButton, watchButton: playButton)
            attachmentLabel.text = "Video"
        case .none:
            attachmentLabel.text = "Anlage"
            attachmentLabel.tintColor = UIColor.systemGray3
            createButton.isHidden = true
            playButton.isHidden = true
        }
        activityNameTextField.clearButtonMode = .whileEditing
        unitTextField.clearButtonMode = .whileEditing
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(previousDateButtonTapped(_:)))
        swipeRight.direction = .right
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(nextDateButtonTapped(_:)))
        swipeLeft.direction = .left
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(dateButtonTouchUpOutside(_:)))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeRight)
        view.addGestureRecognizer(swipeLeft)
        view.addGestureRecognizer(swipeDown)
    }
    
    //MARK: - Private Methods
    
    private func updatePath() {
        self.pathNavigationItem.title = filesystem.current.url.appendingPathComponent(activity.name, isDirectory: false).path
    }
    
    private func createDateButtons() {
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
    
    private func setDateButtonDate() {
        self.dateButton.setTitle(self.chosenDate.dateString(with: DateFormats.shortYear), for: .normal)
        if self.chosenDate.isToday() {
            self.dateButton.titleLabel!.font = UIFont.boldSystemFont(ofSize: 14)
        }
        else {
            self.dateButton.titleLabel!.font = UIFont.systemFont(ofSize: 14)
        }
    }
    
    private func setUpButtons() {
        leftButton.createBorder()
        middleButton.createBorder()
        rightButton.createBorder()
        moveButton.createBorder()
        if activity.measurementMethod == .time {
            leftButton.setTitle("Läuft..", for: .selected)
            leftButton.addTarget(self, action: #selector(startTimer), for: .touchUpInside)
            middleButton.addTarget(self, action: #selector(stopTimer), for: .touchUpInside)
            rightButton.addTarget(self, action: #selector(deleteTimer), for: .touchUpInside)
        }
        else if activity.measurementMethod == .intWithoutUnit {
            leftButton.setTitle("+", for: .normal)
            middleButton.setTitle("-", for: .normal)
            leftButton.addTarget(self, action: #selector(addOne), for: .touchUpInside)
            middleButton.addTarget(self, action: #selector(substractOne), for: .touchUpInside)
        }
        else if activity.measurementMethod == .doubleWithUnit {
            leftButton.setTitle("+", for: .normal)
            middleButton.setTitle("-", for: .normal)
            leftButton.addTarget(self, action: #selector(addAmount), for: .touchUpInside)
            middleButton.addTarget(self, action: #selector(substractAmount), for: .touchUpInside)
        }
        if activity.measurementMethod != .time {
            rightButton.addTarget(self, action: #selector(reset), for: .touchUpInside)
        }
    }
    
    private func addOrSubstract(substract: Bool) {
        let info: (title: String, msg: String)
        if substract {
            info = ("Subtrahiere", "subtrahierenden")
        }
        else {
            info = ("Addiere", "addierenden")
        }
        let alert = UIAlertController(title: info.title, message: "Gebe den zu \(info.msg) Wert ein:", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.keyboardType = .decimalPad
            textField.clearButtonMode = .whileEditing
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler:  { (action) in
            let textField = alert.textFields?.first!
            if let amount = Double(textField!.text!.replacingOccurrences(of: ",", with: ".")) {
                if substract {
                    self.activity[self.chosenDate] -= amount
                    self.lastSubstractAmount = amount
                }
                else {
                    self.activity[self.chosenDate] += amount
                    self.lastAddAmount = amount
                }
                self.quantityView.update(for: self.chosenDate)
            }
        }))
        present(alert, animated: true, completion: nil)
    }
    
    @objc func addAmount() {
        addOrSubstract(substract: false)
    }
    
    @objc func substractAmount() {
        addOrSubstract(substract: true)
    }
    
    func updateButtonStates() {
        if activity.measurementMethod != .yesNo {
            self.leftButton.isEnabled = true
            self.middleButton.isEnabled = true
            if activity.measurementMethod == .time {
                if stopWatch.isRunning {
                    self.setStartButtonRunning()
                }
                else if stopWatch.isPaused {
                    self.setStartButtonPaused()
                }
            }
        }
        else {
            leftButton.isEnabled = false
            middleButton.isEnabled = false
        }
        if activity.attachmentType != .none {
            if filesystem.manager.fileExists(atPath: MediaHandler.shared.getMediaArchiveURL(for: activity, at: chosenDate).path) {
                playButton.enable()
            }
            else {
                playButton.disable()
            }
            if !chosenDate.isToday() {
                createButton.disable()
            }
            else {
                createButton.enable()
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
    
    //MARK: - AVAudioRecorderDelegate
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        mediaStore.audioRecorderDidFinishRecording(recorder, successfully: flag)
    }
    
    //MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        mediaStore.audioPlayerDidFinishPlaying(player, successfully: flag)
    }
    
    //MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        mediaStore.imagePickerController(picker, didFinishPickingMediaWithInfo: info)
    }
    
    //MARK: - Actions
    
    @IBAction func dateButtonTouchUpOutside(_ sender: UIButton) {
        self.chosenDate = Date()
    }
    
    @objc func addOne() {
        activity[chosenDate] += 1
        quantityView.update(for: chosenDate)
    }
    
    @objc func substractOne() {
        let measurement = activity[chosenDate]
        if measurement > 0 {
            activity[chosenDate] -= 1
        }
        quantityView.update(for: chosenDate)
    }
    
    @objc func reset() {
        activity[chosenDate] = 0
        quantityView.update(for: chosenDate)
    }
    
    @objc private func back(_ sender: UIBarButtonItem) {
        if let owningNavigationController = self.navigationController {
            if let recorder = mediaStore.audioRecorder {
                if recorder.isRecording {
                    presentErrorAlert(presentingViewController: self, title: "Aufnahme läuft noch", message: "Bitte beende zuerst die Aufnahme bevor du wieder irgendwohin verschwindest.")
                    return
                }
            }
            owningNavigationController.popViewController(animated: false)
        }
    }
    
    @objc private func previousDateButtonTapped(_ sender: UIButton) {
        self.chosenDate.addDays(days: -1)
    }
    
    @objc private func nextDateButtonTapped(_ sender: UIButton) {
        self.chosenDate.addDays(days: 1)
    }
    
    @objc func startTimer() {
        if !stopWatch.isRunning {
            stopWatch.start()
            setStartButtonRunning()
        }
    }
    
    @objc func stopTimer() {
        stopWatch.stop()
        setStartButtonWaiting()
    }
    
    @objc func deleteTimer() {
        stopWatch.clear()
        setStartButtonWaiting()
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //super.prepare(for: segue, sender: sender)
        let navigationController = segue.destination as? UINavigationController
        switch(segue.identifier ?? "") {
        case "DateSelection":
            let destinationViewController = navigationController!.topViewController as! CalendarViewController
            destinationViewController.singleSelectionCallback = {(date: Date) in self.chosenDate = date}
            destinationViewController.firstDate = self.chosenDate
            destinationViewController.activity = activity
        case "MoveActivity":
            let destinationViewController = navigationController!.topViewController as! FolderTableViewController
            destinationViewController.mode = .moveActivity
            destinationViewController.activityToMove = activity
            destinationViewController.moveCallback = {
                self.updatePath()
            }
        case "PresentImage":
            break
        default:
            break
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "PresentImage" && activity.attachmentType != .photo {
            return false
        }
        return true
    }
    
    //MARK: - UITextViewDelegate
    
    func textViewDidChange(_ textView: UITextView) {
        self.activity.comments[chosenDate.dateString()] = textView.text
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
    
    //MARK: - DoneButton
    
    @objc func doneCallback() {
        commentTextView.resignFirstResponder()
    }
}

extension ActivityDetailTableViewController: MediaDelegate {
    func presentError(_ error: Error) {
        presentErrorAlert(presentingViewController: self, error: error)
    }
}
