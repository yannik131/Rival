//
//  TableCells.swift
//  Rival
//
//  Created by Yannik Schroeder on 21.05.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import UIKit

class FolderTableViewCell: UITableViewCell {
    
    //MARK: - Properties
    
    @IBOutlet weak var folderName: UILabel!
    @IBOutlet weak var folderImageView: UIImageView!
    
    var folder: Folder! {
        didSet {
            if folderImageView.image == nil {
                folderImageView.image = UIImage(systemName: "folder")
            }
            folderName.text = folder.name
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
        switch(activity.measurementMethod) {
        case .time:
            activityImageView.image = UIImage(systemName: "clock")
        case .yesNo:
            activityImageView.image = UIImage(systemName: "checkmark.circle")
        case .intWithoutUnit:
            activityImageView.image = UIImage(systemName: "number.circle")
        case .doubleWithUnit:
            activityImageView.image = UIImage(systemName: "u.circle")
        }
    }
}

class FolderConfigFolderTableViewCell: UITableViewCell {
    @IBOutlet weak var folderName: UILabel!
    @IBOutlet weak var checkButton: UIButton!
    @IBOutlet weak var folderImageView: UIImageView!
}

class FolderConfigActivityTableViewCell: UITableViewCell {
    @IBOutlet weak var activityName: UILabel!
    @IBOutlet weak var checkButton: UIButton!
}
