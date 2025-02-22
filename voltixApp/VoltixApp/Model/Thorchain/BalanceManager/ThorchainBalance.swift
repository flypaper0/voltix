//
//  ThorchainBalance.swift
//  VoltixApp
//
//  Created by Enrique Souza Soares on 06/03/2024.
//

import Foundation

class ThorchainBalance: Codable {
    var denom: String
    var amount: String
    
    init(denom: String, amount: String) {
        self.denom = denom
        self.amount = amount
    }
}
