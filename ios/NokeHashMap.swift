//
//  NokeHashMap.swift
//  RNNoke
//
//  Created by linh on 8/27/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

import Foundation

class NokeHashMap {
    var name: String = ""
    var macAddress: String = ""
    var key: String = ""
    var command: String = ""
    var commands: [String] = []
    
    init(data: Dictionary<String, Any>) {
        if(data["name"] != nil) {
            name = data["name"] as! String
        }

        if(data["macAddress"] != nil) {
            macAddress = data["macAddress"] as! String
        }

        if(data["key"] != nil) {
            key = data["key"] as! String
        }

        if(data["command"] != nil) {
            command = data["command"] as! String
        }

        if(data["commands"] != nil) {
            commands = data["commands"] as! [String]
        }
    }
}
