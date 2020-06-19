//
//  AlarmDaemon.swift
//  Pull Request Alarm
//
//  Created by Dimitar Chakarov on 18/06/2020.
//  Copyright © 2020 Dimitar Chakarov. All rights reserved.
//

import Foundation
import Combine

class AlarmDaemon {
    var cancellable: AnyCancellable?

    func start(using helper: RepositoryHelper) {
        cancellable?.cancel()
        helper.poll()
        cancellable = Timer.publish(every: 30, tolerance: 1, on: .main, in: .common).autoconnect()
            .sink { _ in
                helper.poll()
        }
    }
}
