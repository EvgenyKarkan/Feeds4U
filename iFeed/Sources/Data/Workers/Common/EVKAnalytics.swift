//
//  EVKAnalytics.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/27/16.
//  Copyright © 2016 Evgeny Karkan. All rights reserved.
//

import Foundation

class EVKAnalytics: NSObject {

    // MARK: - Singleton
    static let analytics = EVKAnalytics()
    
    // MARK: - APIs
    func startCrashlytics() {
        #if __RELEASE__
            //Fabric.with([Crashlytics.self])

        // FirebaseApp.configure()
        #endif
    }
}
