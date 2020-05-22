//
//  FolderTableViewController.swift
//  Rival
//
//  Created by Yannik Schroeder on 28.04.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import UIKit

class FolderTableViewController: UITableViewController {
    
    //MARK: - Types
    
    enum Mode {
        case createFolder
        case plotSelection
        case moveActivity
    }
    
    enum SelectedState {
        case unselected
        case selected
        case subitem
    }
    
    class CellInformation {
        init(level: Int, activity: Activity? = nil, folder: Folder? = nil, url: URL) {
            self.level = level
            self.activity = activity
            self.folder = folder
            self.state = .unselected
            self.url = url
        }
        var level: Int
        var activity: Activity?
        var folder: Folder?
        var url: URL
        var state = SelectedState.unselected
    }
    
    //MARK: - Properties
    
    let filesystem = Filesystem.shared
    var cellList: [CellInformation] = []
    let levelCharacter = "\t"
    var mode: Mode = .createFolder
    ///If mode is .plotSelection, this will be called in didSelectRow
    var selectionCallback: ((Activity) -> ())!
    ///If mode is .plotSelection, this will be set by the PlotViewController
    var selectedActivity: Activity!
    ///If mode is .createFolder, this will be set by AddNewActivityViewController
    var folderToCreate: Folder!
    ///Is called in saveButtonTapped if the mode is .createFolder
    var folderCreationCallback: (() -> Void)!
    ///If mode is .moveActivity, this will be set in didSelectRow
    var activityToMove: Activity!
    ///If mode is .moveActivity, this is the folder the user selected. Is set in didSelectRow and used in saveButtonTapped
    var selectedFolder: Folder!
    ///Is called in saveButtonTapped if the mode is .moveActivity
    var moveCallback: (() -> Void)!
    
    //MARK: - Initialization
    
    private func fillList() {
        let action = {(folder: Folder, level: Int) in
            self.cellList.append(CellInformation(level: level, activity: nil, folder: folder, url: folder.url))
            for activity in folder.activities.values {
                self.cellList.append(CellInformation(level: level, activity: activity, folder: nil, url: folder.url.appendingPathComponent(activity.id.uuidString)))
            }
        }
        filesystem.traverseDown(folderAction: action)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        fillList()
        if self.mode == .moveActivity {
            self.navigationItem.rightBarButtonItem!.isEnabled = false
        }
        else if self.mode == .plotSelection && self.selectedActivity != nil {
            self.navigationItem.title = self.selectedActivity!.name
            for cell in self.cellList {
                if let activity = cell.activity {
                    if activity.id == self.selectedActivity!.id {
                        cell.state = .selected
                    }
                }
            }
        }
        else if mode == .createFolder {
            navigationItem.title = folderToCreate.url.path
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cellList.count
    }
    
    func textColor(for state: SelectedState) -> UIColor {
        if state == .subitem {
            return UIColor.lightGray
        }
        return UIColor.black
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellInformation = self.cellList[indexPath.row]
        let state = cellInformation.state
        if let folder = cellInformation.folder { //This is a folder
            let cell = tableView.dequeueReusableCell(withIdentifier: "folderConfigFolderCell", for: indexPath) as! FolderConfigFolderTableViewCell
            cell.folderName.text = String(repeating: self.levelCharacter, count: cellInformation.level)+folder.name
            cell.folderImageView.image = UIImage(systemName: "folder")
            if self.mode == .createFolder {
                cell.checkButton.isSelected = state == .selected || state == .subitem
            }
            else if self.mode == .plotSelection {
                cell.checkButton.isHidden = true
            }
            else if self.mode == .moveActivity {
                cell.checkButton.isSelected = state == .selected
            }
            cell.folderName.textColor = self.textColor(for: state)
            self.tableView.reloadRows(at: [indexPath], with: .none)
            return cell
        }
        else if let activity = cellInformation.activity { //This is an activity
            let cell = tableView.dequeueReusableCell(withIdentifier: "folderConfigActivityCell", for: indexPath) as! FolderConfigActivityTableViewCell
            cell.activityName.text = String(repeating: self.levelCharacter, count: cellInformation.level)+activity.name
            if self.mode == .moveActivity {
                cell.checkButton.isHidden = true
            }
            else {
                cell.checkButton.isSelected = state == .selected || state == .subitem
            }
            cell.activityName.textColor = self.textColor(for: state)
            self.tableView.reloadRows(at: [indexPath], with: .none)
            return cell
        }
        else {
            fatalError()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellInformation = self.cellList[indexPath.row]
        let state = cellInformation.state
        switch(mode) {
        case .createFolder:
            if let folder = cellInformation.folder {
                //If the selected folder is not a subfolder of the current folder, abort.
                if folder.url.contains(folderToCreate.url) {
                    presentErrorAlert(presentingViewController: self, title: "Nö", message: "Einen Überordner in einen Unterordner zu schieben würde eine Endlosschleife verursachen.")
                    return
                }
                //(De)select the folder and all subitems of it
                var newState: SelectedState = .subitem
                if state == .selected {
                    newState = .unselected
                    //An url does not contain itself, so the selected folder state can be
                    //set separetely
                    cellInformation.state = .unselected
                }
                else if state == .unselected {
                    cellInformation.state = .selected
                }
                for cell in self.cellList {
                    if folder.url.contains(cell.url) {
                        cell.state = newState
                    }
                }
            }
            else if cellInformation.activity != nil {
                if state == .subitem {
                    return
                }
                else if state == .selected {
                    cellInformation.state = .unselected
                }
                else if state == .unselected {
                    cellInformation.state = .selected
                }
            }
        case .moveActivity:
            guard let folder = cellInformation.folder else {
                return
            }
            selectedFolder = folder
            deselectAll()
            cellInformation.state = .selected
            navigationItem.rightBarButtonItem!.isEnabled = true
        case .plotSelection:
            guard let activity = cellInformation.activity else {
                return
            }
            selectionCallback!(activity)
            deselectAll()
            cellInformation.state = .selected
            tableView.reloadData()
            dismiss(animated: true, completion: nil)
        }
        tableView.reloadData()
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveButtonTapped(_ sender: UIBarButtonItem) {
        do {
            switch(mode) {
            case .moveActivity:
                try filesystem.moveActivity(activityToMove, from: filesystem.current.url, to: selectedFolder.url)
                filesystem.open(selectedFolder.url)
                moveCallback()
                dismiss(animated: true, completion: nil)
            case .createFolder:
                try filesystem.createFolder(folderToCreate.name)
                for cell in cellList {
                    if cell.state == .selected {
                        if let folder = cell.folder {
                            try filesystem.moveFolder(from: folder.url, to: folderToCreate.url)
                        }
                        else if let activity = cell.activity {
                            try filesystem.moveActivity(activity, from: cell.url.deletingLastPathComponent(), to: folderToCreate.url)
                        }
                    }
                }
                folderCreationCallback()
                dismiss(animated: true, completion: nil)
            default:
                break
            }
        }
        catch {
            presentErrorAlert(presentingViewController: self, error: error)
        }
    }
    
    private func deselectAll() {
        for cell in cellList {
            cell.state = .unselected
        }
    }
}
