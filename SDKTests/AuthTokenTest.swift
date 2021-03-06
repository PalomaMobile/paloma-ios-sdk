//
// Created by karel herink on 16/12/2015.
// Copyright (c) 2015 Paloma Mobile Ltd. All rights reserved.
//

import Foundation
import XCTest
import SwiftyJSON

@testable import SDK

class AuthTokenTest: XCTestCase {

    func testAuthToken() {
        let token: AuthToken = AuthToken(dict: [
                "access_token": "value_access_token",
                "refresh_token" : "value_refresh_token",
                "token_type" : "value_token_type",
                "expires_in" : Int(20000),
                "scope" : "value_scope",
        ])

        let jsonFromToken = token.toJSON()
        print(jsonFromToken)
        XCTAssertNotNil(jsonFromToken, " should not be nil")

        let tokenReinflated = AuthToken(json: jsonFromToken)
        XCTAssertEqual(token, tokenReinflated)
    }

}
