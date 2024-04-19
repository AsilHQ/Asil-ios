//
//  VpnType.swift
//  Kahf Guard
//
//  Created by Mehdi with ♥ / hi@mehssi.com
//

import Foundation

struct VpnType {
    //INTERNAL/NATIVE DNS IS ONLY AVAILABLE IN iOS
    //IN OSX IT WILL ONLY AFFECT SAFARI NOT CHROME,BRAVE,FIREFOX,OPERA BUT IN IOS IT AFFECTS ALL.
    //SO DON'T USE INTERNAL FOR OSX.
    static let EXTERNAL = 0 //external vpn on our dedicated server that enforces safe search.
    static let INTERNAL = 1 //native dns
    
    static let DEFAULT = VpnType.EXTERNAL
    
    //we've stopped giving vpn option to users.
    static let SHOW_CONNECT_OPTIONS = false
}
