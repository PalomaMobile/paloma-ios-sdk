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
import Locksmith

// Specifies the token retrieval options.
public enum TokenRetrievalMode {

    // Get the token from local cache only. Do not attempt network.
    case CacheOnly

     // Get the token from network only. Ignore any cached value.
    case NetworkOnly

     // First attempt to retrieve token from local cache, if cached token not available then try to retrieve one from network.
     case CacheThenNetwork
}

@objc
public class AuthManager: NSObject {

    let tokenUrl: String
    let clientId: String
    let clientSecret: String
    let registerUserUrl: String
    let secureStoreUserAccoutnName: String
    var user: User? = nil

    var clientToken: AuthToken? {
        get {
            return getAuthTokenFromSecureStore("clientToken")
        }
        set {
            setAuthTokenInSecureStore("clientToken", tokenValue: newValue);
        }
    }

    var userToken: AuthToken? {
        get {
            return getAuthTokenFromSecureStore("userToken")
        }
        set {
            setAuthTokenInSecureStore("userToken", tokenValue: newValue);
        }
    }

    private func getAuthTokenFromSecureStore(tokenName: String) -> AuthToken? {
        var dictionary = Locksmith.loadDataForUserAccount(secureStoreUserAccoutnName, inService: tokenName)
        if let token = dictionary?[tokenName] as? String {
            return AuthToken(json: JSON.parse(token))
        }
        //XXX: implement this: removeSessionHeaderIfExists("Authorization")
        return nil
    }

    private func setAuthTokenInSecureStore(tokenName: String, tokenValue: AuthToken?) {
        if let valueToSave = tokenValue {
            do {
                try Locksmith.saveData([tokenName: valueToSave.toJSON().rawString()!], forUserAccount: secureStoreUserAccoutnName, inService: tokenName)
                //XXX: implement this: addSessionHeader("Authorization", value: "clientToken \(newValue)")
            }
            catch {
                print("Unable to save \(tokenName)")
                do {
                    try Locksmith.deleteDataForUserAccount(secureStoreUserAccoutnName, inService: tokenName)
                }
                catch { print("Unable to delete \(tokenName)") }
            }
        }
        else { // they set it to nil, so delete it
            do {
                try Locksmith.deleteDataForUserAccount(secureStoreUserAccoutnName, inService: tokenName)
                //XXX: implement this: removeSessionHeaderIfExists("Authorization")
            } catch { print("Unable to delete \(tokenName)") }
        }
    }

    init(
            tokenUrl tokenUrl: String = "http://ec2-46-137-242-200.ap-southeast-1.compute.amazonaws.com/oauth/token",
            clientId clientId: String = "testapp-client",
            clientSecret clientSecret: String = "VXaIKFbydKSQlWxqqJXOsH9-63Y=",
            registerUserUrl registerUserUrl: String = "http://ec2-46-137-242-200.ap-southeast-1.compute.amazonaws.com/users",
            secureStoreUserAccoutnName secureStoreUserAccoutnName: String = "healthmapper"
    )
    {
        self.tokenUrl = tokenUrl
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.registerUserUrl = registerUserUrl
        self.secureStoreUserAccoutnName = secureStoreUserAccoutnName
    }

