//
//  AuthSessionOutcomeTests.swift
//  VaylTests
//
//  Covers the pure session-check failure classifier: a returning signed-in user
//  who cold-launches offline must NOT be bounced to SignIn. The classifier
//  distinguishes a NETWORK failure (URLError, retryable) from an AUTH failure
//  (revoked/invalid grant — sign out), and treats "no stored session" as sign out.
//

import XCTest
@testable import Vayl

@MainActor
final class AuthSessionOutcomeTests: XCTestCase {

    // MARK: - Network failure WITH a stored session → stay in, retry offline

    func testNotConnectedWithStoredSessionRetriesOffline() {
        let error = URLError(.notConnectedToInternet)
        XCTAssertEqual(
            AuthService.classifyFailure(error, hasStoredSession: true),
            .retryOffline
        )
    }

    func testTimedOutWithStoredSessionRetriesOffline() {
        XCTAssertEqual(
            AuthService.classifyFailure(URLError(.timedOut), hasStoredSession: true),
            .retryOffline
        )
    }

    func testNetworkConnectionLostWithStoredSessionRetriesOffline() {
        XCTAssertEqual(
            AuthService.classifyFailure(URLError(.networkConnectionLost), hasStoredSession: true),
            .retryOffline
        )
    }

    func testCannotConnectToHostWithStoredSessionRetriesOffline() {
        XCTAssertEqual(
            AuthService.classifyFailure(URLError(.cannotConnectToHost), hasStoredSession: true),
            .retryOffline
        )
    }

    // MARK: - Network failure with NO stored session → sign out

    func testNetworkFailureWithoutStoredSessionSignsOut() {
        XCTAssertEqual(
            AuthService.classifyFailure(URLError(.notConnectedToInternet), hasStoredSession: false),
            .signOut
        )
    }

    // MARK: - Auth failure (non-network error) → sign out even with a stored session

    func testAuthFailureWithStoredSessionSignsOut() {
        struct RevokedGrantError: Error {}
        XCTAssertEqual(
            AuthService.classifyFailure(RevokedGrantError(), hasStoredSession: true),
            .signOut
        )
    }

    func testAuthFailureWithoutStoredSessionSignsOut() {
        struct RevokedGrantError: Error {}
        XCTAssertEqual(
            AuthService.classifyFailure(RevokedGrantError(), hasStoredSession: false),
            .signOut
        )
    }

    // MARK: - Sign-in error copy

    func testSignInNetworkErrorShowsConnectionCopy() {
        XCTAssertEqual(
            AuthService.signInErrorMessage(URLError(.notConnectedToInternet)),
            "Couldn't connect. Check your connection and try again."
        )
    }

    func testSignInNonNetworkErrorUsesUnderlyingDescription() {
        struct AuthRejected: LocalizedError {
            var errorDescription: String? { "Sign in was rejected." }
        }
        XCTAssertEqual(
            AuthService.signInErrorMessage(AuthRejected()),
            "Sign in was rejected."
        )
    }
}
