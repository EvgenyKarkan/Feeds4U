//
//  EntityCreatable.swift
//  iFeed
//
//  Created by Evgeny Karkan on 26.03.2024.
//  Copyright © 2024 Evgeny Karkan. All rights reserved.
//

import Foundation
import CoreData.NSManagedObject

protocol EntityCreatable {
    func createFeedEntity() -> NSManagedObject?
    func createFeedItemEntity() -> NSManagedObject?
}
