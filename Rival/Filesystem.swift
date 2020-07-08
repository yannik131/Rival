//
//  Filesystem.swift
//  Rival
//
//  Created by Yannik Schroeder on 27.04.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import Foundation
import UIKit
import os.log

extension URL {
    public func contains(_ url: URL) -> Bool {
        if url.path == path {
            return false
        }
        return url.path.contains(self.path)
    }
    
    public var count: Int {
        return pathComponents.count
    }
    
    ///If the folder- or filename consists of only an UUID, this will retrieve it
    var id: UUID? {
        if let id = UUID(uuidString: self.deletingPathExtension().lastPathComponent) {
            return id
        }
        return nil
    }
}

class Folder {
    //MARK: - Types
    
    enum Permission {
        case everyone
        case user
    }
    
    //MARK: - Properties
    
    var activities: [String:Activity] = [:]
    var orderedActivities: [Activity] {
        return activities.values.sorted(by: {$0.name < $1.name})
    }
    var orderedActivityNames: [String] {
        return activities.keys.sorted()
    }
    var folders: [String:Folder] = [:]
    var orderedFolders: [Folder] {
        return folders.values.sorted(by: {$0.name < $1.name})
    }
    var orderedFolderNames: [String] {
        return folders.keys.sorted()
    }
    var parent: Folder?
    var name: String
    ///Recursively defined computed property
    var url: URL {
        if let parent = parent {
            return parent.url.appendingPathComponent(name, isDirectory: true)
        }
        return URL(fileURLWithPath: name, isDirectory: true)
    }
    var permission: Permission = .everyone
    
    //MARK: - Initialization
    
    init(_ name: String, parent: Folder?) {
        self.name = name
        self.parent = parent
    }
}

final class Serialization {
    private init() {}
    public static func save<T>(_ stuff: T, with encoder: JSONEncoder, to url: URL) throws where T: Encodable {
        let data = try encoder.encode(stuff)
        let jsonString = String(data: data, encoding: .utf8)!
        try jsonString.write(to: url, atomically: false, encoding: .utf8)
    }

    public static func load<T>(_ type: T.Type, with decoder: JSONDecoder, from url: URL) throws -> T where T: Decodable {
        let jsonString = try String(contentsOf: url)
        let data = jsonString.data(using: .utf8)!
        return try decoder.decode(type, from: data)
    }
}

public enum FilesystemError: Error {
    case cannotMove(String)
    case cannotDelete(String)
    case cannotCreate(String)
    case cannotRename(String)
}

class Filesystem {
    
    //MARK: - Properties
    
    private(set) public var activities: [UUID:Activity] = [:]
    private(set) public var root: Folder
    private(set) public var current: Folder
    let documentsURL: URL
    let filesystemArchiveURL: URL
    let activitiesArchiveURL: URL
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    let manager = FileManager.default
    var count: Int {
        return current.activities.count + current.folders.count
    }
    static let shared = Filesystem()
    
    //MARK: - Initialization
    
    init() {
        root = Folder("/", parent: nil)
        current = root
        documentsURL = manager.urls(for: .documentDirectory, in: .allDomainsMask).first!
        filesystemArchiveURL = documentsURL.appendingPathComponent("filesystem.json", isDirectory: false)
        activitiesArchiveURL = documentsURL.appendingPathComponent("act", isDirectory: true)
        if !manager.fileExists(atPath: activitiesArchiveURL.path) {
            os_log("Creating activities save directory at %@", activitiesArchiveURL.path)
            try! manager.createDirectory(at: activitiesArchiveURL, withIntermediateDirectories: true, attributes: nil)
        }
        print("Archive URL for this session: \(documentsURL.path)")
    }
    
    //MARK: - Public Methods
    
    //MARK: Serialization
    
    ///This requires that the activities have already been loaded
    func loadStructureFromURLs(_ urls: [URL]) {
        for url in urls {
            let last = url.lastPathComponent
            if let id = UUID(uuidString: last) {
                if let activity = activities[id] {
                    current.activities[activity.name] = activity
                }
            }
            else {
                while url.pathComponents.count <= current.url.pathComponents.count {
                    close()
                }
                try! createFolder(last)
                open(last)
            }
        }
        close(all: true)
    }
    