    public func clearClientToken() throws {
        clientToken = nil
    }
    public func clearUserToken() throws {
        userToken = nil
    }
    public func clearTokens() throws {
        try clearClientToken()
        try clearUserToken()
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

    public func retrieveClientTokenFromNetwork(
            encodedCreds encodedCreds: String,
            tokenTimeOutSecs tokenTimeOutSecs: Int? = nil,
            clientTokenHandler clientTokenHandler: (AuthToken?, ErrorType?) -> Void)
            -> Void
    {
        Alamofire.upload(
            Method.POST,
            tokenUrl,
            headers: ["Authorization": "Basic \(encodedCreds)"],
            multipartFormData: {
                multipartFormData in
                multipartFormData.appendBodyPart(data: "client_credentials".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "grant_type")
                if let forceTokenTimeoutSecs = tokenTimeOutSecs {
                    multipartFormData.appendBodyPart(data: String(forceTokenTimeoutSecs).dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "token_timeout")
                }
            },
            encodingCompletion: {
                result in
                switch result {
                case .Success(let uploadRequest, _, _ ): //success locally encoding the multipartFormData
                    uploadRequest
                    .validate()
                    .responseJSON {
                        response in
                        switch response.result {
                            case .Success(let jsonData):
                                print("Success with jsonData: \(jsonData)")
                                let json = JSON(jsonData)
                                let token = AuthToken(json: json)
                                self.clientToken = token
                                clientTokenHandler(token, nil)
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
        let userCredentials = userCredentialProvider()

        getClientToken() {
            (clientToken, error) in
            if let token = clientToken {
                let request = Alamofire.request(.POST, self.registerUserUrl, parameters: userCredentials, encoding: .JSON, headers: ["Authorization" : token.token_type + " " + token.access_token])
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

    //XXX Finish this once retrieveClientTokenFromNetwork() is refactored into a generic retrieveAuthTokenFromNetwork()
    public func getUserTokenFromNetwork(
            userCredentialProvider: () -> [String: AnyObject],
            retrievalMode: TokenRetrievalMode = .CacheThenNetwork,
            userTokenHandler userTokenHandler: (AuthToken?, ErrorType?) -> Void) {
        let userCredentials = userCredentialProvider()

        getClientToken() {
            (clientToken, error) in
            if let token = clientToken {

/*

curl
curl -X POST -vu ${CLIENT_ID}:${CLIENT_SECRET} http://${USER_HOST}/oauth/token -H "Accept: application/json" -d "grant_type=client_credentials"

request
POST /oauth/token HTTP/1.1
Authorization: Basic Y2xpZW50YXBwOjEyMzQ1Ng==
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials

-------

curl
curl -X POST -u ${CLIENT_ID}:${CLIENT_SECRET} http://${USER_HOST}/oauth/token -H "Accept: application/json" -d "password=${FACEBOOK_TOKEN}&username=JohnSmith10&grant_type=password&credential_type=facebook"

request
POST /oauth/token HTTP/1.1
Authorization: Basic Y2xpZW50YXBwOjEyMzQ1Ng==
Content-Type: application/x-www-form-urlencoded

username=JohnSmith10&
passsword=<facebook-access-token>&
credential_type=facebook&
grant_type=password

*/
            }
        }
    }


    func tokenExpiredError(){}


//    public func getUserToken(
//            clientId clientId: String,
//            clientSecret clientSecret: String,
//            retrievalMode retrievalMode: TokenRetrievalMode = .CacheThenNetwork,
//            userTokenHandler userTokenHandler: (AuthToken?, ErrorType?) -> Void)
//                    -> Void {
//
//        let creds: NSData = (clientId + ":" + clientSecret).dataUsingEncoding(NSUTF8StringEncoding)!
//        let encodedCreds: String = creds.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.init(rawValue: 0))
//
//        switch retrievalMode {
//        case .CacheOnly:
//            print("getting token from cache only")
//            userTokenHandler(retrieveUserTokenFromCache(), nil)
//        case .NetworkOnly:
//            print("getting token from network only")
//            retrieveUserTokenFromNetwork(encodedCreds: encodedCreds, userTokenHandler: userTokenHandler)
//        case .CacheThenNetwork:
//            print("getting token from cache or network")
//            if let token = retrieveUserTokenFromCache() {
//                userTokenHandler(token, nil)
//            }
//            else {
//                retrieveUserTokenFromNetwork(encodedCreds: encodedCreds, userTokenHandler: userTokenHandler)
//            }
//        }
//    }
//
//    public func retrieveUserTokenFromCache() -> AuthToken? {
//        return userToken
//    }
//
//    public func retrieveUserTokenFromNetwork(encodedCreds encodedCreds: String, userTokenHandler userTokenHandler: (AuthToken?, ErrorType?) -> Void) {}
//        Alamofire.upload(
//            Method.POST,
//            tokenUrl,
//            headers: ["Authorization": "Basic \(encodedCreds)"],
//            multipartFormData: {
//                multipartFormData in
//                  NEED TO BUILD UP THIS
//                //multipartFormData.appendBodyPart(data: "client_credentials".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "grant_type")
//            },
//            encodingCompletion: {
//                result in
//                switch result {
//                case .Success(let upload, _, _ ): //success locally encoding the multipartFormData
//                    upload
//                    .validate()
//                    .responseJSON {
//                        response in
//                        switch response.result {
//                        case .Success(let jsonData):
//                            print("Success with jsonData: \(jsonData)")
//                            let json = JSON(jsonData)
//                            self.userToken = AuthToken(json: json)
//                            userTokenHandler(self.userToken, nil)
//                        case .Failure(let err):
//                            print("Error: \(err)")
//                            userTokenHandler(nil, err)
//                        }
//                    }
//                case .Failure(let err):
//                    print("Error: \(err)")
//                    userTokenHandler(nil, err)
//                }
//            }
//        )
//    }



}
