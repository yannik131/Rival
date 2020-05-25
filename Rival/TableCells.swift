//
//  TableCells.swift
//  Rival
//
//  Created by Yannik Schroeder on 21.05.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import UIKit

protocol FilesystemErrorDelegate {
    func throwError(_ error: Error)
}

class FolderTableViewCell: UITableViewCell, UITextFieldDelegate {
    
    //MARK: - Properties
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var folderImageView: UIImageView!
    var errorDelegate: FilesystemErrorDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        nameTextField.delegate = self
        nameTextField.isEnabled = false
    }
    
    var folder: Folder! {
        didSet {
            if folder == nil {
                folderImageView.isHidden = true
                nameTextField.text = nil
                return
            }
            else {
                nameTextField.text = folder.name
                folderImageView.isHidden = false
                if folderImageView.image == nil {
                    folderImageView.image = UIImage(systemName: "folder")
                }
            }
        }
    }
    
    //MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        do {
            try Filesystem.shared.renameFolder(folder, name: textField.text!)
        }
        catch {
            errorDelegate?.throwError(error)
            textField.text = folder.name
        }
    }
}

class ActivityTableViewCell: UITableViewCell {
    
    //MARK: - Properties
    
    @IBOutlet weak var activityNameLabel: UILabel!
    @IBOutlet weak var practiceAmountLabel: UILabel!
    @IBOutlet weak var activityImageView: UIImageView!
    
    var activity: Activity!
    
    func setDisplayedDate(date: Date) {
        activityNameLabel.text = activity.name
        practiceAmountLabel.text = activity.getPracticeAmountString(date: date)
        if let stopWatch = StopWatchStore[activity.id] {
            if stopWatch.isRunning && stopWatch.startStamp!.isToday() {
                practiceAmountLabel.text! += "..."
            }
        }
        activityImageView.image = determineActivityImage(for: activity)
    }
}

class FolderConfigCell: UITableViewCell {
    @IBOutlet weak var folderName: UILabel!
    @IBOutlet weak var checkButton: UIButton!
    @IBOutlet weak var folderImageView: UIImageView!

    func setInformation(information: CellInformation, levelCharacter: String) {
        guard let folder = information.folder else {
            fatalError()
        }
        folderName.text = String(repeating: levelCharacter, count: information.level)+folder.name
        folderName.textColor = information.determineTextColor()
        checkButton.isSelected = information.selected
        if folderImageView.image == nil {
            folderImageView.image = UIImage(systemName: "folder")
        }
    }
}

class ActivityConfigCell: UITableViewCell {
    @IBOutlet weak var activityName: UILabel!
    @IBOutlet weak var checkButton: UIButton!

    func setInformation(information: CellInformation) {
        guard let activity = information.activity else {
            fatalError()
        }
        activityName.text = activity.name
        activityName.textColor = information.determineTextColor()
        checkButton.isSelected = information.selected
    }
}
