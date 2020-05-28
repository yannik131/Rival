//
//  ImageViewController.swift
//  Rival
//
//  Created by Yannik Schroeder on 28.05.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var photoView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var noImageLabel: UILabel!
    
    var date: Date!
    var activity: Activity!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.date = MediaStore.shared.date!
        self.activity = MediaStore.shared.activity!
        setImage(MediaStore.shared.image)
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 6.0
        // Do any additional setup after loading the view.
    }
    
    func setImage(_ image: UIImage?) {
        if image == nil {
            noImageLabel.isHidden = false
            photoView.image = nil
        }
        else {
            noImageLabel.isHidden = true
            photoView.image = image
        }
        updateLabel()
    }
    
    func updateLabel() {
        titleLabel.text = activity.name + " - " + date.dateString()
    }
    
    @IBAction func increaseDate(_ sender: Any) {
        date.addDays(days: 1)
        let url = MediaStore.shared.getMediaArchiveURL(for: MediaStore.shared.activity!, at: date)
        let image = UIImage(contentsOfFile: url.path)
        setImage(image)
    }
    
    @IBAction func decreaseDate(_ sender: Any) {
        date.addDays(days: -1)
        let url = MediaStore.shared.getMediaArchiveURL(for: MediaStore.shared.activity!, at: date)
        let image = UIImage(contentsOfFile: url.path)
        setImage(image)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return photoView
    }

}
