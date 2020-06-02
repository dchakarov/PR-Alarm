//
//  Repository.swift
//  Pull Request Alarm
//
//  Created by Dimitar Chakarov on 02/06/2020.
//  Copyright © 2020 Dimitar Chakarov. All rights reserved.
//

import Foundation

struct Repository: Codable, Identifiable {
    let id: Int32
    let name: String
    let full_name: String
}
