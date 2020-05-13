//
//  FolderConfigFolderTableViewCell.swift
//  Rival
//
//  Created by Yannik Schroeder on 29.04.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import UIKit

class FolderConfigFolderTableViewCell: UITableViewCell {
    
    @IBOutlet weak var folderName: UILabel!
    @IBOutlet weak var checkButton: UIButton!
    @IBOutlet weak var folderImageView: UIImageView!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
