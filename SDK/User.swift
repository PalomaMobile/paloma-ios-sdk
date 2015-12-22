//
// Created by karel herink on 9/12/2015.
// Copyright (c) 2015 Paloma Mobile Ltd. All rights reserved.
//

import Foundation
import SwiftyJSON

public struct User {

    var id: Int64 = 0
    var username: String = ""
    var emailAddress: String? = nil

    init(json: JSON) {
        if let id = json["id"].int64 { self.id = id }
        if let username = json["username"].string { self.username = username }
        emailAddress = json["emailAddress"].string
    }

}
