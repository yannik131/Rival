//
//  FolderTableViewController.swift
//  Rival
//
//  Created by Yannik Schroeder on 28.04.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import UIKit

class CellInformation {
    
    //MARK: - Types
    
    enum SelectedState {
        case unselected
        case selected
        case subitem
    }
    
    //MARK: - Properties
    
    var level: Int
    var activity: Activity?
    var folder: Folder?
    var url: URL
    var state = SelectedState.unselected
    var selected: Bool {
        return state == .selected || state == .subitem
    }
    
    //MARK: - Initialization
    
    init(level: Int, activity: Activity? = nil, folder: Folder? = nil, url: URL) {
        self.level = level
        self.activity = activity
        self.folder = folder
        self.state = .unselected
        self.url = url
    }
    
    //MARK: - Public Methods
    
    func determineTextColor() -> UIColor {
        if state == .subitem {
            return UIColor.lightGray
        }
        return UIColor.black
    }
}

class FolderTableViewController: UITableViewController {
    
    //MARK: - Types
    
    enum Mode {
        case createFolder
        case plotSelection
        case moveActivity
    }
    
    //MARK: - Properties
    
    let filesystem = Filesystem.shared
    var cellList: [CellInformation] = []
    var mode: Mode = .createFolder
    ///If mode is .plotSelection, this will be called in didSelectRow
    var selectionCallback: ((Activity) -> ())!
    ///If mode is .plotSelection, this will be set by the PlotViewController
    var selectedActivity: Activity!
    ///If mode is .createFolder, this will be set by AddNewActivityViewController
    var folderToCreate: Folder!
    ///If mode is .createFolder, this is called in saveButtonTapped
    var folderCreationCallback: (() -> Void)!
    ///If mode is .moveActivity, this will be set in didSelectRow
    var activityToMove: Activity!
    ///If mode is .moveActivity, this is the folder the user selected. Is set in didSelectRow and used in saveButtonTapped
    var selectedFolder: Folder!
    ///If mode is .moveActivity, this is called in saveButtonTapped
    var moveCallback: (() -> Void)!
    
    //MARK: - Initialization

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

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellInformation = self.cellList[indexPath.row]
        if cellInformation.folder != nil { //This is a folder
            let cell = tableView.dequeueReusableCell(withIdentifier: "folderConfigFolderCell", for: indexPath) as! FolderConfigCell
            cell.setInformation(information: cellInformation, levelCharacter: "\t")
            if mode == .plotSelection {
                cell.checkButton.isHidden = true
            }
            return cell
        }
        else if cellInformation.activity != nil { //This is an activity
            let cell = tableView.dequeueReusableCell(withIdentifier: "folderConfigActivityCell", for: indexPath) as! ActivityConfigCell
            cell.setInformation(information: cellInformation)
            if mode == .moveActivity {
                cell.checkButton.isHidden = true
            }
            return cell
        }
        else {
            fatalError()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellInformation = self.cellList[indexPath.row]
        switch(mode) {
        case .createFolder:
            handleSelectionInFolderCreationMode(at: indexPath)
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
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: nil)
            }
        }
        tableView.reloadData()
    }
    
    //MARK: - Actions
    
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
    
    //MARK: - Private Methods
    
    private func handleSelectionInFolderCreationMode(at indexPath: IndexPath) {
        let cellInformation = cellList[indexPath.row]
        let state = cellInformation.state
        
        if let folder = cellInformation.folder {
            //If the selected folder is not a subfolder of the current folder, abort.
            if folder.url.contains(folderToCreate.url) {
                presentErrorAlert(presentingViewController: self, title: "Nö.", message: "Einen Überordner in einen Unterordner zu schieben würde eine Endlosschleife verursachen.")
                return
            }
            //(De)select the folder and all subitems of it
            var newState: CellInformation.SelectedState = .subitem
            if state == .selected {
                newState = .unselected
                //An url does not contain itself, so the selected folder state can be set separetely
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
    }
    
    private func fillList() {
        let action = {(folder: Folder, level: Int) in
            self.cellList.append(CellInformation(level: level, activity: nil, folder: folder, url: folder.url))
            for activity in folder.orderedActivities {
                self.cellList.append(CellInformation(level: level, activity: activity, folder: nil, url: folder.url.appendingPathComponent(activity.id.uuidString, isDirectory: false)))
            }
        }
        filesystem.traverseDown(folderAction: action)
    }
    
    private func deselectAll() {
        for cell in cellList {
            cell.state = .unselected
        }
    }
}
