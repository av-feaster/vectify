import Foundation

/// Central place for Vectify ↔ GitHub URLs.
enum VectifyGitHubLinks {
    /// Public Vectify repository (no trailing slash).
    static let repositoryRootString = "https://github.com/av-feaster/vectify"

    static let authorProfile = URL(string: "https://github.com/av-feaster")!

    static let repository = URL(string: repositoryRootString)!

    /// Issue list: open items only (`is:issue is:open`).
    static let issuesOpen = URL(string: "\(repositoryRootString)/issues?q=is%3Aopen+is%3Aissue")!

    /// Browse likely feature work: open issues tagged **enhancement** (create the label in GitHub if needed).
    static let issuesFeatureFilter = URL(
        string: "\(repositoryRootString)/issues?q=is%3Aopen+is%3Aissue+label%3Aenhancement"
    )!

    /// New issue composer with **enhancement** label pre-selected.
    static let newFeatureIssue = URL(string: "\(repositoryRootString)/issues/new?labels=enhancement")!

    /// New issue with **bug** label (optional entry point from About).
    static let newBugIssue = URL(string: "\(repositoryRootString)/issues/new?labels=bug")!
}
