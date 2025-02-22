//
//  KeygenViewModel.swift
//  VoltixApp
//

import Foundation
import OSLog
import SwiftData
import Tss

enum KeygenStatus {
    case CreatingInstance
    case KeygenECDSA
    case ReshareECDSA
    case ReshareEdDSA
    case KeygenEdDSA
    case KeygenFinished
    case KeygenFailed
}

@MainActor
class KeygenViewModel: ObservableObject {
    private let logger = Logger(subsystem: "keygen-viewmodel", category: "tss")
    
    var vault: Vault
    var tssType: TssType // keygen or reshare
    var keygenCommittee: [String]
    var vaultOldCommittee: [String]
    var mediatorURL: String
    var sessionID: String
    
    @Published var isLinkActive = false
    @Published var keygenError: String = ""
    @Published var status = KeygenStatus.CreatingInstance
    
    private var tssService: TssServiceImpl? = nil
    private var tssMessenger: TssMessengerImpl? = nil
    private var stateAccess: LocalStateAccessorImpl? = nil
    private var messagePuller = MessagePuller()
    
    init() {
        self.vault = Vault(name: "New Vault")
        self.tssType = .Keygen
        self.keygenCommittee = []
        self.vaultOldCommittee = []
        self.mediatorURL = ""
        self.sessionID = ""
    }
    
    func setData(vault: Vault, tssType: TssType, keygenCommittee: [String], vaultOldCommittee: [String], mediatorURL: String, sessionID: String) {
        self.vault = vault
        self.tssType = tssType
        self.keygenCommittee = keygenCommittee
        self.vaultOldCommittee = vaultOldCommittee
        self.mediatorURL = mediatorURL
        self.sessionID = sessionID
    }

    func delaySwitchToMain() {
        Task {
            // when user didn't touch it for 5 seconds , automatically goto home screen
            try await Task.sleep(for: .seconds(5)) // Back off 5s
            self.isLinkActive = true
        }
    }

    func startKeygen(context: ModelContext) async {
        defer {
            self.messagePuller.stop()
        }
        do {
            self.vault.signers = self.keygenCommittee
            // Create keygen instance, it takes time to generate the preparams
            let messengerImp = TssMessengerImpl(mediatorUrl: self.mediatorURL, sessionID: self.sessionID, messageID: nil)
            let stateAccessorImp = LocalStateAccessorImpl(vault: self.vault)
            self.tssMessenger = messengerImp
            self.stateAccess = stateAccessorImp
            self.tssService = try await self.createTssInstance(messenger: messengerImp,
                                                               localStateAccessor: stateAccessorImp)
            guard let tssService = self.tssService else {
                self.keygenError = "TSS instance is nil"
                self.status = .KeygenFailed
                return
            }
            self.messagePuller.pollMessages(mediatorURL: self.mediatorURL,
                                            sessionID: self.sessionID,
                                            localPartyKey: self.vault.localPartyID,
                                            tssService: tssService,
                                            messageID: nil)
            switch self.tssType {
            case .Keygen:
                self.status = .KeygenECDSA
                let keygenReq = TssKeygenRequest()
                keygenReq.localPartyID = self.vault.localPartyID
                keygenReq.allParties = self.keygenCommittee.joined(separator: ",")
                keygenReq.chainCodeHex = self.vault.hexChainCode
                self.logger.info("chaincode:\(self.vault.hexChainCode)")
                
                let ecdsaResp = try await tssKeygen(service: tssService, req: keygenReq, keyType: .ECDSA)
                self.vault.pubKeyECDSA = ecdsaResp.pubKey
                
                // continue to generate EdDSA Keys
                self.status = .KeygenEdDSA
                try await Task.sleep(for: .seconds(1)) // Sleep one sec to allow other parties to get in the same step
                
                let eddsaResp = try await tssKeygen(service: tssService, req: keygenReq, keyType: .EdDSA)
                self.vault.pubKeyEdDSA = eddsaResp.pubKey
            case .Reshare:
                self.status = .ReshareECDSA
                let reshareReq = TssReshareRequest()
                reshareReq.localPartyID = self.vault.localPartyID
                reshareReq.pubKey = self.vault.pubKeyECDSA
                reshareReq.oldParties = self.vaultOldCommittee.joined(separator: ",")
                reshareReq.newParties = self.keygenCommittee.joined(separator: ",")
                reshareReq.resharePrefix = self.vault.resharePrefix ?? ""
                reshareReq.chainCodeHex = self.vault.hexChainCode
                self.logger.info("chaincode:\(self.vault.hexChainCode)")
                
                let ecdsaResp = try await tssReshare(service: tssService, req: reshareReq, keyType: .ECDSA)
                self.vault.pubKeyECDSA = ecdsaResp.pubKey
                self.vault.resharePrefix = ecdsaResp.resharePrefix
                
                // continue to generate EdDSA Keys
                self.status = .ReshareEdDSA
                try await Task.sleep(for: .seconds(1)) // Sleep one sec to allow other parties to get in the same step
                reshareReq.pubKey = self.vault.pubKeyEdDSA
                reshareReq.newResharePrefix = ecdsaResp.resharePrefix
                let eddsaResp = try await tssReshare(service: tssService, req: reshareReq, keyType: .EdDSA)
                self.vault.pubKeyEdDSA = eddsaResp.pubKey
            }
            
            self.status = .KeygenFinished
            // save the vault
            if let stateAccess {
                self.vault.keyshares = stateAccess.keyshares
            }
            switch self.tssType {
            case .Keygen:
                context.insert(self.vault)
            case .Reshare:
                // if local party is not in the old committee , then he is the new guy , need to add the vault
                // otherwise , they previously have the vault
                if !self.vaultOldCommittee.contains(self.vault.localPartyID) {
                    context.insert(self.vault)
                }
            }
            try context.save()
        } catch {
            self.logger.error("Failed to generate key, error: \(error.localizedDescription)")
            self.status = .KeygenFailed
            self.keygenError = error.localizedDescription
            return
        }
    }

    private func createTssInstance(messenger: TssMessengerProtocol,
                                   localStateAccessor: TssLocalStateAccessorProtocol) async throws -> TssServiceImpl?
    {
        let t = Task.detached(priority: .high) {
            var err: NSError?
            let service = await TssNewService(self.tssMessenger, self.stateAccess, true, &err)
            if let err {
                throw err
            }
            return service
        }
        return try await t.value
    }
    
    private func tssKeygen(service: TssServiceImpl,
                           req: TssKeygenRequest,
                           keyType: KeyType) async throws -> TssKeygenResponse
    {
        let t = Task.detached(priority: .high) {
            switch keyType {
            case .ECDSA:
                return try service.keygenECDSA(req)
            case .EdDSA:
                return try service.keygenEdDSA(req)
            }
        }
        return try await t.value
    }
    
    private func tssReshare(service: TssServiceImpl,
                            req: TssReshareRequest,
                            keyType: KeyType) async throws -> TssReshareResponse
    {
        let t = Task.detached(priority: .high) {
            switch keyType {
            case .ECDSA:
                return try service.reshareECDSA(req)
            case .EdDSA:
                return try service.resharingEdDSA(req)
            }
        }
        return try await t.value
    }
}
