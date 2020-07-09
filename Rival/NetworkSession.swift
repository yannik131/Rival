//
//  NetworkSession.swift
//  Rival
//
//  Created by Yannik Schroeder on 08.07.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import Foundation
import os.log
import UIKit

extension CharacterSet {
    static let rfc3986Unreserved = CharacterSet(charactersIn:
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
}

class NetworkSession {
    static let shared = NetworkSession()
    let serverURL = "http://192.168.0.79:8000/"
    var cookie: String?
    var postString: String?
    var errorDelegate: UIViewController?
    var presentErrors: Bool = true
    
    init() {
        if FileManager.default.fileExists(atPath: Filesystem.shared.cookieURL.path) {
            cookie = try! Serialization.load(String.self, with: Filesystem.shared.decoder, from: Filesystem.shared.cookieURL)
        }
    }
    
    func setBody(_ args: String...) {
        guard args.count % 2 == 0 else {
            os_log("%@::%@: Uneven number of arguments", #file, #function)
            return
        }
        postString = ""
        for i in stride(from: 0, to: args.count, by: 2) {
            postString! += args[i] + "=" + args[i+1].addingPercentEncoding(withAllowedCharacters: CharacterSet.rfc3986Unreserved)! + "&"
        }
        postString!.removeLast()
    }
    
    func post(_ urlString: String, saveCookie: Bool = false, handler: ((_ response: String?, _ error: Error?) -> Void)? = nil) {
        guard let postString = postString else {
            os_log("post called without a post message")
            return
        }
        let url = URL(string: serverURL + urlString)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(cookie, forHTTPHeaderField: "Set-Cookie")
        request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if let error = error {
                os_log("Could not connect to server: %@", String(describing: error))
                if self.presentErrors {
                    DispatchQueue.main.async {
                        presentErrorAlert(presentingViewController: UIApplication.getTopViewController()!, error: error, title: "Verbindung nicht möglich")
                    }
                    
                }
            }
            
            if saveCookie, let response = response as? HTTPURLResponse {
                self.cookie =  response.allHeaderFields["Set-Cookie"] as? String
                if let cookie = self.cookie {
                    os_log("Saving the cookie")
                    try! Serialization.save(cookie, with: Filesystem.shared.encoder, to: Filesystem.shared.cookieURL)
                }
            }
            var responseString: String?
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                responseString = dataString
            }
            DispatchQueue.main.async {
                handler?(responseString, error)
            }
        }
        task.resume()
    }
}
