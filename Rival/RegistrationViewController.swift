//
//  RegistrationViewController.swift
//  Rival
//
//  Created by Yannik Schroeder on 08.07.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import UIKit
import CoreLocation
import CryptoKit
import os.log

class RegistrationViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var userTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var usernameOkCheckmark: UIImageView!
    
    var startedAddressInput: Bool = false
    let geocoder = CLGeocoder()
    let session = NetworkSession.shared
    var options = Options.getInstance()

    override func viewDidLoad() {
        super.viewDidLoad()
        usernameOkCheckmark.isHidden = true
        session.errorDelegate = self
        userTextField.delegate = self
        passwordTextField.delegate = self
        emailTextField.delegate = self
        firstNameTextField.delegate = self
        lastNameTextField.delegate = self
        addressTextField.delegate = self
        updateSendButtonState()
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == addressTextField &&  !startedAddressInput {
            presentMessage(presentingViewController: self, title: "Adresseingabe", message: "Die Koordinaten der eingegebenen Adresse werden zur lokalen Suche nach Rivalen genutzt. Sie muss nicht Ihrer wirklichen Anschrift entsprechen. Beispielformat:\nStraße [Nummer, optional], Stadt")
            startedAddressInput = true
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == addressTextField {
            getCoordinatesFromAddress()
        }
        if textField == userTextField {
            usernameOkCheckmark.isHidden = userTextField.text!.isEmpty
            checkIfUsernameIsTaken()
        }
        options.username = userTextField.text
        options.password = Options.hash(passwordTextField.text!)
        options.email = emailTextField.text
        options.firstName = firstNameTextField.text
        options.lastName = lastNameTextField.text
        updateSendButtonState()
    }
    
    func checkIfUsernameIsTaken() {
        session.setBody("username", userTextField.text!)
        session.post("accounts/taken/") { (response, error) in
            if response == "yes" {
                presentMessage(presentingViewController: self, title: "Name nicht verfügbar", message: "Der Benutzername \(self.userTextField.text!) ist bereits vergeben.")
                self.userTextField.text = nil
                self.usernameOkCheckmark.isHidden = true
            }
            else {
                self.usernameOkCheckmark.isHidden = false
            }
        }
    }
    
    func updateSendButtonState() {
        sendButton.isEnabled = !(userTextField.text!.isEmpty || passwordTextField.text!.isEmpty || emailTextField.text!.isEmpty || firstNameTextField.text!.isEmpty || lastNameTextField.text!.isEmpty || options.longitude == nil || options.latitude == nil)
    }
    
    func getCoordinatesFromAddress() {
        if addressTextField.text!.isEmpty {
            return
        }
        geocoder.geocodeAddressString(addressTextField.text!) { (placemarks, error) in
            let placemark = placemarks?.first
            self.options.longitude = placemark?.location?.coordinate.longitude
            self.options.latitude = placemark?.location?.coordinate.latitude
            os_log("Got coordinates from address: (%@, %@)", String(describing: self.options.longitude), String(describing: self.options.latitude))
            if self.options.longitude == nil || self.options.latitude == nil {
                presentMessage(presentingViewController: self, title: "Falsche Adresse", message: "Aus der eingegebenen Adresse konnten keine Koordinaten ermittelt werden.")
            }
            self.updateSendButtonState()
        }
    }
    
    @IBAction func sendButtonTapped(_ sender: Any) {
        sendButton.setTitle("Senden...", for: .normal)
        sendButton.isEnabled = false
        session.setBody("username", options.username,
                        "password", options.password,
                        "email", options.email,
                        "first_name", options.firstName,
                        "last_name", options.lastName,
                        "longitude", String(options.longitude),
                        "latitude", String(options.latitude))
        session.post("accounts/create/") { (response, error) in
            self.sendButton.setTitle("Absenden", for: .normal)
            self.sendButton.isEnabled = true
            os_log("Account creation, response: %@", String(describing: response))
            if response == "" {
                presentMessage(presentingViewController: self, title: "Account erstellt", message: "Der Account wurde erfolgreich erstellt. Sie können sich jetzt anmelden.")
            }
            else if response == "exists" {
                presentMessage(presentingViewController: self, title: "Interner Fehler", message: "Benutzername ist bereits vergeben, obwohl das vorher überprüft wurde.")
            }
            else if response == "bad email" {
                presentMessage(presentingViewController: self, title: "Falsche E-Mail", message: "Die eingegebene E-Mail hat ein falsches Format.")
            }
        }
    }
}
