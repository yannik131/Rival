//
//  NetworkSession.swift
//  Rival
//
//  Created by Yannik Schroeder on 08.07.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import Foundation
import os.log

extension CharacterSet {
    static let rfc3986Unreserved = CharacterSet(charactersIn:
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
}

class NetworkSession {
    private static var instance: NetworkSession?
    let serverURL = "http://127.0.0.1:8000/"
    var cookie: String?
    var postString: String?
    
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
    
    func post(_ urlString: String, saveCookie: Bool = false, handler: ((String) -> Void)? = nil) {
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
                os_log("Error making connection: %@", error.localizedDescription)
                return
            }
            
            if saveCookie, let response = response as? HTTPURLResponse {
                self.cookie =  response.allHeaderFields["Set-Cookie"] as? String
            }
            
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                print("Response: \(dataString)")
                handler?(dataString)
            }
        }
        task.resume()
    }
    
    private init() { }
    
    static func getInstance() -> NetworkSession {
        if NetworkSession.instance == nil {
            NetworkSession.instance = NetworkSession()
        }
        return NetworkSession.instance!
    }
}
