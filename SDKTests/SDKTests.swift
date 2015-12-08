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
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        print("ok");
        let tmp = "ok";
        XCTAssertEqual("ok", tmp, "ok expected but got " + tmp)
        let authMan = AuthManager()
        //authMan.doIt()
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testGetClientToken() {
        let authMan = AuthManager()
        let expectation = expectationWithDescription("200")

        authMan.getClientToken() {
            (json, err) in
            print("callback received json: \(json) err: \(err)")
            expectation.fulfill()
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





//-------------------------------


    func makeIncrementer(forIncrement amount: Int) -> () -> Int {
        var runningTotal = 0
        func incrementer() -> Int {
            runningTotal += amount
            return runningTotal
        }
        return incrementer
    }




}
