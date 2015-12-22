//
//  UserManagerTests.swift
//  SDKTests
//
//  Created by karel herink on 27/11/2015.
//  Copyright © 2015 Paloma Mobile Ltd. All rights reserved.
//

import Alamofire
import Foundation
import XCTest
@testable import SDK

class UserManagerTests: XCTestCase {

    let userManager = UserManager(
        baseUrl: "http://ec2-46-137-242-200.ap-southeast-1.compute.amazonaws.com",
        clientId: "testapp-client",
        clientSecret: "VXaIKFbydKSQlWxqqJXOsH9-63Y="
    )

    override func setUp() {
        do {
            try userManager.clearTokens()
            userManager.user = nil
        } catch {}
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()

    }

    func testGetClientAuthToken() {
        var expectation = expectationWithDescription("fail from cache")
        userManager.getAuthToken(.Client, retrievalMode: .CacheOnly) {
            (token, err) in
            print("callback received client auth token: \(token) err: \(err)")
            XCTAssertNil(token)
            XCTAssertNil(err)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(NSTimeInterval(30.0), handler: nil)


        expectation = expectationWithDescription("success from network")
        userManager.getAuthToken(.Client, retrievalMode: .NetworkOnly) {
            (token, err) in
            print("callback received client auth token: \(token) err: \(err)")
            XCTAssertNotNil(token)
            XCTAssertNil(err)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(NSTimeInterval(30.0), handler: nil)

        expectation = expectationWithDescription("success from cache")
        userManager.getAuthToken(.Client, retrievalMode: .CacheOnly) {
            (token, err) in
            print("callback received client auth token: \(token) err: \(err)")
            XCTAssertNotNil(token)
            XCTAssertNil(err)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(NSTimeInterval(30.0), handler: nil)

        try! userManager.clearClientToken()

        expectation = expectationWithDescription("fail from cache")
        userManager.getAuthToken(.Client, retrievalMode: .CacheOnly) {
            (token, err) in
            print("callback received client auth token: \(token) err: \(err)")
            XCTAssertNil(token)
            XCTAssertNil(err)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(NSTimeInterval(30.0), handler: nil)

        expectation = expectationWithDescription("success from cache then network")
        userManager.getAuthToken(.Client, retrievalMode: .CacheThenNetwork) {
            (token, err) in
            print("callback received client auth token: \(token) err: \(err)")
            XCTAssertNotNil(token)
            XCTAssertNil(err)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(NSTimeInterval(30.0), handler: nil)
    }

    /*
    {
      "username": "JohnSmith10",
      "credential":
      {
        "type": "password",
        "password": "mypassword"
      }
    }
    */
    func testRegisterUser() {
        var expectation = expectationWithDescription("201") //created
        let temp = String(NSDate().timeIntervalSince1970)

        func provideUserCredentials() -> UserCredential {
            var userCredential = UserCredential()
            userCredential.username = temp
            userCredential.credential = [
                "type": "password", "password": "passwordFor\(temp)"
            ]
            return userCredential
        }

        func handleUserRegistration(user: User?, err: ErrorType?) -> Void {
            if let e = err {
                print("err: \(e)")
            }
            if let u = user {
                print("user: id:\(u.id), username=\(u.username), emailAddress:\(u.emailAddress)")
            }
            XCTAssertNil(err)
            XCTAssertNotNil(user)
            expectation.fulfill()
        }

        userManager.userCredentialProvider = provideUserCredentials
        userManager.registerUser(handleUserRegistration)
        waitForExpectationsWithTimeout(NSTimeInterval(30.0), handler: nil)


    }


    func testGetUserAuthToken() {

        var expectation = expectationWithDescription("fail from cache")
        userManager.getAuthToken(.User, retrievalMode: .CacheOnly) {
            (token, err) in
            print("callback received user auth token: \(token) err: \(err)")
            XCTAssertNil(token)
            XCTAssertNil(err)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(NSTimeInterval(30.0), handler: nil)

        let temp = String(NSDate().timeIntervalSince1970)
        if let _ = registerUserUtil(temp, password: temp) {
            expectation = expectationWithDescription("201") //created

            userManager.getAuthToken(.User, retrievalMode: .CacheThenNetwork) {
                (authToken, errorType) in
                XCTAssertNil(errorType)
                XCTAssertNotNil(authToken)
                expectation.fulfill()
            }
            waitForExpectationsWithTimeout(NSTimeInterval(30.0), handler: nil)
            print("client token: \(userManager.clientToken)")
            print("user token: \(userManager.userToken)")
            XCTAssertNotEqual(userManager.clientToken!.access_token, userManager.userToken!.access_token)
        }
        else {
            XCTFail("registerUser() ERROR")
        }

        expectation = expectationWithDescription("success from cache")
        userManager.getAuthToken(.Client, retrievalMode: .CacheOnly) {
            (token, err) in
            print("callback received client auth token: \(token) err: \(err)")
            XCTAssertNotNil(token)
            XCTAssertNil(err)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(NSTimeInterval(30.0), handler: nil)

        try! userManager.clearUserToken()

        expectation = expectationWithDescription("fail from cache")
        userManager.getAuthToken(.User, retrievalMode: .CacheOnly) {
            (token, err) in
            print("callback received user auth token: \(token) err: \(err)")
            XCTAssertNil(token)
            XCTAssertNil(err)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(NSTimeInterval(30.0), handler: nil)
    }

    func testReadUser() {
        let temp = String(NSDate().timeIntervalSince1970)
        if let _ = registerUserUtil(temp, password: temp) {
            let expectation = expectationWithDescription("200") //read
            userManager.readUser() {
                (user, err) in
                print("callback received read user: \(user) err: \(err)")
                if user != nil {
                    expectation.fulfill()
                }
            }
            waitForExpectationsWithTimeout(NSTimeInterval(30.0), handler: nil)
        }
    }

    func testReadUserNoLocalUserError() {
        let expectation = expectationWithDescription("4xx") //read
        userManager.readUser() {
            (user, err) in
            print("callback received read user: \(user) err: \(err)")
            if user != nil {
                XCTFail("Should not have a user here")
            }
            XCTAssertEqual(UserSDKError.UserNotLoggedIn, err as? UserSDKError)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(NSTimeInterval(30.0), handler: nil)
    }

    func registerUserUtil(username: String, password: String) -> User?  {
        userManager.userCredentialProvider = {
            var userCredential = UserCredential()
            userCredential.username = username
            userCredential.credential = [
                    "type": "password", "password": "\(password)"
            ]
            return userCredential
        }
        var userSuccess: User?
        let expectation = expectationWithDescription("201") //created
        userManager.registerUser() {
            (user, err) in
            if let e = err {
                print("err: \(e)")
            }
            if let u = user {
                print("user: id:\(u.id), username=\(u.username), emailAddress:\(u.emailAddress)")
                userSuccess = u
            }
            XCTAssertNil(err)
            XCTAssertNotNil(user)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(NSTimeInterval(30.0), handler: nil)
        return userSuccess
    }

}
