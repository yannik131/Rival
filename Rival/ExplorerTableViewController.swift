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

class ExplorerTableViewController: UITableViewController{
    
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
            tableView.setContentOffset(CGPoint(x: -100, y: -100), animated: true)
        }
    }
    
    @objc private func editButtonTapped() {
        tableView.setEditing(!tableView.isEditing, animated: true)
        if tableView.isEditing {
            editButtonItem.title = "Fertig"
        }
        else {
            editButtonItem.title = "Edit"
        }
        for index in 0..<filesystem.current.folders.count {
            if let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? FolderTableViewCell {
                cell.nameTextField.isEnabled = tableView.isEditing
            }
        }
        tableView.reloadData()
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
                os_log("Failed to reuse ActivityTableViewCell")
                fatalError()
            }
            cell.activity = activity
            cell.setDisplayedDate(date: chosenDate)
            return cell
        }
        else if let folder = getSelectedFolder(for: indexPath) {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "folderCell", for: indexPath) as? FolderTableViewCell else {
                os_log("Failed to reuse FolderTableViewCell")
                fatalError()
            }
            cell.folder = folder
            cell.errorDelegate = self
            //TODO: Last modified?
            return cell
        }
        else if let cell = tableView.dequeueReusableCell(withIdentifier: "folderCell", for: indexPath) as? FolderTableViewCell {
            cell.folder = nil
            return cell
        }
        else {
            os_log("Failed to reuse cell: Unknown cell")
            fatalError()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let folder = getSelectedFolder(for: indexPath) {
            self.adjustRowNumbersAfterAction {
                filesystem.open(folder.name)
                tableView.setContentOffset(CGPoint(x: -100, y: -100), animated: true)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if indexPath.row < filesystem.count && tableView.isEditing {
            return .delete
        }
        return .none
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let activity = self.getSelectedActivity(for: indexPath) {
                os_log("Deleting activity")
                self.adjustRowNumbersAfterAction {
                    filesystem.deleteActivity(activity.name)
                }
            }
            else if let folder = self.getSelectedFolder(for: indexPath) {
                os_log("Deleting folder")
                self.adjustRowNumbersAfterAction {
                    do {
                        try filesystem.deleteFolder(folder.name)
                    }
                    catch {
                        presentErrorAlert(presentingViewController: self, error: error)
                    }
                }
            }
            os_log("Success")
            updatePath()
        }
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        os_log("%@::%@ preparing for segue with identifier %@", #file, #function, segue.identifier ?? "nil")
        super.prepare(for: segue, sender: sender)
        switch(segue.identifier ?? "") {
        case "AddActivity":
            if let controller = (segue.destination as! UINavigationController).topViewController as? AddNewActivityTableViewController {
                controller.completionCallback = tableView.reloadData
            }
        case "ShowDetail":
            let destinationViewController = segue.destination as! ActivityDetailTableViewController
            let selectedCell = sender as! ActivityTableViewCell
            
            guard let indexPath = tableView.indexPath(for: selectedCell) else {
                os_log("ShowDetail segue triggered without selected cell")
                break
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
            break
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        os_log("Explorer view will appear")
        tableView.reloadData()
        self.updatePath()
    }
    
    //MARK: - Private Methods
    
    //MARK: UI Stuff
    
    private func setUpDateArrows() {
        let leftArrow = UIBarButtonItem(image: UIImage(systemName: "arrow.left")!, style: .plain, target: self, action: #selector(self.previousDateButtonTapped(_:)))
        leftArrow.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.navigationItem.leftBarButtonItems = [self.editButtonItem, leftArrow]
        editButtonItem.action = #selector(editButtonTapped)
        editButtonItem.title = "Edit"
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
        tableView.reloadData()
        updatePath()
        os_log("Success")
    }

    private func setDateButtonDate() {
        self.dateButton.setTitle(self.chosenDate.dateString(), for: .normal)
        if self.chosenDate.isToday() {
            self.dateButton.titleLabel!.font = UIFont.boldSystemFont(ofSize: 14)
        }
        else {
            self.dateButton.titleLabel!.font = UIFont.systemFont(ofSize: 14)
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
                try filesystem.createActivity(name: "Gitarre üben", measurementMethod: .time, attachmentType: .audio)
                try filesystem.createActivity(name: "Klavier spielen", measurementMethod: .yesNo, attachmentType: .video)
                try filesystem.createActivity(name: "5km Lauf", measurementMethod: .time, attachmentType: .photo)
                try filesystem.createActivity(name: "Liegestütze", measurementMethod: .intWithoutUnit, attachmentType: .photo)
            }
        }
        catch {
            presentErrorAlert(presentingViewController: self, error: error)
        }
    }
}

extension ExplorerTableViewController: FilesystemErrorDelegate {
    func throwError(_ error: Error) {
        presentErrorAlert(presentingViewController: self, error: error)
    }
}
