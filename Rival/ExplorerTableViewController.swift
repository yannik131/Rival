//
//  ExplorerTableViewController.swift
//  Rival
//
//  Created by Yannik Schroeder on 14.04.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import UIKit
import Foundation
import os.log

class ExplorerTableViewController: UITableViewController {
    
    //MARK: - Properties
    
    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var pathNavigationbar: UINavigationItem!
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    var selectedCellRow: Int?
    
    let filesystem = Filesystem.getInstance()
    let minimumCellNumber = 6
    
    var chosenDate = Date() {
        didSet {
            self.setDateButtonDate()
            self.refreshAllRows()
        }
    }
    
    //MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        let formatter = Activity.fullFormatter
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.setLocalizedDateFormatFromTemplate("ddMMyyyy")
        self.setDateButtonDate()
        self.loadSampleData()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        let leftArrow = UIBarButtonItem(image: UIImage(systemName: "arrow.left")!, style: .plain, target: self, action: #selector(self.previousDateButtonTapped(_:)))
        leftArrow.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.navigationItem.leftBarButtonItems = [self.editButtonItem, leftArrow]
        let rightArrow = UIBarButtonItem(image: UIImage(systemName: "arrow.right"), style: .plain, target: self, action: #selector(self.nextDateButtonTapped(_:)))
        rightArrow.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.navigationItem.rightBarButtonItems = [self.addButton, rightArrow]
        let back = UIBarButtonItem(image: UIImage(systemName: "arrow.left")!, style: .plain, target: self, action: #selector(self.closeCurrentFolder))
        self.pathNavigationbar.leftBarButtonItem = back
        self.navigationController!.view.backgroundColor = UIColor.white
        //self.dateButton.tintColor = UIColor.black
    }
    
    //MARK: - Actions
    
    @IBAction func dateButtonTouchUpOutside(_ sender: UIButton) {
        self.chosenDate = Date()
        self.refreshAllRows()
    }
    
    @objc func previousDateButtonTapped(_ sender: UIButton) {
        self.chosenDate.addDays(days: -1)
    }
    
    @objc func nextDateButtonTapped(_ sender: UIButton) {
        self.chosenDate.addDays(days: 1)
    }
    
    @IBAction func unwindToActivitiesList(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? AddNewActivityTableViewController {
            if let activity = sourceViewController.activity {
                self.addActivity(activity: activity)
            }
        }
        else if let sourceViewController = sender.source as? FolderTableViewController {
            print("Unwinding to explorer with folder \(sourceViewController.folder!.name)")
            print("Content: \(sourceViewController.folder!.list())")
            self.addFolder(folder: sourceViewController.folder!)
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let total = self.filesystem.currentFolder.count
        if total > self.minimumCellNumber {
            return total
        }
        return self.minimumCellNumber
    }
    
    private func getSelectedActivityIndex(for indexPath: IndexPath) -> Int? {
        let folderCount = self.filesystem.currentFolder.folders.count
        if folderCount == 0 || indexPath.row+1 > folderCount {
            let activityIndex = indexPath.row - folderCount
            guard activityIndex >= 0 && activityIndex < self.filesystem.currentFolder.activities.count else {
                return nil
            }
            return activityIndex
        }
        return nil
    }
    
    private func getSelectedFolderIndex(for indexPath: IndexPath) -> Int? {
        if indexPath.row < self.filesystem.currentFolder.folders.count {
            return indexPath.row
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let activityIndex = self.getSelectedActivityIndex(for: indexPath) {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "activityCell", for: indexPath) as? ActivityTableViewCell else {
                fatalError()
            }
            let selectedActivity = self.filesystem.currentFolder.activities[activityIndex]
            cell.activityNameLabel.text = selectedActivity.name
            cell.practiceAmountLabel.text = selectedActivity.getPracticeAmountString(date: self.chosenDate)
            cell.activity = selectedActivity
            switch(cell.activity.measurementMethod) {
            case .Time:
                cell.activityImageView.image = UIImage(systemName: "clock")
            case .YesNo:
                cell.activityImageView.image = UIImage(systemName: "checkmark.circle")
            case .IntWithoutUnit:
                cell.activityImageView.image = UIImage(systemName: "number.circle")
            case .DoubleWithUnit:
                cell.activityImageView.image = UIImage(systemName: "u.circle")
            }
            return cell
        }
        else if let folderIndex = self.getSelectedFolderIndex(for: indexPath) {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "folderCell", for: indexPath) as? FolderTableViewCell else {
                fatalError()
            }
            let selectedFolder = self.filesystem.currentFolder.folders[folderIndex]
            cell.folderName.text = selectedFolder.name
            cell.folderImageView.image = UIImage(systemName: "folder")
            return cell
        }
        else if let cell = tableView.dequeueReusableCell(withIdentifier: "folderCell", for: indexPath) as? FolderTableViewCell {
            cell.folderName.text! = ""
            cell.folderImageView.image = nil
            return cell
        }
        else {
            fatalError("Unknown cell")
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let folderIndex = self.getSelectedFolderIndex(for: indexPath) {
            self.adjustRowNumbersAfterAction {
                self.filesystem.openFolderInCurrentFolder(folder: self.filesystem.currentFolder.folders[folderIndex])
            }
        }
    }
    
    @objc private func closeCurrentFolder() {
        self.adjustRowNumbersAfterAction {
            self.filesystem.closeCurrentFolder()
        }
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if tableView.isEditing {
            if indexPath.row < self.filesystem.currentFolder.count {
                return .delete
            }
        }
        return .none
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let activityIndex = self.getSelectedActivityIndex(for: indexPath) {
                self.adjustRowNumbersAfterAction {
                    self.filesystem.currentFolder.activities.remove(at: activityIndex)
                }
            }
            if let folderIndex = self.getSelectedFolderIndex(for: indexPath) {
                self.adjustRowNumbersAfterAction {
                    self.filesystem.removeFolderInCurrentFolder(at: folderIndex)
                }
            }
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
        case "addActivity":
            break
        case "showDetail":
            guard let destinationViewController = segue.destination as? ActivityDetailTableViewController else {
                fatalError("showDetail: Wrong connection.")
            }
            
            guard let selectedCell = sender as? ActivityTableViewCell else {
                fatalError("showDetail: No cell was tapped.")
            }
            
            guard let indexPath = tableView.indexPath(for: selectedCell) else {
                fatalError("Unknown cell selected.")
            }
            
            destinationViewController.activity = self.filesystem.currentFolder.activities[self.getSelectedActivityIndex(for: indexPath)!]
            destinationViewController.chosenDate = self.chosenDate
            destinationViewController.selectDateCallback = {(date: Date) in self.chosenDate = date}
            self.selectedCellRow = indexPath.row
        case "calendarPopup":
            let navigationController = segue.destination as? UINavigationController
            let destinationViewController = navigationController!.topViewController as! CalendarViewController
            destinationViewController.selectDateCallback = {(date: Date) in self.chosenDate = date}
            destinationViewController.firstDate = self.chosenDate
        default:
            fatalError("Unknown segue triggered.")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.refreshAllRows()
        self.updatePath()
    }
    
    //MARK: - Private Methods
    
    private func updatePath() {
        self.pathNavigationbar.title = self.filesystem.currentPath
    }
    
    private func adjustRowNumbersAfterAction(action: () -> ()) {
        let previousRowCount = self.filesystem.currentFolder.count
        action()
        self.updatePath()
        let currentRowCount = self.filesystem.currentFolder.count
        if previousRowCount < self.minimumCellNumber || currentRowCount < self.minimumCellNumber {
            self.refreshAllRows()
            return
        }
        var diff = currentRowCount - previousRowCount
        if diff < 0 {
            //delete abs(diff) rows
            diff *= -1
            for i in 0..<diff {
                self.tableView.deleteRows(at: [IndexPath(row: previousRowCount-1-i, section: 0)], with: .none)
            }
        }
        else {
            //insert diff rows
            for i in 0..<diff {
                self.tableView.insertRows(at: [IndexPath(row: previousRowCount-1+i, section: 0)], with: .none)
            }
        }
        self.refreshAllRows()
    }

    private func setDateButtonDate() {
        self.dateButton.setTitle(self.chosenDate.dateString(), for: .normal)
        if self.chosenDate.isToday() {
            self.dateButton.titleLabel!.font = UIFont.boldSystemFont(ofSize: 18)
        }
        else {
            self.dateButton.titleLabel!.font = UIFont.systemFont(ofSize: 18)
        }
    }
    
    private func addActivity(activity: Activity) {
        self.adjustRowNumbersAfterAction {
            self.filesystem.addActivityToFolder(activity: activity, folder: self.filesystem.currentFolder)
        }
    }
    
    private func addFolder(folder: Filesystem.Folder) {
        self.adjustRowNumbersAfterAction {
            self.filesystem.addFolderToFolder(destination: self.filesystem.currentFolder, folder: folder)
        }
    }
    
    private func loadSampleData() {
        if self.filesystem.getAllActivities().isEmpty {
            let activity = Activity(name: "Gitarre üben", measurementMethod: .Time)!
            activity.fillWithTimeData()
            self.addActivity(activity: activity)
            self.addActivity(activity: Activity(name: "Klavier spielen", measurementMethod: .YesNo)!)
            self.addActivity(activity: Activity(name: "Laufen", measurementMethod: .DoubleWithUnit, unit: "km")!)
            self.addActivity(activity: Activity(name: "Liegestütze", measurementMethod: .IntWithoutUnit)!)
        }
    }
    
    func refreshAllRows() {
        var total = self.filesystem.currentFolder.count
        if total < self.minimumCellNumber {
            total = self.minimumCellNumber
        }
        for index in 0..<total{
            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        }
    }
}
