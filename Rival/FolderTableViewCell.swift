//
//  FolderTableViewCell.swift
//  Rival
//
//  Created by Yannik Schroeder on 27.04.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import UIKit

class FolderTableViewCell: UITableViewCell {
    
    //MARK: - Properties
    
    @IBOutlet weak var folderName: UILabel!
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
