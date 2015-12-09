//
//  AuthManager.swift
//  SDK
//
//  endpoint: http://ec2-46-137-242-200.ap-southeast-1.compute.amazonaws.com
//  path: /oauth/token
//  client id: testapp-client
//  client secret: VXaIKFbydKSQlWxqqJXOsH9-63Y=
//
//  Created by karel herink on 27/11/2015.
//  Copyright © 2015 Paloma Mobile Ltd. All rights reserved.
//

import Foundation
import Alamofire

// Specifies the token retrieval options.
public enum TokenRetrievalMode {

    // Get the token from local cache only. Do not attempt network.
    case CacheOnly

     // Get the token from network only. Ignore any cached value.
    case NetworkOnly

     // First attempt to retrieve token from local cache, if cached token not available then try to retrieve one from network.
     case CacheThenNetwork
}

public class AuthManager {

    let tokenUrl: String
    let clientId: String
    let clientSecret: String

    var clientToken: AuthToken? = nil
    var user: User? = nil


    init(
            tokenUrl tokenUrl: String = "http://ec2-46-137-242-200.ap-southeast-1.compute.amazonaws.com/oauth/token",
            clientId clientId: String = "testapp-client",
            clientSecret clientSecret: String = "VXaIKFbydKSQlWxqqJXOsH9-63Y="
    )
    {
        self.tokenUrl = tokenUrl
        self.clientId = clientId
        self.clientSecret = clientSecret
    }

    public func getClientToken(
            retrievalMode retrievalMode: TokenRetrievalMode = .CacheThenNetwork,
            clientTokenHandler clientTokenHandler: (AuthToken?, ErrorType?) -> Void)
            -> Void {
        getClientToken(clientId: clientId, clientSecret: clientSecret, retrievalMode: retrievalMode, clientTokenHandler: clientTokenHandler)
    }

    public func getClientToken(
            clientId clientId: String,
            clientSecret clientSecret: String,
            retrievalMode retrievalMode: TokenRetrievalMode = .CacheThenNetwork,
            clientTokenHandler clientTokenHandler: (AuthToken?, ErrorType?) -> Void)
            -> Void {

        let creds: NSData = (clientId + ":" + clientSecret).dataUsingEncoding(NSUTF8StringEncoding)!
        let encodedCreds: String = creds.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.init(rawValue: 0))

        switch retrievalMode {
            case .CacheOnly:
                print("getting token from cache only")
                clientTokenHandler(retrieveClientTokenFromCache(), nil)
            case .NetworkOnly:
                print("getting token from network only")
                retrieveClientTokenFromNetwork(encodedCreds: encodedCreds, clientTokenHandler: clientTokenHandler)
            case .CacheThenNetwork:
                print("getting token from cache or network")
                if let token = retrieveClientTokenFromCache() {
                    clientTokenHandler(token, nil)
                }
                else {
                    retrieveClientTokenFromNetwork(encodedCreds: encodedCreds, clientTokenHandler: clientTokenHandler)
                }
        }
    }

    public func retrieveClientTokenFromCache() -> AuthToken? {
        return clientToken
    }

    public func retrieveClientTokenFromNetwork(encodedCreds encodedCreds: String, clientTokenHandler clientTokenHandler: (AuthToken?, ErrorType?) -> Void) {
        Alamofire.upload(
            Method.POST,
            tokenUrl,
            headers: ["Authorization": "Basic \(encodedCreds)"],
            multipartFormData: {
                multipartFormData in
                multipartFormData.appendBodyPart(data: "client_credentials".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "grant_type")
            },
            encodingCompletion: {
                result in
                switch result {
                case .Success(let upload, _, _ ): //success locally encoding the multipartFormData
                    upload
                    .validate()
                    .responseJSON {
                        response in
                        switch response.result {
                            case .Success(let jsonData):
                                print("Success with jsonData: \(jsonData)")
                                let json = JSON(jsonData)
                                self.clientToken = AuthToken(json: json)
                                clientTokenHandler(self.clientToken, nil)
                            case .Failure(let err):
                                print("Error: \(err)")
                                clientTokenHandler(nil, err)
                        }
                    }
                case .Failure(let err):
                    print("Error: \(err)")
                    clientTokenHandler(nil, err)
                }
            }
        )
    }


    public func registerUser(userCredentialProvider: () -> [String: AnyObject], retrievalMode: TokenRetrievalMode = .CacheThenNetwork, userRegistrationHandler userRegistrationHandler: (User?, ErrorType?) -> Void) {
        let registerUserUrl = "http://ec2-46-137-242-200.ap-southeast-1.compute.amazonaws.com/users"
        let userCredentials = userCredentialProvider()

        getClientToken() {
            (clientToken, error) in
            if let token = clientToken {
                let request = Alamofire.request(.POST, registerUserUrl, parameters: userCredentials, encoding: .JSON, headers: ["Authorization" : token.token_type + " " + token.access_token])
                print("Description: " + request.description)
                print("DebugDescription: " + request.debugDescription)
                request
                .validate()
                .responseJSON() {
                    response in switch response.result {
                    case .Success(let jsonData):
                        print("Success with jsonData: \(jsonData)")
                        let json = JSON(jsonData)
                        self.user = User(json: json)
                        userRegistrationHandler(self.user, nil)
                    case .Failure(let err):
                        print("Error: \(err)")
                        userRegistrationHandler(nil, err)
                    }
                }
            }
            else {
                userRegistrationHandler(nil, error)
            }
        }
    }



}
