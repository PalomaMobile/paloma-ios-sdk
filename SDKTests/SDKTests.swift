//
//  SDKTests.swift
//  SDKTests
//
//  Created by karel herink on 27/11/2015.
//  Copyright © 2015 Paloma Mobile Ltd. All rights reserved.
//

import Alamofire
import Foundation
import XCTest
@testable import SDK

class SDKTests: XCTestCase {

    let authMan = AuthManager(
        tokenUrl: "http://ec2-46-137-242-200.ap-southeast-1.compute.amazonaws.com/oauth/token",
        clientId: "testapp-client",
        clientSecret: "VXaIKFbydKSQlWxqqJXOsH9-63Y=",
        registerUserUrl: "http://ec2-46-137-242-200.ap-southeast-1.compute.amazonaws.com/users"
    )

    override func setUp() {
        do {
            try authMan.clearTokens()
        } catch {}
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()

    }

    func testGetClientToken() {
        var expectation = expectationWithDescription("fail from cache")
        authMan.getAuthToken(.Client, retrievalMode: .CacheOnly) {
            (token, err) in
            print("callback received client auth token: \(token) err: \(err)")
            XCTAssertNil(token)
            XCTAssertNil(err)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(NSTimeInterval(30.0), handler: nil)


        expectation = expectationWithDescription("success from network")
        authMan.getAuthToken(.Client, retrievalMode: .NetworkOnly) {
            (token, err) in
            print("callback received client auth token: \(token) err: \(err)")
            XCTAssertNotNil(token)
            XCTAssertNil(err)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(NSTimeInterval(30.0), handler: nil)

        expectation = expectationWithDescription("success from cache")
        authMan.getAuthToken(.Client, retrievalMode: .CacheOnly) {
            (token, err) in
            print("callback received client auth token: \(token) err: \(err)")
            XCTAssertNotNil(token)
            XCTAssertNil(err)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(NSTimeInterval(30.0), handler: nil)

        try! authMan.clearClientToken()

        expectation = expectationWithDescription("fail from cache")
        authMan.getAuthToken(.Client, retrievalMode: .CacheOnly) {
            (token, err) in
            print("callback received client auth token: \(token) err: \(err)")
            XCTAssertNil(token)
            XCTAssertNil(err)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(NSTimeInterval(30.0), handler: nil)

        expectation = expectationWithDescription("success from cache then network")
        authMan.getAuthToken(.Client, retrievalMode: .CacheThenNetwork) {
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
        let authMan = AuthManager()
        let expectation = expectationWithDescription("201") //created

        func provideUserCredentials() -> UserCredential {
            let temp = String(NSDate().timeIntervalSince1970)
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

        authMan.userCredentialProvider = provideUserCredentials
        authMan.registerUser(userRegistrationHandler: handleUserRegistration)

        waitForExpectationsWithTimeout(NSTimeInterval(30.0), handler: nil)
    }


    func XXXtestStartRequestWith401() {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = Manager.defaultHTTPHeaders
        let manager = AuthenticationManager(configuration: configuration)

        let expectation = expectationWithDescription("200")

        let successListener : (obj: AnyObject?) -> Void = {
            obj in
            if let o = obj {
                print(o)
            }
            expectation.fulfill()
        }

        let errorListener : (resp: NSHTTPURLResponse?, obj: AnyObject?, err: NSError) -> Void = {
            resp, obj, err in
            print(resp ?? "resp = nil")
            expectation.fulfill()
        }

        let req = manager.startRequest(
                method: .GET,
                URLString: "http://httpbin.org/status/401",
                        parameters: nil,
                        encoding: .JSON,
                        successHandler: successListener,
                        failureHandler: errorListener)
        if let request = req {
            print(request)
        }
        waitForExpectationsWithTimeout(NSTimeInterval(30.0), handler: nil)

    }

    func xxxtestClientTokenRawData() {
        let clientId = "testapp-client"
        let clientSecret = "VXaIKFbydKSQlWxqqJXOsH9-63Y="
        let tokenUrl = "http://ec2-46-137-242-200.ap-southeast-1.compute.amazonaws.com/oauth/token"
        
        let dataValueUtf8: NSData = (clientId + ":" + clientSecret).dataUsingEncoding(NSUTF8StringEncoding)!
        let encodedCreds: String = dataValueUtf8.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.init(rawValue: 0))
        
        var request: NSURLRequest?
        var response: NSHTTPURLResponse?
        var data: NSData?
        var error: NSError?

        let expectation = expectationWithDescription("200")

        Alamofire.upload(
            Method.POST,
            tokenUrl,
            headers: ["Authorization": "Basic \(encodedCreds)"],
            multipartFormData: { multipartFormData in
                multipartFormData.appendBodyPart(data: "client_credentials".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "grant_type")
            },
            encodingCompletion: { result in
                switch result {
                case .Success(let upload, _, _): //succes locally encoding the multipartFormData
                    upload.response { responseRequest, responseResponse, responseData, responseError in
                        request = responseRequest
                        response = responseResponse
                        data = responseData
                        error = responseError
                        expectation.fulfill()
                    }
                case .Failure: //failed to locally encode the multipartFormData
                    print("Failure")
                    expectation.fulfill()
                }
            }
        )
        
        waitForExpectationsWithTimeout(NSTimeInterval(30.0), handler: nil)
        XCTAssertNotNil(request, "request should not be nil")
        XCTAssertNotNil(response, "response should be nil")
        XCTAssertNotNil(data, "data should not be nil")
        XCTAssertNil(error, "error should not be nil")
        
        if let r = response {
            print("Printing RESPONSE:")
            print(r)
        }
        if let d = data {
            let s = String(data: d, encoding: NSUTF8StringEncoding)
            print("Printing DATA:")
            print(s)
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }

}
