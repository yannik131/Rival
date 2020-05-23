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
    
    let filesystem = Filesystem.shared
    let minimumCellNumber = 6
    var closeButton: UIBarButtonItem!
    
    var chosenDate = Date() {
        didSet {
            self.setDateButtonDate()
            tableView.reloadData()
        }
    }
    
    //MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setDateButtonDate()
        self.loadSampleData()
        self.setUpDateArrows()
        //This is necessary if the segue animations look weird
        self.navigationController!.view.backgroundColor = UIColor.white
    }
    
    //MARK: - Actions
    
    @IBAction func dateButtonTouchUpOutside(_ sender: UIButton) {
        self.chosenDate = Date()
        tableView.reloadData()
    }
    
    @objc func previousDateButtonTapped(_ sender: UIButton) {
        self.chosenDate.addDays(days: -1)
    }
    
    @objc func nextDateButtonTapped(_ sender: UIButton) {
        self.chosenDate.addDays(days: 1)
    }
    
    @objc private func closeCurrentFolder() {
        self.adjustRowNumbersAfterAction {
            filesystem.close()
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let total = filesystem.count
        if total > self.minimumCellNumber {
            return total
        }
        return self.minimumCellNumber
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let activity = getSelectedActivity(for: indexPath) {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "activityCell", for: indexPath) as? ActivityTableViewCell else {
                fatalError()
            }
            cell.activity = activity
            cell.setDisplayedDate(date: chosenDate)
            return cell
        }
        else if let folder = getSelectedFolder(for: indexPath) {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "folderCell", for: indexPath) as? FolderTableViewCell else {
                fatalError()
            }
            cell.folder = folder
            //TODO: Last modified?
            return cell
        }
        else if let cell = tableView.dequeueReusableCell(withIdentifier: "folderCell", for: indexPath) as? FolderTableViewCell {
            cell.folder = nil
            return cell
        }
        else {
            fatalError("Unknown cell")
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let folder = getSelectedFolder(for: indexPath) {
            self.adjustRowNumbersAfterAction {
                filesystem.open(folder.name)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if tableView.isEditing {
            if indexPath.row < filesystem.count {
                
                return .delete
            }
        }
        return .none
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let activity = self.getSelectedActivity(for: indexPath) {
                self.adjustRowNumbersAfterAction {
                    filesystem.deleteActivity(activity.name)
                }
            }
            else if let folder = self.getSelectedFolder(for: indexPath) {
                self.adjustRowNumbersAfterAction {
                    do {
                        try filesystem.deleteFolder(folder.name)
                    }
                    catch {
                        presentErrorAlert(presentingViewController: self, error: error)
                    }
                }
            }
            updatePath()
        }
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
        case "AddActivity":
            if let controller = (segue.destination as! UINavigationController).topViewController as? AddNewActivityTableViewController {
                controller.completionCallback = tableView.reloadData
            }
        case "ShowDetail":
            guard let destinationViewController = segue.destination as? ActivityDetailTableViewController else {
                fatalError("showDetail: Wrong connection.")
            }
            
            guard let selectedCell = sender as? ActivityTableViewCell else {
                fatalError("showDetail: No cell was tapped.")
            }
            
            guard let indexPath = tableView.indexPath(for: selectedCell) else {
                fatalError("Unknown cell selected.")
            }
            
            let activity = getSelectedActivity(for: indexPath)!
            destinationViewController.activity = activity
            destinationViewController.chosenDate = self.chosenDate
            destinationViewController.selectDateCallback = {(date: Date) in self.chosenDate = date}
        case "DateSelection":
            let navigationController = segue.destination as? UINavigationController
            let destinationViewController = navigationController!.topViewController as! CalendarViewController
            destinationViewController.singleSelectionCallback = {(date: Date) in self.chosenDate = date}
            destinationViewController.firstDate = self.chosenDate
        default:
            fatalError("Unknown segue triggered.")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
        self.updatePath()
    }
    
    //MARK: - Private Methods
    
    //MARK: UI Stuff
    
    private func setUpDateArrows() {
        let leftArrow = UIBarButtonItem(image: UIImage(systemName: "arrow.left")!, style: .plain, target: self, action: #selector(self.previousDateButtonTapped(_:)))
        leftArrow.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.navigationItem.leftBarButtonItems = [self.editButtonItem, leftArrow]
        let rightArrow = UIBarButtonItem(image: UIImage(systemName: "arrow.right"), style: .plain, target: self, action: #selector(self.nextDateButtonTapped(_:)))
        rightArrow.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.navigationItem.rightBarButtonItems = [self.addButton, rightArrow]
        closeButton = UIBarButtonItem(image: UIImage(systemName: "arrow.left")!, style: .plain, target: self, action: #selector(self.closeCurrentFolder))
        self.pathNavigationbar.leftBarButtonItem = closeButton
    }
    
    private func updatePath() {
        pathNavigationbar.title = filesystem.current.url.path
        if filesystem.current.parent == nil {
            closeButton.isEnabled = false
        }
        else {
            closeButton.isEnabled = true
        }
    }
    
    private func adjustRowNumbersAfterAction(action: () -> ()) {
        let previousRowCount = filesystem.count
        action()
        let currentRowCount = filesystem.count
        if previousRowCount < minimumCellNumber || currentRowCount < minimumCellNumber {
            tableView.reloadData()
            updatePath()
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
        tableView.reloadData()
        updatePath()
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
    
    //MARK: Model Stuff
    
    private func getSelectedActivity(for indexPath: IndexPath) -> Activity? {
        let folderCount = filesystem.current.folders.count
        let activityCount = filesystem.current.activities.count
        if folderCount == 0 || indexPath.row+1 > folderCount {
            let activityIndex = indexPath.row - folderCount
            guard activityIndex >= 0 && activityIndex < activityCount else {
                return nil
            }
            return filesystem.current.orderedActivities[activityIndex]
        }
        return nil
    }
    
    private func getSelectedFolder(for indexPath: IndexPath) -> Folder? {
        if indexPath.row < filesystem.current.folders.count {
            return filesystem.current.orderedFolders[indexPath.row]
        }
        return nil
    }
    
    private func loadSampleData() {
        do {
            if filesystem.count == 0 {
                try filesystem.createActivity(name: "Gitarre üben", measurementMethod: .time)
                try filesystem.createActivity(name: "Klavier spielen", measurementMethod: .yesNo)
                try filesystem.createActivity(name: "Laufen", measurementMethod: .doubleWithUnit, unit: "km")
                try filesystem.createActivity(name: "Liegestütze", measurementMethod: .intWithoutUnit)
            }
        }
        catch {
            presentErrorAlert(presentingViewController: self, error: error)
        }
    }
}
