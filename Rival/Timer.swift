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
    
    private var startStamp: DispatchTime?
    private var elapsedTime = 0
    
    private(set) public var isRunning: Bool = false
    private(set) public var isPaused: Bool = false
    public static var nanosecondsMode: Bool = false
    
    init() {
        print("Timer init!")
    }
    
    //MARK: - Public methods
    
    public func start() {
        self.startStamp = DispatchTime.now()
        if self.isRunning || (!self.isRunning && !self.isPaused) {
            self.elapsedTime = 0
        }
        self.isRunning = true
        self.isPaused = false
    }
    
    public func pause() {
        if self.isRunning {
            self.elapsedTime += self.diff(start: self.startStamp!, end: DispatchTime.now())
            self.isRunning = false
            self.isPaused = true
        }
    }
    
    public func stop() -> Int? {
        if self.isRunning {
            self.isRunning = false
            return diff(start: self.startStamp!, end: DispatchTime.now()) + self.elapsedTime
        }
        else if self.isPaused {
            self.isPaused = false
            return self.elapsedTime
        }
        return nil
    }
    
    public func clear() {
        self.startStamp = nil
        self.isRunning = false
        self.isPaused = false
    }
    
    //MARK: - Private Methods
    
    private func diff(start: DispatchTime, end: DispatchTime) -> Int {
        let dt = Double(end.uptimeNanoseconds - start.uptimeNanoseconds)
        if StopWatch.nanosecondsMode {
            return Int(dt)
        }
        return Int((dt/1000000000.0).rounded())
    }
}

class TimerStore {
    private static var timers: [UUID:StopWatch] = [:]
    private init() {}
    static subscript(id: UUID) -> StopWatch {
        get {
            if TimerStore.timers[id] == nil {
                TimerStore.timers[id] = StopWatch()
            }
            return TimerStore.timers[id]!
        }
    }
}
