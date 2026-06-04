https://rss.com/blog/popular-rss-feeds/

1. ❌ SwiftLint only for changed files
    https://github.com/realm/SwiftLint/issues/413
    https://github.com/steven851007/SwiftLint_build_phase_example?tab=readme-ov-file#project-setup
    https://stackoverflow.com/questions/55963836/how-to-run-swiftlint-for-git-diff-files-only
    https://github.com/realm/SwiftLint/issues/4015
    https://developer.apple.com/documentation/Xcode/improving-the-speed-of-incremental-builds
    https://gist.github.com/mcany/eb392a05d00cbefad1f7d9a17d40c3b9
    https://gist.github.com/drrost/f01bce9ccf644c6f9669082097a76421
    https://needone.app/swiftlint/#google_vignette
    pre-commit hook https://tech.autoscout24.com/blog/posts/xcode-build-time-optimization/

     - Before
        if [ "${CONFIGURATION}" == "Debug" ]; then
            // Apple Silicon support
            if [[ "$(uname -m)" == arm64 ]]; then
                export PATH="/opt/homebrew/bin:$PATH"
            fi

            if which swiftlint > /dev/null; then
                swiftlint
            else
                echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
            fi
        else
            echo "warning: SwiftLint is disabled for current ${CONFIGURATION} configuration"
        fi


    - After

        It gives error - Error: No lintable files found at paths: 'iFeed/UI/Base/BaseTableProvider.swift'

        if [ "${CONFIGURATION}" == "Debug" ]; then

            SWIFT_LINT=/usr/local/bin/swiftlint

            # Apple Silicon support
            if [[ "$(uname -m)" == arm64 ]]; then
                SWIFT_LINT=/opt/homebrew/bin/swiftlint
            fi

            # Run SwiftLint for a given filename
            run_swiftlint() {
                local fullFileName="${1}"             # /.../.../SomeClass.swift
                local fileName="${fullFileName##*/}"  # SomeClass.swift

                if [[ "${fileName##*.}" == "swift" ]]; then
                    echo "✅ Linting ${fileName}"
                    ${SWIFT_LINT} lint "${fullFileName}"
                else
                    echo "❌ Skipping ${fileName}, not a valid Swift file or does not exist."
                fi
            }

            if [[ -e "${SWIFT_LINT}" ]]; then
                echo "⚠️ SwiftLint version: $(${SWIFT_LINT} version), "${SWIFT_LINT}""
                # Run for both staged and unstaged files
                git diff --name-only | while read -r fileName; do run_swiftlint "${fileName}"; done
                git diff --cached --name-only | while read -r fileName; do run_swiftlint "${fileName}"; done

            else
                echo "❌ ${SWIFT_LINT} is not installed."
                exit 0
            fi
        else
            echo "❌ warning: SwiftLint is disabled for current ${CONFIGURATION} configuration"
        fi


3. ✅ Licenses in Settings, package plus search API

    - https://gist.github.com/zetachang/4111314

    ✅ Settings Bundle
    ✅ https://github.com/nmdias/FeedKit/blob/master/LICENSE
    ✅ https://github.com/JuliusBahr/SimpleSimilarity/blob/master/LICENSE

    ✅ https://github.com/krimpedance/KRProgressHUD/blob/master/LICENSE
    ✅ https://github.com/krimpedance/KRActivityIndicatorView/blob/master/LICENSE

    ✅ https://github.com/DBeath/feedsearch/blob/master/LICENSE
    ✅ https://github.com/DBeath/feedsearch-crawler/blob/master/LICENSE

    ✅ https://feedsearch.dev

    ✅ https://github.com/fetch-rewards/swift-mocking


5. ❌ Automate with CI/CD

    BITRISE
    - https://devcenter.bitrise.io/en/getting-started.html
    - https://medium.com/@ajayrbhanushali/bitrise-ci-cd-for-ios-apps-8b2c44c4a555
    - https://www.runway.team/blog/how-to-set-up-a-ci-cd-pipeline-ios-app-using-bitrise
    - https://codewithchris.com/bitrise-ios/
    - https://www.linkedin.com/pulse/25-bitrise-integration-steps-you-should-know-ios-apps-moataz-nabil/
    - https://medium.com/ne-digital/ios-build-test-and-deliver-using-bitrise-part-1-build-d210b8e60a2d
    - https://medium.com/ne-digital/ios-build-test-and-deliver-using-bitrise-part-2-test-94c7bc56adc3
    - https://docs.fastlane.tools/best-practices/continuous-integration/bitrise/ - Integrating Fastlane into Bitrise

    - increment build number
    - if branch is dev then execute tests, no need to generate build
    - if branch is release then test plus build ipa (ad-hoc, release)


    /// Firebase GDPR
    /// https://www.reddit.com/r/gdpr/comments/9v3bor/comment/e9a35yn/
    /// https://firebase.google.com/support/privacy#firebase_support_for_gdpr_and_ccpa
    /// https://dev.srdanstanic.com/firebase-crashlytics-analytics-gdpr-user-data-management/ !!!


    /// https://gitdiagram.com


6. Folders
    - chevron on right
    - test long folder name

7. Prewarm in Safari only those items that have no long HTML
