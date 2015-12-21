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


public typealias AuthTokenHandler = (AuthToken?, ErrorType?) -> Void
public typealias UserCredentialProvider = () -> UserCredential

// Specifies the token retrieval options.
public enum TokenRetrievalMode {

    // Get the token from local cache only. Do not attempt network.
    case CacheOnly

     // Get the token from network only. Ignore any cached value.
    case NetworkOnly

    // First attempt to retrieve token from local cache, if cached token not available then try to retrieve one from network.
    case CacheThenNetwork
}

public enum AuthTokenType: String {

    case Client = "clientToken"

    case User = "userToken"
}

public enum UserRegistrationError: ErrorType {
    case ErrNoUserCredentialProvider
}

@objc
public class AuthManager: NSObject {

    var baseUrl: String

    var tokenUrl: String {
        get { return baseUrl + "/oauth/token"}
    }
    var registerUserUrl: String {
        get { return baseUrl + "/users"}
    }
    var readUserUrl: String {
        get { return baseUrl + "/users/"}
    }

    let secureStoreUserAccoutnName: String
    var user: User? = nil

    var clientId: String
    var clientSecret: String

    var userCredentialProvider: UserCredentialProvider? = nil

    var clientToken: AuthToken? {
        get { return getAuthTokenFromSecureStore(.Client) }
        set { setAuthTokenInSecureStore(.Client, tokenValue: newValue) }
    }

    var userToken: AuthToken? {
        get { return getAuthTokenFromSecureStore(.User) }
        set { setAuthTokenInSecureStore(.User, tokenValue: newValue) }
    }

    private func getAuthTokenFromSecureStore(tokenType: AuthTokenType) -> AuthToken? {
        var dictionary = Locksmith.loadDataForUserAccount(secureStoreUserAccoutnName, inService: tokenType.rawValue)
        if let token = dictionary?[tokenType.rawValue] as? String {
            return AuthToken(json: JSON.parse(token))
        }
        //XXX: implement this: removeSessionHeaderIfExists("Authorization")
        return nil
    }

    private func setAuthTokenInSecureStore(tokenType: AuthTokenType, tokenValue: AuthToken?) {
        if let valueToSave = tokenValue {
            do {
                try Locksmith.saveData([tokenType.rawValue: valueToSave.toJSON().rawString()!], forUserAccount: secureStoreUserAccoutnName, inService: tokenType.rawValue)
                //XXX: implement this: addSessionHeader("Authorization", value: "clientToken \(newValue)")
            }
            catch {
                print("Unable to save \(tokenType.rawValue)")
                do {
                    try Locksmith.deleteDataForUserAccount(secureStoreUserAccoutnName, inService: tokenType.rawValue)
                }
                catch { print("Unable to delete \(tokenType.rawValue)") }
            }
        }
        else { // they set it to nil, so delete it
            do {
                try Locksmith.deleteDataForUserAccount(secureStoreUserAccoutnName, inService: tokenType.rawValue)
                //XXX: implement this: removeSessionHeaderIfExists("Authorization")
            } catch { print("Unable to delete \(tokenType.rawValue)") }
        }
    }

