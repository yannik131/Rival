//
//  FriendsTableViewController.swift
//  
//
//  Created by Yannik Schroeder on 24.06.20.
//

import UIKit
import Contacts

class FriendsTableViewController: UITableViewController, InputDelegate {
    
    //MARK: - Properties
    
    var networkHandler: NetworkHandler?
    
    var friends: [String] = []
    var rivals: [String] = []
    var groups: [String] = []
    
    let FRIENDS = 0
    let RIVALS = 1
    let GROUPS = 2
    
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        networkHandler = NetworkHandler.getInstance(delegate: self)
    }
    
    //MARK: - Actions
    
    @IBAction func loginTapped(_ sender: UIButton) {
        
    }
    
    //MARK: - InputDelegate
    
    func requestInputs(title: String, message: String, defaults: [String], completion: ((UIAlertController) -> Void)?)  {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        for value in defaults {
            alert.addTextField() { (textField) in
                textField.text = value
                textField.clearButtonMode = .always
            }
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (action) in
            completion?(alert)
        }))
        alert.addAction(UIAlertAction(title: "Abbrechen", style: UIAlertAction.Style.cancel, handler: nil))
        
        navigationController!.present(alert, animated: true, completion: nil)
    }
    
    func presentError(_ error: Error) {
        
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch(section) {
        case FRIENDS:
            return "Freunde"
        case RIVALS:
            return "Rivalen"
        case GROUPS:
            return "Gruppen"
        default:
            fatalError()
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch(section) {
        case FRIENDS:
            return friends.count
        case RIVALS:
            return rivals.count
        case GROUPS:
            return groups.count
        default:
            fatalError()
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FriendCell", for: indexPath)
        switch(indexPath.section) {
        case FRIENDS:
            cell.textLabel?.text = friends[indexPath.row]
        case RIVALS:
            cell.textLabel?.text = rivals[indexPath.row]
        case GROUPS:
            cell.textLabel?.text = groups[indexPath.row]
        default:
            fatalError()
        }
        
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch(indexPath.section) {
        case FRIENDS:
            performSegue(withIdentifier: "ShowFriend", sender: friends[indexPath.row])
        case RIVALS:
            performSegue(withIdentifier: "ShowRival", sender: rivals[indexPath.row])
        case GROUPS:
            performSegue(withIdentifier: "ShowGroup", sender: groups[indexPath.row])
        default:
            fatalError()
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch(segue.identifier) {
        case "ShowFriend":
            let destination = segue.destination as! UITableViewController
            destination.navigationItem.title = sender as? String
        case "ShowRival":
            segue.destination.navigationItem.title = sender as? String
        case "ShowGroup":
            segue.destination.navigationItem.title = sender as? String
        case "AddFriend":
            break
        default:
            fatalError()
        }
    }

}
