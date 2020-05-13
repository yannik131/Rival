//
//  ActivityTableViewCell.swift
//  Rival
//
//  Created by Yannik Schroeder on 15.04.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import UIKit

class ActivityTableViewCell: UITableViewCell {
    
    //MARK: - Properties
    
    @IBOutlet weak var activityNameLabel: UILabel!
    @IBOutlet weak var practiceAmountLabel: UILabel!
    @IBOutlet weak var activityImageView: UIImageView!
    
    var activity: Activity!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
