//
//  Brain.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/4/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

final class Brain {

    // MARK: - Properties
    let parser: Parser
    let coreDater: NewCoreDataManager // CoreDataManager

    // MARK: - Singleton
    static let brain = Brain()

    // MARK: - Init
    init() {
        parser = Parser(storage: NewCoreDataManager.shared)
        coreDater = NewCoreDataManager.shared // CoreDataManager.manager
    }
}
