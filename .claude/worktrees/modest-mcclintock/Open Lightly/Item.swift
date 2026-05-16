//
//  Item.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/7/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
