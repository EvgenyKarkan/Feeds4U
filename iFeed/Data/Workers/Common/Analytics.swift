//
//  Analytics.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/27/16.
//  Copyright © 2016 Evgeny Karkan. All rights reserved.
//

/// GDPR
/// https://www.reddit.com/r/gdpr/comments/9v3bor/comment/e9a35yn/
/// https://firebase.google.com/support/privacy#firebase_support_for_gdpr_and_ccpa
/// https://dev.srdanstanic.com/firebase-crashlytics-analytics-gdpr-user-data-management/ !!!

final class Analytics {

    // MARK: - Singleton
    static let analytics = Analytics()

    // MARK: - APIs
    func startCrashlytics() {
        #if __RELEASE__
        // FirebaseApp.configure()
        #endif
    }
}
