//
//  AuthManager.swift
//  SDK
//
//  Created by karel herink on 27/11/2015.
//  Copyright © 2015 Paloma Mobile Ltd. All rights reserved.
//

import Foundation
import Alamofire

public class AuthManager {

    

    /*
    //endpoint: http://ec2-46-137-242-200.ap-southeast-1.compute.amazonaws.com
    //path: /oauth/token
    //client id: testapp-client
    //client secret: VXaIKFbydKSQlWxqqJXOsH9-63Y=
    */

    
    public func getClientToken(clientTokenHandler clientTokenHandler: (JSON?, ErrorType?) -> Void) {
        let clientId = "testapp-client"
        let clientSecret = "VXaIKFbydKSQlWxqqJXOsH9-63Y="
        let tokenUrl = "http://ec2-46-137-242-200.ap-southeast-1.compute.amazonaws.com/oauth/token"
        
        let creds: NSData = (clientId + ":" + clientSecret).dataUsingEncoding(NSUTF8StringEncoding)!
        let encodedCreds: String = creds.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.init(rawValue: 0))
        
        Alamofire.upload(
            Method.POST,
            tokenUrl,
            headers: ["Authorization": "Basic \(encodedCreds)"],
            multipartFormData: { multipartFormData in
                multipartFormData.appendBodyPart(data: "client_credentials".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "grant_type")
            },
            encodingCompletion: { result in
                switch result {
                case .Success(let upload, _, _): //success locally encoding the multipartFormData
                    upload.responseJSON {
                        response in switch response.result {
                        case .Success(let jsonData):
                            print("Success with jsonData: \(jsonData)")
                            let json = JSON(jsonData)
                            clientTokenHandler(json, nil)
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
        // Minimal Alamofire implementation. For more info see https://github.com/Alamofire/Alamofire#crud--authorization
//        Alamofire.Manager.
    }

    
}
