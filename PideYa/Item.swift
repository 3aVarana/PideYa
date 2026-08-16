//
//  Item.swift
//  PideYa
//
//  Created by Victor Arana on 16/8/26.
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
