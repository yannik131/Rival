//
//  Filesystem.swift
//  Rival
//
//  Created by Yannik Schroeder on 27.04.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import Foundation
import UIKit

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
            return parent.url.appendingPathComponent(name)
        }
        return URL(fileURLWithPath: name)
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
    let archiveURL: URL
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
        archiveURL = manager.urls(for: .documentDirectory, in: .allDomainsMask).first!
        filesystemArchiveURL = archiveURL.appendingPathComponent("filesystem.json")
        activitiesArchiveURL = archiveURL.appendingPathComponent("act")
        if !manager.fileExists(atPath: activitiesArchiveURL.path) {
            try! manager.createDirectory(at: activitiesArchiveURL, withIntermediateDirectories: true, attributes: nil)
        }
        print("Archive URL for this session: \(archiveURL.path)")
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
                    urls.append(folder.url.appendingPathComponent(activity.id.uuidString))
                }
            }
        }
        traverseDown(folderAction: action)
        return urls
    }
    
    func loadActivitiesFromArchiveURL() {
        let enumerator = manager.enumerator(at: activitiesArchiveURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants], errorHandler: nil)
        while let url = enumerator?.nextObject() as? URL {
            if let id = url.id {
                if let activity = try? Serialization.load(Activity.self, with: decoder, from: url) {
                    activity.saved = true
                    activities[id] = activity
                }
                else {
                    print("Could not load \(url.path)")
                }
            }
        }
    }
    
    func saveActivitiesToArchiveURL() {
        for activity in activities.values {
            if !activity.saved {
                print("Saving \(activity.name)")
                try! Serialization.save(activity, with: encoder, to: activitiesArchiveURL.appendingPathComponent(activity.id.uuidString))
                activity.saved = true
            }
        }
    }
    
    func saveToArchiveURL() {
        let urls = getStructureAsURLs()
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
        for a in current.activities {
            if !(a.value === activity) && a.value.name == name {
                throw FilesystemError.cannotRename("Es gibt bereits eine Aktivität mit dem Namen \"\(name)\" in \"\(current.url.path)\".")
            }
        }
        current.activities[activity.name] = nil
        activity.name = name
        current.activities[name] = activity
    }
    
    func createActivity(name: String, measurementMethod: Activity.MeasurementMethod, unit: String = "", attachmentType: Activity.AttachmentType = .none) throws {
        let activity = Activity(name: name, measurementMethod: measurementMethod, unit: unit, attachmentType: attachmentType)!
        guard !current.activities.keys.contains(name) else {
            throw FilesystemError.cannotCreate("Es gibt bereits eine Aktivität mit dem Namen \"\(name)\" in \"\(current.url.path)\".")
        }
        try! manager.createDirectory(at: MediaStore.shared.getMediaArchiveURL(for: activity), withIntermediateDirectories: true, attributes: nil)
        current.activities[name] = activity
        activities[activity.id] = activity
    }
    
    func deleteActivity(_ name: String) {
        let activity = current.activities[name]!
        current.activities[name] = nil
        activities[activity.id] = nil
        let urlToRemove = url(of: activity)
        if manager.fileExists(atPath: urlToRemove.path) {
            try! manager.removeItem(at: urlToRemove)
        }
        let url = MediaStore.shared.getMediaArchiveURL(for: activity)
        if manager.fileExists(atPath: url.path) {
            try! manager.removeItem(at: url)
        }
    }
    
    func moveActivity(_ activity: Activity, from srcURL: URL, to dstURL: URL) throws {
        let sourceFolder = getFolder(at: srcURL)
        let destinationFolder = getFolder(at: dstURL)
        guard !destinationFolder.activities.keys.contains(activity.name) else {
            throw FilesystemError.cannotMove("Es gibt bereits eine Aktivität mit dem Namen \"\(activity.name)\" in \"\(destinationFolder.url.path)\"")
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
            if parent.activities.keys.contains(a.key) {
                throw FilesystemError.cannotDelete("Es gibt bereits eine Aktivität mit dem Namen \"\(a.key)\" in \"\(current.url.path)\".")
            }
            parent.activities[a.key] = a.value
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
        return activitiesArchiveURL.appendingPathComponent(activity.id.uuidString)
    }
}
