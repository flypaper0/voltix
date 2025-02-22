//
//  THORChainSwaps.swift
//  VoltixApp
//

import Foundation
import Tss
import WalletCore

class THORChainSwaps {
    let vaultHexPublicKey: String
    let vaultHexChainCode: String

    init(vaultHexPublicKey: String, vaultHexChainCode: String) {
        self.vaultHexPublicKey = vaultHexPublicKey
        self.vaultHexChainCode = vaultHexChainCode
    }

    static let affiliateFeeAddress = "thor1tgxm5jw6hrlvslrd6lqpk4jwuu4g29dxytrean"
    func getPreSignedInputData(swapPayload: THORChainSwapPayload, keysignPayload: KeysignPayload) -> Result<Data, Error> {
        let input = THORChainSwapSwapInput.with {
            $0.fromAsset = swapPayload.fromAsset
            $0.fromAddress = swapPayload.fromAddress
            $0.toAsset = swapPayload.toAsset
            $0.toAddress = swapPayload.toAddress
            $0.vaultAddress = swapPayload.vaultAddress
            $0.fromAmount = swapPayload.fromAmount
            $0.toAmountLimit = swapPayload.toAmountLimit
        }
        do {
            let inputData = try input.serializedData()
            let outputData = THORChainSwap.buildSwap(input: inputData)
            let output = try THORChainSwapSwapOutput(serializedData: outputData)
            switch swapPayload.fromAsset.chain {
            case .thor:
                return THORChainHelper.getSwapPreSignedInputData(keysignPayload: keysignPayload, signingInput: output.cosmos)
            case .btc:
                let utxoHelper = UTXOChainsHelper(coin: .bitcoin, vaultHexPublicKey: self.vaultHexPublicKey, vaultHexChainCode: self.vaultHexChainCode)
                return utxoHelper.getSigningInputData(keysignPayload: keysignPayload, signingInput: output.bitcoin)
            case .bch:
                let utxoHelper = UTXOChainsHelper(coin: .bitcoinCash, vaultHexPublicKey: self.vaultHexPublicKey, vaultHexChainCode: self.vaultHexChainCode)
                return utxoHelper.getSigningInputData(keysignPayload: keysignPayload, signingInput: output.bitcoin)
            case .ltc:
                let utxoHelper = UTXOChainsHelper(coin: .litecoin, vaultHexPublicKey: self.vaultHexPublicKey, vaultHexChainCode: self.vaultHexChainCode)
                return utxoHelper.getSigningInputData(keysignPayload: keysignPayload, signingInput: output.bitcoin)
            case .doge:
                let utxoHelper = UTXOChainsHelper(coin: .dogecoin, vaultHexPublicKey: self.vaultHexPublicKey, vaultHexChainCode: self.vaultHexChainCode)
                return utxoHelper.getSigningInputData(keysignPayload: keysignPayload, signingInput: output.bitcoin)
            case .eth:
                return EthereumHelper.getPreSignedInputData(signingInput: output.ethereum, keysignPayload: keysignPayload)
            default:
                return .failure(HelperError.runtimeError("not support yet"))
            }
        } catch {
            return .failure(error)
        }
    }

    func getPreSignedImageHash(keysignPayload: KeysignPayload) -> Result<[String], Error> {
        guard let swapPayload = keysignPayload.swapPayload else {
            return .failure(HelperError.runtimeError("no swap payload"))
        }
        let result = self.getPreSignedInputData(swapPayload: swapPayload, keysignPayload: keysignPayload)
        do {
            switch result {
            case .success(let inputData):
                switch swapPayload.fromAsset.chain {
                case .thor:
                    let hashes = TransactionCompiler.preImageHashes(coinType: .thorchain, txInputData: inputData)
                    let preSigningOutput = try TxCompilerPreSigningOutput(serializedData: hashes)
                    return .success([preSigningOutput.dataHash.hexString])
                case .btc:
                    let hashes = TransactionCompiler.preImageHashes(coinType: .thorchain, txInputData: inputData)
                    let preSigningOutput = try BitcoinPreSigningOutput(serializedData: hashes)
                    return .success(preSigningOutput.hashPublicKeys.map { $0.dataHash.hexString })
                case .eth:
                    let hashes = TransactionCompiler.preImageHashes(coinType: .ethereum, txInputData: inputData)
                    let preSigningOutput = try TxCompilerPreSigningOutput(serializedData: hashes)
                    return .success([preSigningOutput.dataHash.hexString])

                default:
                    return .failure(HelperError.runtimeError("not support yet"))
                }
            case .failure(let err):
                return .failure(err)
            }

        } catch {
            return .failure(error)
        }
    }

    func getSignedTransaction(keysignPayload: KeysignPayload,
                              signatures: [String: TssKeysignResponse]) -> Result<String, Error>
    {
        guard let swapPayload = keysignPayload.swapPayload else {
            return .failure(HelperError.runtimeError("no swap payload"))
        }

        let result = self.getPreSignedInputData(swapPayload: swapPayload, keysignPayload: keysignPayload)
        switch result {
        case .success(let inputData):
            switch swapPayload.fromAsset.chain {
            case .thor:
                return THORChainHelper.getSignedTransaction(vaultHexPubKey: self.vaultHexPublicKey, vaultHexChainCode: self.vaultHexChainCode, inputData: inputData, signatures: signatures)
            case .btc:
                let utxoHelper = UTXOChainsHelper(coin: .bitcoin, vaultHexPublicKey: self.vaultHexPublicKey, vaultHexChainCode: self.vaultHexChainCode)
                return utxoHelper.getSignedTransaction(inputData: inputData, signatures: signatures)
            case .bch:
                let utxoHelper = UTXOChainsHelper(coin: .bitcoinCash, vaultHexPublicKey: self.vaultHexPublicKey, vaultHexChainCode: self.vaultHexChainCode)
                return utxoHelper.getSignedTransaction(inputData: inputData, signatures: signatures)
            case .ltc:
                let utxoHelper = UTXOChainsHelper(coin: .litecoin, vaultHexPublicKey: self.vaultHexPublicKey, vaultHexChainCode: self.vaultHexChainCode)
                return utxoHelper.getSignedTransaction(inputData: inputData, signatures: signatures)
            case .doge:
                let utxoHelper = UTXOChainsHelper(coin: .dogecoin, vaultHexPublicKey: self.vaultHexPublicKey, vaultHexChainCode: self.vaultHexChainCode)
                return utxoHelper.getSignedTransaction(inputData: inputData, signatures: signatures)
            case .eth:
                return EthereumHelper.getSignedTransaction(vaultHexPubKey: self.vaultHexPublicKey, vaultHexChainCode: self.vaultHexChainCode, inputData: inputData, signatures: signatures)
            default:
                return .failure(HelperError.runtimeError("not support"))
            }
        case .failure(let err):
            return .failure(err)
        }
    }
}
