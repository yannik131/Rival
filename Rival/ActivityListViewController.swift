//
//  ActivityListViewController.swift
//  Rival
//
//  Created by Yannik Schroeder on 18.07.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import UIKit

class ActivityListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var activityTableView: UITableView!
    
    var activityList: [String] = []
    var searchList: [String] = []
    let options = Options.getInstance()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchTextField.delegate = self
        activityTableView.delegate = self
        activityTableView.dataSource = self
    }
    
    private func showPopup(_ controller: UIViewController, sourceView: UIView) {
        let presentationController = AlwaysPresentAsPopover.configurePresentation(forController: controller)
        presentationController.sourceView = sourceView
        presentationController.sourceRect = sourceView.bounds
        presentationController.permittedArrowDirections = [.down, .up]
        self.present(controller, animated: true)
    }
    
    func search() {
        searchList.removeAll()
        if searchTextField.text!.isEmpty {
            searchList = activityList
        }
        else {
            for name in activityList {
                if name.contains(searchTextField.text!) {
                    searchList.append(name)
                }
            }
        }
        activityTableView.reloadData()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        search()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let name = searchList[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "standard")!
        cell.textLabel?.text = name
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 12)
        cell.detailTextLabel?.text = nil
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let indexPath = activityTableView.indexPathForSelectedRow {
            activityTableView.reloadRows(at: [indexPath], with: .none)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch(segue.identifier) {
        case "ShowActivityProfile":
            let cell = sender as! UITableViewCell
        default:
            break
        }
    }
    
    @IBAction func createButtonTapped(_ sender: Any) {
        
    }
    
}
