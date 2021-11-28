//
//  Options.swift
//  Rival
//
//  Created by Yannik Schroeder on 24.06.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import Foundation
import CryptoKit
import os.log
import CoreLocation

class SerializableSingleton: Codable {
    private static var instance: SerializableSingleton?
    private(set) public var saved: Bool = false
    class var name: String! {
        return nil
    }
    class var archiveURL: URL! {
        return nil
    }
    
    static func getInstance() -> SerializableSingleton {
        if SerializableSingleton.instance == nil {
            do {
                SerializableSingleton.instance = try Serialization.load(SerializableSingleton.self, with: Filesystem.shared.decoder, from: SerializableSingleton.archiveURL)
            }
            catch {
                os_log("Error loading SerializableSingleton: %@", error.localizedDescription)
                SerializableSingleton.instance = SerializableSingleton()
                SerializableSingleton.instance!.save()
            }
        }
        return SerializableSingleton.instance!
    }
    
    func save() {
        if !saved {
            os_log("Saving settings")
            try! Serialization.save(self, to: SerializableSingleton.archiveURL)
            saved = true
        }
    }
}

enum PlotTitleState: String, CaseIterable, Codable {
    case sum = "Summe"
    case median = "Median"
    case average = "Durchschnitt"
    case min = "Minimum"
    case max = "Maximum"
}

enum PlotType: String, CaseIterable, Codable {
    case bar = "Balken"
    case line = "Linie"
    case pie = "Torte"
}

enum PeriodTemplate: String, CaseIterable, Codable {
    case last7Days = "Letzte 7 Tage"
    case thisWeek = "Diese Woche"
    case lastWeek = "Letzte Woche"
    case thisMonth = "Dieser Monat"
    case lastMonth = "Letzter Monat"
    case thisYear = "Dieses Jahr"
    case lastYear = "Letztes Jahr"
    case custom = "Manuell"
}

extension Calendar.Component: Codable {
    enum CodingKeys: String, CodingKey {
        case Component
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let str = try values.decode(String.self, forKey: .Component)
        switch(str) {
        case "day":
            self = .day
        case "weekOfYear":
            self = .weekOfYear
        case "month":
            self = .month
        case "year":
            self = .year
        default:
            fatalError()
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let str = String(describing: self)
        try container.encode(str, forKey: .Component)
    }
}

final class Options: Codable {
    private static var instance: Options?
    var saved: Bool = false
    
    //MARK: - Plot
    
    var plotType: PlotType!
    var granularity: Calendar.Component!
    var ignoreZeros: Bool!
    var plotTitleState: PlotTitleState!
    var startDate: Date!
    var endDate: Date!
    var periodTemplate: PeriodTemplate!
    var activityID: UUID!
    var folderURL: URL!
    
    
    public static let archiveURL = Filesystem.shared.documentsURL.appendingPathComponent("options.json", isDirectory: false)
    
    private init() {
        
    }
    
    private func loadDefaults() {
        setDefault(&plotType, .line)
        setDefault(&granularity, .day)
        setDefault(&plotTitleState, .sum)
        setDefault(&periodTemplate, .last7Days)
        setDefault(&ignoreZeros, true)
    }
    
    private func setDefault<T>(_ variable: inout T!, _ value: T!, overwrite: Bool = false) {
        if variable == nil || overwrite {
            variable = value
            saved = false
        }
    }
    
    func change<T>(_ variable: inout T!, _ handler: ((inout T) -> Void)) {
        handler(&variable)
        saved = false
    }
    
    func set<T>(_ variable: inout T!, _ value: T!) {
        variable = value
        saved = false
    }
    
    static func hash(_ string: String) -> String {
        return SHA256.hash(data: string.appending("This is my own cool extra stuff!").data(using: .utf8)!).description
    }
    
    static func getInstance() -> Options {
        if Options.instance == nil {
            do {
                Options.instance = try Serialization.load(Options.self, with: Filesystem.shared.decoder, from: Options.archiveURL)
                os_log("Loaded options from file")
            }
            catch {
                os_log("Error loading options: %@", error.localizedDescription)
                Options.instance = Options()
                Options.instance!.save()
            }
            Options.instance!.loadDefaults()
        }
        return Options.instance!
    }
    
    func save() {
        if !saved {
            os_log("Saving settings")
            try! Serialization.save(self, with: Filesystem.shared.encoder, to: Options.archiveURL)
            saved = true
        }
    }
}
