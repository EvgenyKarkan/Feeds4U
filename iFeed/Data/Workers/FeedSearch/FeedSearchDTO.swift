//
//  FeedSearchDTO.swift
//  iFeed
//
//  Created by Evgeny Karkan on 08.04.2023.
//  Copyright © 2023 Evgeny Karkan. All rights reserved.
//

import Foundation

// MARK: - Type definitions
typealias FeedSearchDTO = [FeedSearchElement]

// MARK: - FeedSearchElement
struct FeedSearchElement: Codable {

    // MARK: - Properties
    let description: String?
    let favicon: String?
    let selfURL: String?
    let siteName: String?
    let siteURL: String?
    let title: String?
    let url: String?

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case description
        case favicon
        case selfURL = "self_url"
        case siteName = "site_name"
        case siteURL = "site_url"
        case title
        case url
    }
}
