//
// Created by karel herink on 18/12/2015.
// Copyright (c) 2015 Paloma Mobile Ltd. All rights reserved.
//

import Foundation

public struct UserCredential {

    var emailAddress: String? = nil
    var verificationCode: String? = nil
    var username: String? = nil
    var password: String? {
        get {
            return credential["password"]
        }
        set {
            credential["password"] = newValue
        }
    }
    var credential = [String:String]()

    func toDictionary() -> [String: AnyObject] {
        var dict = [String:AnyObject]()
        dict["emailAddress"] = emailAddress
        dict["verificationCode"] = verificationCode
        dict["username"] = username
        dict["credential"] = credential
        return dict
    }
}
