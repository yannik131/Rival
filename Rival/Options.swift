//
//  Options.swift
//  Rival
//
//  Created by Yannik Schroeder on 24.06.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import Foundation

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
    
    public static let archiveURL = Filesystem.shared.documentsURL.appendingPathComponent("options.json", isDirectory: false)
    
    private init() {
        plotType = .line
        granularity = .day
        plotTitleState = .sum
        periodTemplate = .last7Days
    }
    
    static func getInstance() -> Options {
        if Options.instance == nil {
            do {
                Options.instance = try Serialization.load(Options.self, with: Filesystem.shared.decoder, from: Options.archiveURL)
            }
            catch {
                Options.instance = Options()
                Options.instance!.save()
            }
        }
        return Options.instance!
    }
    
    func save() {
        try! Serialization.save(self, with: Filesystem.shared.encoder, to: Options.archiveURL)
    }
    
    //MARK: - Plot
    
    var plotType: PlotType
    var granularity: Calendar.Component
    var ignoreZeros: Bool = true
    var plotTitleState: PlotTitleState
    var startDate: Date!
    var endDate: Date!
    var periodTemplate: PeriodTemplate!
    var activityID: UUID!
    var folderURL: URL!
}
