//
//  Filesystem.swift
//  Rival
//
//  Created by Yannik Schroeder on 27.04.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import Foundation
import os.log

class Filesystem {
    
    //MARK: - Properties
    
    var root = Folder(name: "")
    private static var instance: Filesystem?
    var currentFolder: Folder
    var currentPath: String {
        get {
            var path = "/"
            for component in self.currentFolder.pathComponents {
                path += component + "/"
            }
            return path
        }
    }
    
    let decoder = JSONDecoder()
    let encoder = JSONEncoder()
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .allDomainsMask).first!
    static let ArchiveURL = Filesystem.DocumentsDirectory.appendingPathComponent("filesystem.json")
    
    //MARK: - Initialization
    
    private init() {
        self.currentFolder = self.root
        self.load()
    }
    
    //MARK: - Methods
    
    public static func getInstance() -> Filesystem {
        if Filesystem.instance == nil {
            Filesystem.instance = Filesystem()
        }
        return Filesystem.instance!
    }
    
    public func openFolderInCurrentFolder(folder: Folder) {
        self.currentFolder = self.currentFolder.folders.first(where: {toFind in toFind.name == folder.name})!
    }
    
    public func closeCurrentFolder() {
        var components = self.currentFolder.pathComponents
        if components.count > 0 {
            components.removeLast()
            self.openFolder(pathComponents: components)
        }
    }
    
    public func openFolder(pathComponents: [String]) {
        if pathComponents.isEmpty {
            self.currentFolder = self.root
        }
        else {
            self.currentFolder = self.root
            for component in pathComponents {
                self.currentFolder = self.currentFolder.folders.first(where: {folder in folder.name == component})!
            }
        }
    }
    
    public func removeEverywhere(folders: [Folder]? = nil,
                                 activities: [Activity]? = nil) {
        let remove = {(folder: Filesystem.Folder) in
            if let folders = folders {
                folder.folders.removeAll(where: {anyFolder in folders.contains(where: {toBeDeleted in toBeDeleted.id == anyFolder.id})})
            }
            if let activities = activities {
                folder.activities.removeAll(where: {anyActivity in activities.contains(where: {toBeDeleted in toBeDeleted.id == anyActivity.id})})
            }
        }
        self.traverseDirectory(folderAction: remove)
    }
    
    public func addFolderToFolder(destination: Folder, folder: Folder) {
        /*
         If folder is already in the filesystem, it's contents will be erased.
         */
        self.removeEverywhere(folders: folder.folders, activities: folder.activities)
        destination.add(folder)
        destination.sortFolders()
    }
    
    public func addActivityToFolder(activity: Activity, folder: Folder) {
        self.removeEverywhere(activities: [activity])
        folder.add(activity)
    }
    
    public func removeFolderInCurrentFolder(at index: Int) {
        let folder = self.currentFolder.folders[index]
        for new in folder.folders {
            self.currentFolder.add(new)
        }
        self.currentFolder.activities += folder.activities
        self.currentFolder.folders.removeAll(where: {$0.id == folder.id})
        self.currentFolder.sortActivities()
        self.currentFolder.sortFolders()
    }
    
    public func getAllActivities(folder: Folder? = nil) -> [Activity] {
        var list = [Activity]()
        let addToList = {(activity: Activity) in
            if !list.contains(where: {element in element.name == activity.name}) {
                list.append(activity)
            }
        }
        self.traverseDirectory(folder: folder, activityAction: addToList)
        return list
    }

    public func getAllFolders(folder: Folder? = nil) -> [Folder] {
        var list = [Folder]()
        let addToList = {(folder: Folder) in
            if !list.contains(where: {element in element.id == folder.id}) {
                list.append(folder)
            }
        }
        self.traverseDirectory(folder: folder, folderAction: addToList)
        //The root folder has no name and is not supposed to be counted as a folder
        //list.removeAll(where: {folder in folder.name.isEmpty})
        return list
    }
    
    public func traverseDirectory(folder: Folder? = nil,
                                  folderAction: ((Folder) -> ())? = nil,
                                  activityAction: ((Activity) -> ())? = nil) {
        if let folder = folder {
            for f in folder.folders {
                if let action = folderAction {
                    action(f)
                }
                self.traverseDirectory(folder: f, folderAction: folderAction, activityAction: activityAction)
            }
            if let action = activityAction {
                for a in folder.activities {
                    action(a)
                }
            }
        }
        else {
            if let action = folderAction {
                action(self.root)
            }
            self.traverseDirectory(folder: self.root, folderAction: folderAction, activityAction: activityAction)
        }
    }
    
    public func printDirectory(folder: Folder? = nil, levelCount: Int = 0) {
        if let folder = folder {
            for f in folder.folders {
                print(String(repeating: "-", count: levelCount)+f.name)
                self.printDirectory(folder: f, levelCount: levelCount+1)
            }
            for a in folder.activities {
                print(String(repeating: "-", count: levelCount)+a.name)
            }
        }
        else {
            print("Filesystem: ")
            self.printDirectory(folder: self.root)
        }
    }
    
    private func load() {
        do {
            let jsonString = try String(contentsOf: Filesystem.ArchiveURL)
            if let jsonData = jsonString.data(using: .utf8) {
                do {
                    let root = try decoder.decode(Folder.self, from: jsonData)
                    self.root = root
                    self.currentFolder = root
                }
                catch {
                    os_log("Cannot decode from json data: %s Using an empty filesystem instead.", error.localizedDescription)
                }
            }
        }
        catch {
           os_log("Cannot read from file: %s", error.localizedDescription)
        }
    }
    
    public func save() {
        guard let jsonData = try? encoder.encode(self.root) else {
            fatalError("Could not encode root folder.")
        }
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            fatalError("Could not create a string out of json data.")
        }
        do {
            try jsonString.write(toFile: Filesystem.ArchiveURL.path, atomically: false, encoding: .utf8)
        }
        catch {
            fatalError("Cannot write to file: \(error.localizedDescription)")
        }
        os_log("Successfully saved filesystem.")
    }
    
    //MARK: - Types
    
    class Folder: Codable {
        init(name: String) {
            self.name = name
        }
        public func sortActivities() {
            self.activities = self.activities.sorted(by: {$0.name < $1.name})
        }
        public func sortFolders() {
            self.folders = self.folders.sorted(by: {$0.name < $1.name})
        }
        public func add(_ activity: Activity) {
            self.activities.append(activity)
            self.sortActivities()
        }
        public func add(_ folder: Folder) {
            if self.folders.contains(where: {$0.id == folder.id}) {
                fatalError()
            }
            print("Adding \(folder.name) to \(name)")
            self.folders.append(folder)
            folder.pathComponents = self.pathComponents + [folder.name]
            print("\(name) pathComponent: \(pathComponents)\n\(folder.name) pathComponent: \(folder.pathComponents)")
            self.sortFolders()
        }
        public func list() -> (folders: [String], activities: [String]) {
            return (folders.map({$0.name}), activities.map({$0.name}))
        }
        let name: String
        var count: Int {
            return activities.count + folders.count
        }
        var pathComponents: [String] = []
        var activities = [Activity]()
        var folders = [Folder]()
        let id = UUID()
    }
    
}
