//
//  PullRequest.swift
//  Pull Request Alarm
//
//  Created by Dimitar Chakarov on 02/06/2020.
//  Copyright © 2020 Dimitar Chakarov. All rights reserved.
//

import Foundation

struct PullRequestId: Codable {
    let number: Int
}

struct PullRequest: Codable {
    let number: Int
    let id: Int32
    let title: String
    let user: User
    let html_url: URL
    let mergeable: Bool?
    let mergeable_state: String
    var mergeableDisplayValue: String {
        if let mergeable = mergeable {
            if !mergeable { return "🔴" }
            return mergeable_state == "clean" ? "🟢": "🔴"
        } else {
            return "🟠"
        }
    }
}
