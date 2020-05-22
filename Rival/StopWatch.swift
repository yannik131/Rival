//
//  Timer.swift
//  Rival
//
//  Created by Yannik Schroeder on 22.04.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import Foundation

class StopWatch {
    
    //MARK: - Properties
    
    private(set) public var startStamp: Date?
    private(set) public var elapsedTime: TimeInterval = 0
    
    private(set) public var isRunning: Bool = false {
        didSet {
            if fireAction != nil && isRunning {
                startTimer()
            }
            else if let timer = timer {
                timer.invalidate()
            }
            callback()
        }
    }
    private(set) public var isPaused: Bool = false
    private var timer: Timer! = nil
    public var fireAction: (() -> Void)? = nil
    
    //MARK: - Public methods
    
    public func start() {
        startStamp = Date()
        isRunning = true
        isPaused = false
    }
    
    public func pause() {
        guard isRunning else {
            return
        }
        elapsedTime += diff()
        startStamp = nil
        isRunning = false
        isPaused = true
    }
    
    public func stop() {
        elapsedTime += diff()
        startStamp = nil
        isRunning = false
        isPaused = false
    }
    
    public func clear() {
        elapsedTime = 0
        startStamp = nil
        stop()
    }
    
    public func update() {
        if isRunning {
            elapsedTime += diff()
            startStamp = Date()
        }
    }
    
    //MARK: - Private Methods
    
    private func diff() -> TimeInterval {
        if let start = startStamp {
            return Date().timeIntervalSince1970 - start.timeIntervalSince1970
        }
        return 0
    }
    
    @objc private func callback() {
        if let action = fireAction {
            action()
        }
        else if let timer = timer {
            timer.invalidate()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: TimeInterval(exactly: 0.3)!, target: self, selector: #selector(callback), userInfo: nil, repeats: true)
        timer.tolerance = TimeInterval(exactly: 0.2)!
    }
}

class StopWatchStore {
    private static var stopwatches: [UUID:StopWatch] = [:]
    private init() {}
    static subscript(id: UUID) -> StopWatch! {
        get {
            if StopWatchStore.stopwatches[id] == nil && Filesystem.shared.activities[id]!.measurementMethod == .time {
                StopWatchStore.stopwatches[id] = StopWatch()
            }
            return StopWatchStore.stopwatches[id]
        }
    }
}
