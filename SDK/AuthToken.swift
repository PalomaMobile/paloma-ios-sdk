//
//  AuthToken.swift
//  SDK
//
//  Created by karel herink on 7/12/2015.
//  Copyright © 2015 Paloma Mobile Ltd. All rights reserved.
//

import Foundation

public class AuthToken {
    
    var access_token: String = ""
    var token_type: String = ""
    var expires_in: Int = 0
    var scope: String = ""

    init(json: JSON) {
        if let access_token = json["access_token"].string { self.access_token = access_token }
        if let token_type = json["token_type"].string { self.token_type = token_type }
        if let expires_in = json["expires_in"].int { self.expires_in = expires_in}
        if let scope = json["scope"].string { self.scope = scope }
    }

}