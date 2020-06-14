//
//  Settings.swift
//  Pull Request Alarm
//
//  Created by Dimitar Chakarov on 14/06/2020.
//  Copyright © 2020 Dimitar Chakarov. All rights reserved.
//

import Foundation

struct Settings {
    var org: String? {
        get {
            UserDefaults.standard.string(forKey: "org")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "org")
        }
    }
    var customUrl: String? {
        get {
            UserDefaults.standard.string(forKey: "customUrl")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "customUrl")
        }
    }
}
