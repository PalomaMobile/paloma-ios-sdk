//
// Created by karel herink on 16/12/2015.
// Copyright (c) 2015 Paloma Mobile Ltd. All rights reserved.
//

import Foundation
import XCTest
@testable import SDK

class AuthTokenTest: XCTestCase {

    func testAuthToken() {
//        let authMan = AuthManager()
//        let expectation = expectationWithDescription("200")
//        let clientId = "testapp-client"
//        let clientSecret = "VXaIKFbydKSQlWxqqJXOsH9-63Y="
//
//        authMan.getClientToken(clientId: clientId, clientSecret: clientSecret) {
//            (token, err) in
//            print("callback received json: \(token) err: \(err)")
//            expectation.fulfill()
//        }
//        waitForExpectationsWithTimeout(NSTimeInterval(30.0), handler: nil)


    /*
    var access_token: String = ""
    var refresh_token: String? = nil
    var token_type: String = ""
    var expires_in: Int = 0
    var scope: String = ""
    */

        let token: AuthToken = AuthToken(dict: [
                "access_token": "value_access_token",
                "refresh_token" : "value_refresh_token",
                "token_type" : "value_token_type",
                "expires_in" : Int(20000),
                "scope" : "value_scope",
        ])

        var jsonStr = token.toJSON().rawString()
        print(jsonStr)
        XCTAssertNotNil(jsonStr, "at should not be nil")

    }

}
