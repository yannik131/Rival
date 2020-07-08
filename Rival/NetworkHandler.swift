//
//  NetworkHandler.swift
//  Rival
//
//  Created by Yannik Schroeder on 25.06.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import Foundation
import UIKit
import CryptoKit

protocol InputDelegate: ErrorDelegate {
    func requestInputs(title: String, message: String, defaults: [String], completion: ((UIAlertController) -> Void)?)
}

class NetworkHandler {
    var delegate: InputDelegate!
    private static var instance: NetworkHandler?
    let loginArchiveURL = Filesystem.shared.documentsURL.appendingPathComponent("login.json", isDirectory: false)
    private(set) var isLoggedIn = false
    
    static func getInstance(delegate: InputDelegate) -> NetworkHandler? {
        if NetworkHandler.instance == nil {
            let handler = NetworkHandler()
            handler.delegate = delegate
            if let loginDict = try? Serialization.load([String:String].self, with: Filesystem.shared.decoder, from: handler.loginArchiveURL) {
                handler.requestLogin(loginDict)
            }
            else {
                var loginDict: [String:String] = [:]
                delegate.requestInputs(title: "Nutzer erstellen", message: "Legen Sie Nutzername und Passwort fest:", defaults: ["Nutzername", "Passwort"], completion: { (alert) in
                    loginDict["username"] = alert.textFields![0].text!
                    loginDict["password"] = alert.textFields![1].text!
                    handler.requestUserCreation(loginDict)
                    handler.requestLogin(loginDict)
                })
            }
            if handler.isLoggedIn {
                NetworkHandler.instance = handler
            }
        }
        return NetworkHandler.instance
    }
    
    func requestLogin(_ loginDict: [String:String]) {
        print("Requesting login with user data \(loginDict)")
        let url = URL(string: "http://192.168.0.26:8000/login/" + loginDict["username"]! + "/" + loginDict["password"]!)!
        
        let task = URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            guard let data = data else {
                return
            }
            print("Data: \(String(data: data, encoding: .utf8)!)")
            print("Response: \(response)")
            print("Error: \(error)")
        }
        task.resume()
    }
    
    func requestUserCreation(_ loginDict: [String:String]) {
        print("Requesting user creation with user data \(loginDict)")
        let url = URL(string: "http://192.168.0.26:8000/create/" + loginDict["username"]! + "/" + loginDict["password"]!)!
        
        let task = URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            guard let data = data else {
                return
            }
            print("Data: \(String(data: data, encoding: .utf8)!)")
            print("Response: \(response)")
            print("Error: \(error)")
        }
        task.resume()
    }
}
