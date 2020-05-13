//
//  AttachmentView.swift
//  Rival
//
//  Created by Yannik Schroeder on 01.05.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import UIKit
import AVFoundation

class AttachmentView: UIView {
    
    func setUpView(photo: Data? = nil,
                   video: Data? = nil,
                   audio: Data? = nil) {
        if let photo = photo {
            
        }
        else if let video = video {
            
        }
        else if let audio = audio {
            
        }
        else {
            return
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.viewTapped(_:)))
        self.addGestureRecognizer(tap)
    }
    
    @objc func viewTapped(_ sender: UITapGestureRecognizer) {
        
    }
    
    func loadPhoto(photo: UIImage? = nil) {
        
    }

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
