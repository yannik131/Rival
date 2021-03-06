//
//  CommonGUI.swift
//  Rival
//
//  Created by Yannik Schroeder on 22.05.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import Foundation
import UIKit

extension UIApplication {

    class func getTopViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {

        if let nav = base as? UINavigationController {
            return getTopViewController(base: nav.visibleViewController)

        } else if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return getTopViewController(base: selected)

        } else if let presented = base?.presentedViewController {
            return getTopViewController(base: presented)
        }
        return base
    }
}

func presentMessage(presentingViewController: UIViewController, title: String, message: String) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
    presentingViewController.present(alert, animated: true, completion: nil)
}

public func presentErrorAlert(presentingViewController: UIViewController, error: Error! = nil, title: String? = nil, message: String? = nil) {
    guard error != nil || message != nil else {
        fatalError()
    }
    var title = title ?? "Fehler"
    var message = message ?? error.localizedDescription
    if let error = error as? FilesystemError {
        switch(error) {
        case .cannotCreate(let msg):
            title = "Erstellen nicht möglich"
            message = msg
        case .cannotDelete(let msg):
            title = "Löschen nicht möglich"
            message = msg
        case .cannotMove(let msg):
            title = "Verschieben nicht möglich"
            message = msg
        case .cannotRename(let msg):
            title = "Umbennen nicht möglich"
            message = msg
        }
        //TODO: Find out if its possible to get the string from an error enum so that 4x message = msg is not necessary
    }
    else if let error = error as? MediaError {
        switch(error) {
        case .PlayAudioError(let msg):
            title = "Audio abspielen nicht möglich"
            message = msg
        case .RecordAudioError(let msg):
            title = "Audio aufnehmen nicht möglich"
            message = msg
        case .RecordPhotoError(let msg):
            title = "Foto aufnehmen nicht möglich"
            message = msg
        case .RecordVideoError(let msg):
            title = "Video aufnehmen nicht möglich"
            message = msg
        case .SeePhotoError(let msg):
            title = "Foto ansehen nicht möglich"
            message = msg
        case .WatchVideoError(let msg):
            title = "Video ansehen nicht möglich"
            message = msg
        }
    }
    presentMessage(presentingViewController: presentingViewController, title: title, message: message)
}

@objc protocol DoneButton {
    //Resign first responder in here
    @objc func doneCallback()
}

func addDoneButton<ParentType: UIResponder & DoneButton>(parentView: ParentType, to view: UIView) {
    //This is copied from: https://stackoverflow.com/questions/20192303/how-to-add-a-done-button-to-numpad-keyboard-in-ios
    let keyboardToolbar = UIToolbar()
    keyboardToolbar.sizeToFit()
    let flexBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
        target: nil, action: nil)
    let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done,
                                        target: parentView, action: #selector(parentView.doneCallback))
    keyboardToolbar.items = [flexBarButton, doneBarButton]
    if let view = view as? UITextField {
        view.inputAccessoryView = keyboardToolbar
    }
    else if let view = view as? UITextView {
        view.inputAccessoryView = keyboardToolbar
    }
}

func determineActivityImage(for activity: Activity) -> UIImage {
    switch(activity.measurementMethod) {
    case .time:
        return UIImage(systemName: "clock")!
    case .yesNo:
        return UIImage(systemName: "checkmark.circle")!
    case .intWithoutUnit:
        return UIImage(systemName: "number.circle")!
    case .doubleWithUnit:
        return UIImage(systemName: "u.circle")!
    }
}

//MARK: - Extensions

extension UIButton {
    public func createBorder() {
        self.backgroundColor = .clear
        self.layer.cornerRadius = 5
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.systemBlue.cgColor
        self.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    }
    
    public func disable() {
        isEnabled = false
        tintColor = UIColor.systemGray3
    }
    
    public func enable() {
        isEnabled = true
        tintColor = UIColor.systemBlue
    }
}