    func getStructureAsURLs(neglectingPermissions: Bool = true) -> [URL] {
        var urls: [URL] = []
        let action = {(folder: Folder, level: Int) in
            if folder.permission == .everyone || neglectingPermissions {
                if folder.parent != nil { //Make sure not to add the root
                    urls.append(folder.url)
                }
                for activity in folder.orderedActivities {
                    urls.append(folder.url.appendingPathComponent(activity.id.uuidString, isDirectory: false))
                }
            }
        }
        traverseDown(folderAction: action)
        return urls
    }
    
    private func loadActivity(id: UUID) -> Activity? {
        let loadURL = activitiesArchiveURL.appendingPathComponent(id.uuidString, isDirectory: false)
        if let info = try? Serialization.load(ActivityMetaData.self, with: decoder, from: loadURL.appendingPathExtension("info")) {
            let activity = Activity(info: info)
            activity.infoSaved = true
            if let measurements = try? Serialization.load([String:Double].self, with: decoder, from: loadURL.appendingPathExtension("m")) {
                activity.measurements = measurements
                activity.measurementsSaved = true
            }
            if let comments = try? Serialization.load([String:String].self, with: decoder, from: loadURL.appendingPathExtension("c")) {
                activity.comments = comments
                activity.commentsSaved = true
            }
            return activity
        }
        return nil
    }
    