    init(
            baseUrl baseUrl: String = "http://ec2-46-137-242-200.ap-southeast-1.compute.amazonaws.com",
            clientId: String = "testapp-client",
            clientSecret: String = "VXaIKFbydKSQlWxqqJXOsH9-63Y=",
            secureStoreUserAccoutnName: String = "healthmapper"
    )
    {
        self.baseUrl = baseUrl
        self.clientId = clientId
        self.clientSecret = clientSecret
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


    public func getAuthToken(
        tokenType: AuthTokenType,
        retrievalMode: TokenRetrievalMode = .CacheThenNetwork,
        tokenHandler: AuthTokenHandler)
        -> Void {

        switch retrievalMode {
            case .CacheOnly:
                print("getting token from cache only")
                tokenHandler(retrieveAuthTokenFromCache(tokenType), nil)
            case .NetworkOnly:
                print("getting token from network only")
                retrieveAuthTokenFromNetwork(tokenType, tokenHandler: tokenHandler)
            case .CacheThenNetwork:
                print("getting token from cache or network")
                if let token = retrieveAuthTokenFromCache(tokenType) {
                    tokenHandler(token, nil)
                }
                else {
                    retrieveAuthTokenFromNetwork(tokenType, tokenHandler: tokenHandler)
                }
        }
    }

    public func retrieveAuthTokenFromCache(tokenType: AuthTokenType) -> AuthToken? {
        switch tokenType {
            case .Client: return clientToken
            case .User: return userToken
        }
    }

    public func retrieveAuthTokenFromNetwork(
            tokenType: AuthTokenType,
            tokenTimeOutSecs: Int? = nil,
            tokenHandler: AuthTokenHandler)
            -> Void
    {
        let creds: NSData = (clientId + ":" + clientSecret).dataUsingEncoding(NSUTF8StringEncoding)!
        let encodedCreds: String = creds.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.init(rawValue: 0))

        Alamofire.upload(
            Method.POST,
            tokenUrl,
            headers: ["Authorization": "Basic \(encodedCreds)"],
            multipartFormData: {
                multipartFormData in
                if let forceTokenTimeoutSecs = tokenTimeOutSecs {
                    multipartFormData.appendBodyPart(data: String(forceTokenTimeoutSecs).dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "token_timeout")
                }
                switch tokenType {
                    case .Client:
                        multipartFormData.appendBodyPart(data: "client_credentials".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "grant_type")
                    case .User:
                        if let provider = self.userCredentialProvider {
                            var userCredentials = provider()
                            print("get user token for: userCredentials.username: \(userCredentials.username!), userCredentials.password: \(userCredentials.password!)")
                            multipartFormData.appendBodyPart(data: userCredentials.username!.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "username")
                            multipartFormData.appendBodyPart(data: userCredentials.password!.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "password")
                            multipartFormData.appendBodyPart(data: "password".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "credential_type")
                            multipartFormData.appendBodyPart(data: "password".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "grant_type")
                            debugPrint(multipartFormData)
                        }
                }
            },
            encodingCompletion: {
                result in
                switch result {
                case .Success(let uploadRequest, _, _ ): //success locally encoding the multipartFormData
                    debugPrint(uploadRequest)
                    uploadRequest
                    .validate()
                    .responseJSON {
                        response in
                        switch response.result {
                            case .Success(let jsonData):
                                print("Success with jsonData: \(jsonData)")
                                let json = JSON(jsonData)
                                let token = AuthToken(json: json)
                                switch tokenType {
                                case .Client:
                                    self.clientToken = token
                                case .User:
                                    self.userToken = token
                                }
                                tokenHandler(token, nil)
                            case .Failure(let err):
                                print("Error with jsonData: \(err)")
                                tokenHandler(nil, err)
                        }
                    }
                case .Failure(let err):
                    print("Error on encodingCompletion: \(err)")
                    tokenHandler(nil, err)
                }
            }
        )
    }


    public func registerUser(retrievalMode: TokenRetrievalMode = .CacheThenNetwork, userRegistrationHandler userRegistrationHandler: (User?, ErrorType?) -> Void) {

        if let provider = self.userCredentialProvider {

            var userCredentials = provider()

            getAuthToken(.Client) {
                (clientToken, error) in
                if let token = clientToken {
                    let request = Alamofire.request(.POST, self.registerUserUrl, parameters: userCredentials.toDictionary(), encoding: .JSON, headers: ["Authorization" : token.token_type + " " + token.access_token])
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
        else {
            userRegistrationHandler(nil, UserRegistrationError.ErrNoUserCredentialProvider)
            return
        }

    }


    func tokenExpiredError(){}

}
