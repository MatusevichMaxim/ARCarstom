//
//  WatchDog.swift
//  CarstomApp
//
//  Created by Максим Матусевич on 8/11/19.
//  Copyright © 2019 Максим Матусевич. All rights reserved.
//

import Foundation

struct WatchDog {
    
    // MARK:- Properties
    
    private let created = Date()
    
    private let label: String
    
    // MARK:- Lifecycle
    
    init(named label: String = "") {
        self.label = label
    }
    
    // MARK:- API
    
    mutating func logEnter() {
        print("WatchDog[\(label)] created at: \(created)")
    }
    
    mutating func logDuration(withDescription description: String = "") {
        let diff = Date().timeIntervalSince(created)
        print("WatchDog[\(label)] \(description) lived \(diff) seconds")
    }
    
    mutating func logExit() {
        print("WatchDog[\(label)] destructed at: \(Date())")
    }
    
}