    func loadActivitiesFromArchiveURL() {
        let enumerator = manager.enumerator(at: activitiesArchiveURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants], errorHandler: nil)
        while let url = enumerator?.nextObject() as? URL {
            if let id = url.id, activities[id] == nil {
                activities[id] = loadActivity(id: id)
            }
        }
    }
    
    private func saveActivityPart<T: Encodable>(activity: Activity, part: T, flag: inout Bool, pathExtension: String) {
        if !flag {
            os_log("Saving %@, part %@", activity.name, pathExtension)
            try! Serialization.save(part, with: encoder, to: activitiesArchiveURL.appendingPathComponent(activity.id.uuidString, isDirectory: false).appendingPathExtension(pathExtension))
            flag = true
        }
    }
    
    func saveActivitiesToArchiveURL() {
        for activity in activities.values {
            saveActivityPart(activity: activity, part: activity.info, flag: &activity.infoSaved, pathExtension: "info")
            saveActivityPart(activity: activity, part: activity.measurements, flag: &activity.measurementsSaved, pathExtension: "m")
            saveActivityPart(activity: activity, part: activity.comments, flag: &activity.commentsSaved, pathExtension: "c")
        }
    }
    
    func saveToArchiveURL() {
        let urls = getStructureAsURLs()
        os_log("Saving tree structure to %@", filesystemArchiveURL.path)
        try! Serialization.save(urls, with: encoder, to: filesystemArchiveURL)
        saveActivitiesToArchiveURL()
    }
    
    func loadFromArchiveURL() {
        loadActivitiesFromArchiveURL()
        if let urls = try? Serialization.load([URL].self, with: decoder, from: filesystemArchiveURL) {
            loadStructureFromURLs(urls)
        }
    }
    
    //MARK: Interaction
    
    func traverseDown(folderAction: ((Folder, Int) -> Void), currentFolder: Folder? = nil, level: Int = 0) {
        if let folder = currentFolder {
            for f in folder.orderedFolders {
                folderAction(f, level)
                traverseDown(folderAction: folderAction, currentFolder: f, level: level + 1)
            }
        }
        else {
            folderAction(root, level)
            traverseDown(folderAction: folderAction, currentFolder: root, level: level + 1)
        }
    }
    
    func open(_ folder: String) {
        os_log("Opening folder %@", folder)
        current = current.folders[folder]!
    }
    
    func open(_ url: URL) {
        close(all: true)
        current = getFolder(at: url)
    }
    
    func getFolder(at url: URL) -> Folder {
        var folder = root
        for component in url.pathComponents[1...] {
            folder = folder.folders[component]!
        }
        return folder
    }
    
    func close(all: Bool = false) {
        if all {
            current = root
        }
        else if let parent = current.parent {
            current = parent
        }
    }
    
    func renameActivity(_ activity: Activity, name: String) throws {
        guard !name.isEmpty else {
            throw FilesystemError.cannotRename("Der Name darf nicht leer sein.")
        }
        guard !activities.values.contains(where: {$0.name == activity.name}) else {
            throw FilesystemError.cannotRename("Es gibt bereits eine Aktivität mit dem Namen \"\(name)\".")
        }
        current.activities[activity.name] = nil
        activity.name = name
        current.activities[name] = activity
    }
    
    func createActivity(name: String, measurementMethod: MeasurementMethod, unit: String = "", attachmentType: AttachmentType = .none) throws {
        let info = ActivityMetaData(name: name, unit: unit, id: UUID(), measurementMethod: measurementMethod, attachmentType: attachmentType)
        let activity = Activity(info: info)
        guard !activities.values.contains(where: {$0.name == name}) else {
            throw FilesystemError.cannotCreate("Es gibt bereits eine Aktivität mit dem Namen \"\(name)\".")
        }
        try! manager.createDirectory(at: MediaHandler.shared.getMediaArchiveURL(for: activity), withIntermediateDirectories: true, attributes: nil)
        current.activities[name] = activity
        activities[activity.id] = activity
    }
    
    func deleteActivity(_ name: String) {
        let activity = current.activities[name]!
        current.activities[name] = nil
        activities[activity.id] = nil
        let urlToRemove = url(of: activity)
        try? manager.removeItem(at: urlToRemove.appendingPathExtension("info"))
        try? manager.removeItem(at: urlToRemove.appendingPathExtension("m"))
        try? manager.removeItem(at: urlToRemove.appendingPathExtension("c"))
        try? manager.removeItem(at: MediaHandler.shared.getMediaArchiveURL(for: activity))
    }
    
    func moveActivity(_ activity: Activity, from srcURL: URL, to dstURL: URL) throws {
        let sourceFolder = getFolder(at: srcURL)
        let destinationFolder = getFolder(at: dstURL)
        guard !activities.values.contains(where: { $0.name == activity.name }) else {
            throw FilesystemError.cannotMove("Es gibt bereits eine Aktivität mit dem Namen \"\(activity.name)\".")
        }
        sourceFolder.activities[activity.name] = nil
        destinationFolder.activities[activity.name] = activity
    }
    
    func renameFolder(_ folder: Folder, name: String) throws {
        guard let parent = folder.parent else {
            throw FilesystemError.cannotRename("Die Dateisystembasis kann nicht umbenannt werden.")
        }
        for f in parent.folders {
            if !(f.value === folder) && f.value.name == name {
                throw FilesystemError.cannotRename("\"\(parent.url.path)\" enthält bereits einen Ordner mit dem Namen \"\(name)\"")
            }
        }
        parent.folders[folder.name] = nil
        folder.name = name
        parent.folders[name] = folder
    }
    
    func createFolder(_ name: String) throws  {
        guard !current.folders.keys.contains(name) else {
            throw FilesystemError.cannotCreate("Es gibt bereits einen Ordner mit dem Namen \"\(name)\" in \"\(current.url.path)\".")
        }
        current.folders[name] = Folder(name, parent: current)
    }
    
    func deleteFolder(_ name: String) throws {
        let folder = current.folders[name]!
        guard let parent = folder.parent else {
            throw FilesystemError.cannotDelete("Die Dateisystembasis kann nicht gelöscht werden.")
        }
        for a in folder.activities {
            parent.activities[a.key] = a.value
            folder.activities[a.key] = nil
        }
        for f in folder.folders {
            if parent.folders.keys.contains(f.key) {
                throw FilesystemError.cannotDelete("Es gibt bereits einen Ordner mit dem Namen \"\(f.key)\" in \"\(current.url.path)\".")
            }
            parent.folders[f.key] = f.value
            f.value.parent = parent
        }
        parent.folders[name] = nil
    }
    
    func moveFolder(from srcURL: URL, to dstURL: URL) throws {
        let sourceFolder = getFolder(at: srcURL)
        guard let parent = sourceFolder.parent else {
            throw FilesystemError.cannotMove("Die Dateisystembasis kann nicht verschoben werden.")
        }
        let destinationFolder = getFolder(at: dstURL)
        let srcName = srcURL.lastPathComponent
        if destinationFolder.folders.keys.contains(srcName) {
            throw FilesystemError.cannotMove("Es gibt bereits einen Ordner mit dem Namen \"\(srcName)\" in \"\(current.url.path)\".")
        }
        else if srcURL.contains(dstURL) {
            throw FilesystemError.cannotMove("Das Verschieben des Ordners \"\(srcURL.path)\" in seinen Unterordner \"\(dstURL.path)\" würde eine Endlosschleife verursachen.")
        }
        destinationFolder.folders[srcName] = sourceFolder
        sourceFolder.parent = destinationFolder
        parent.folders[srcName] = nil
    }
    
    func url(of activity: Activity) -> URL {
        return activitiesArchiveURL.appendingPathComponent(activity.id.uuidString, isDirectory: false)
    }
}
