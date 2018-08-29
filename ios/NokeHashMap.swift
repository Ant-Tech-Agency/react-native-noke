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
        if(data["name"] == nil) {
            return
        }
        
        name = data["name"] as! String
        macAddress = data["macAddress"] as! String
        key = data["key"] as! String
        command = data["command"] as! String
        commands = data["commands"] as! [String]
    }
}
