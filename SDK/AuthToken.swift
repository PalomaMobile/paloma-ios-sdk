//
//  AuthToken.swift
//  SDK
//
//  Created by karel herink on 7/12/2015.
//  Copyright © 2015 Paloma Mobile Ltd. All rights reserved.
//

import Foundation

public struct AuthToken {

    var access_token: String = ""
    var refresh_token: String? = nil
    var token_type: String = ""
    var expires_in: Int = 0
    var scope: String = ""

    init(json: JSON) {
        if let access_token = json["access_token"].string { self.access_token = access_token }
        if let refresh_token = json["refresh_token"].string { self.refresh_token = refresh_token }
        if let token_type = json["token_type"].string { self.token_type = token_type }
        if let expires_in = json["expires_in"].int { self.expires_in = expires_in}
        if let scope = json["scope"].string { self.scope = scope }
    }

    init(dict: [String: AnyObject]) {
        if let access_token = dict["access_token"] { self.access_token = access_token as! String}
        if let refresh_token = dict["refresh_token"] { self.refresh_token = refresh_token as! String}
        if let token_type = dict["token_type"] { self.token_type = token_type  as! String}
        if let expires_in = dict["expires_in"] { self.expires_in = expires_in as! Int}
        if let scope = dict["scope"] { self.scope = scope  as! String}
    }

    public func toJSON() -> JSON {
        var dict: [String: AnyObject] = [
                "access_token" : self.access_token,
                "token_type" : self.token_type,
                "expires_in" : self.expires_in,
                "scope" : self.scope
        ]
        if let refresh_token = self.refresh_token {
            dict["refresh_token"] = refresh_token
        }
        let json: JSON = JSON(dict)
        return json
    }

}