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
        case folderCreation
        case plotSelection
        case moveActivity
    }
    
    enum SelectedState {
        case unselected
        case selected
        case subitem
    }
    
    class CellType {
        init(level: Int, activity: Activity? = nil, folder: Filesystem.Folder? = nil) {
            self.level = level
            self.activity = activity
            self.folder = folder
            self.state = .unselected
        }
        var level: Int
        var activity: Activity?
        var folder: Filesystem.Folder?
        var state = SelectedState.unselected
        var currentFolder: Filesystem.Folder?
    }
    
    //MARK: - Properties
    
    let filesystem = Filesystem.getInstance()
    var activities = [Activity]()
    var folders = [Filesystem.Folder]()
    var folder: Filesystem.Folder?
    var cellList = [CellType]()
    let levelCharacter = "\t"
    var mode: Mode = .folderCreation
    var selectionCallback: ((Activity) -> ())?
    var moveCallback: ((Filesystem.Folder) -> ())?
    var selectedActivity: Activity?
    
    //MARK: - Initialization
    
    private func fillList(folder: Filesystem.Folder? = nil, level: Int = 0) {
        if let folder = folder {
            for f in folder.folders {
                cellList.append(CellType(level: level, folder: f))
                self.fillList(folder: f, level: level+1)
            }
            for a in folder.activities {
                cellList.append(CellType(level: level, activity: a))
            }
        }
        else {
            cellList.append(CellType(level: level, folder: filesystem.root))
            self.fillList(folder: filesystem.root, level: level+1)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.activities = self.filesystem.getAllActivities()
        self.folders = self.filesystem.getAllFolders()
        self.fillList()
        if self.mode == .moveActivity {
            self.navigationItem.rightBarButtonItem!.isEnabled = false
        }
        if self.mode == .plotSelection && self.selectedActivity != nil {
            self.navigationItem.title = self.selectedActivity!.name
            for cell in self.cellList {
                if let activity = cell.activity {
                    if activity.id == self.selectedActivity!.id {
                        cell.state = .selected
                    }
                }
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
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
        let cellType = self.cellList[indexPath.row]
        let state = cellType.state
        if let folder = cellType.folder { //This is a folder
            let cell = tableView.dequeueReusableCell(withIdentifier: "folderConfigFolderCell", for: indexPath) as! FolderConfigFolderTableViewCell
            cell.folderName.text = String(repeating: self.levelCharacter, count: cellType.level)+folder.name
            if folder.name.isEmpty {
                cell.folderName.text! += "Wurzel"
            }
            cell.folderImageView.image = UIImage(systemName: "folder")
            if self.mode == .folderCreation {
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
        else if let activity = cellType.activity { //This is an activity
            let cell = tableView.dequeueReusableCell(withIdentifier: "folderConfigActivityCell", for: indexPath) as! FolderConfigActivityTableViewCell
            cell.activityName.text = String(repeating: self.levelCharacter, count: cellType.level)+activity.name
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
        let cellType = self.cellList[indexPath.row]
        if (cellType.folder != nil && self.mode == .plotSelection) ||
            (cellType.activity != nil && self.mode == .moveActivity) {
            return
        }
        if let folder = cellType.folder { //Now every subitem needs to be selected
            if self.mode == .folderCreation {
                let subActivities = filesystem.getAllActivities(folder: folder)
                let subFolders = filesystem.getAllFolders(folder: folder)
                //If the selected folder is not a subfolder of the current folder, abort.
                if !filesystem.getAllFolders(folder: filesystem.currentFolder).contains(where: {anyFolder in anyFolder.id == folder.id}) {
                    let alert = UIAlertController(title: "Nö.", message: "Einen Überordner in einen Unterordner zu schieben würde eine Endlosschleife verursachen.", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    return
                }
                var newState: SelectedState = .subitem
                if cellType.state == .selected {
                    newState = .unselected
                }
                for cell in self.cellList {
                    if let activity = cell.activity {
                        if subActivities.contains(where: {anyActivity in anyActivity.id == activity.id}) {
                            cell.state = newState
                        }
                    }
                    else if let folder = cell.folder {
                        if subFolders.contains(where: {anyFolder in anyFolder.id == folder.id}) {
                            cell.state = newState
                        }
                    }
                }
            }
        }
        if self.mode != .folderCreation {
            for cell in self.cellList {
                cell.state = .unselected
            }
            if self.mode == .plotSelection {
                self.selectionCallback!(cellType.activity!)
                self.navigationItem.title = cellType.activity!.name
            }
            else {
                self.folder = cellType.folder
                self.navigationItem.rightBarButtonItem!.isEnabled = true
            }
        }
        if cellType.state == .selected {
            cellType.state = .unselected
        }
        else if cellType.state == .unselected {
            cellType.state = .selected
        }
        for i in 0..<self.cellList.count {
            self.tableView.reloadRows(at: [IndexPath(row: i, section: 0)], with: .none)
        }
        if self.mode == .plotSelection {
            dismiss(animated: true, completion: nil)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let folder = self.folder else {
            fatalError()
        }
        for cell in self.cellList {
            if let activityToAdd = cell.activity, cell.state == .selected {
                folder.add(activityToAdd)
            }
            else if let folderToAdd = cell.folder, cell.state == .selected {
                folder.add(folderToAdd)
            }
        }
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveButtonTapped(_ sender: UIBarButtonItem) {
        if let folder = self.folder {
            self.moveCallback!(folder)
        }
        dismiss(animated: true, completion: nil)
    }
    
}
