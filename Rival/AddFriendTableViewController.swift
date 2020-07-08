//
//  AddFriendTableViewController.swift
//  
//
//  Created by Yannik Schroeder on 25.06.20.
//

import UIKit
import Contacts

class AddFriendTableViewController: UITableViewController {
    private var contacts: [(name: String, number: String)] = []
    
    private func fetchContactList() {
        //https://stackoverflow.com/questions/33973574/fetching-all-contacts-in-ios-swift
        let contactStore = CNContactStore()
        var contacts = [CNContact]()
        let keys = [
                CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                        CNContactPhoneNumbersKey,
                        CNContactEmailAddressesKey
                ] as [Any]
        let request = CNContactFetchRequest(keysToFetch: keys as! [CNKeyDescriptor])
        do {
            try contactStore.enumerateContacts(with: request){
                    (contact, stop) in
                // Array containing all unified contacts from everywhere
                contacts.append(contact)
                for phoneNumber in contact.phoneNumbers {
                    self.contacts.append((name: contact.givenName + " " + contact.familyName, number: phoneNumber.value.stringValue))
                }
                self.contacts = self.contacts.sorted(by: { $0.name < $1.name })
            }
        } catch {
            presentErrorAlert(presentingViewController: self, error: nil, title: "Fehler", message: "Die Kontakte konnten nicht gelesen werden. Stelle sicher, dass es der App erlaubt ist, auf diese Daten zuzugreifen (Einstellungen-Rival-Kontakte)")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchContactList()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath)

        cell.textLabel?.text = contacts[indexPath.row].name

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let name = contacts[indexPath.row].name
        let alert = UIAlertController(title: "Kontakt hinzufügen", message: "Willst Du \(name) eine Freundschaftsanfrage senden?", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ja", style: UIAlertAction.Style.default, handler: nil))
        alert.addAction(UIAlertAction(title: "Nein", style: UIAlertAction.Style.cancel))
        present(alert, animated: true, completion: nil)
    }
    
    

}
