//
//  MergeResponse.swift
//  Pull Request Alarm
//
//  Created by Dimitar Chakarov on 19/06/2020.
//  Copyright © 2020 Dimitar Chakarov. All rights reserved.
//

import Foundation

struct MergeResponse: Codable {
    let sha: String
    let merged: Bool
    let message: String
}
