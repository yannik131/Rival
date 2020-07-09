//
//  LoginViewController.swift
//  
//
//  Created by Yannik Schroeder on 08.07.20.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var offlineButton: UIButton!
    
    let session = NetworkSession.shared
    let options = Options.getInstance()
    var loggedIn: Bool = false
    var requestSent: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        usernameTextField.delegate = self
        usernameTextField.clearButtonMode = .whileEditing
        usernameTextField.text = options.username
        passwordTextField.delegate = self
        passwordTextField.clearButtonMode = .whileEditing
        passwordTextField.text = options.password
        //TODO: Manual login in settings + save last login method
        if options.offlineMode && options.autoLogin {
            offlineButtonTapped(self)
        }
        if options.autoLogin && options.username != nil && options.password != nil {
            loginButtonTapped(self)
        }
        updateLoginButtonState()
    }
    
    func updateLoginButtonState() {
        loginButton.isEnabled = !(usernameTextField.text!.isEmpty || passwordTextField.text!.isEmpty || requestSent)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "CloseLogin" {
            return loggedIn || options.offlineMode
        }
        return true
    }
    
    @IBAction func offlineButtonTapped(_ sender: Any) {
        options.offlineMode = true
        options.save()
        performSegue(withIdentifier: "CloseLogin", sender: self)
    }
    
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        requestSent = true
        session.setBody("username", usernameTextField.text!,
                        "password", Options.hash(passwordTextField.text!))
        session.post("accounts/login/", saveCookie: true) { (response, error) in
            self.requestSent = false
            if response == "" {
                self.loggedIn = true
                self.options.username = self.usernameTextField.text!
                self.options.password = self.passwordTextField.text!
                self.options.save()
                self.performSegue(withIdentifier: "CloseLogin", sender: self)
            }
            self.updateLoginButtonState()
        }
    }
    
    @IBAction func registerButtonTapped(_ sender: Any) {
    }
    
    @IBAction func forgotButtonTapped(_ sender: Any) {
    }
}
