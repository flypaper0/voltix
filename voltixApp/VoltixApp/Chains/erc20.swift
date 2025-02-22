//
//  erc20.swift
//  VoltixApp
//

import Foundation
import Tss
import WalletCore
import BigInt

enum ERC20Helper {
    static func getPreSignedInputData(keysignPayload: KeysignPayload) -> Result<Data, Error> {
        guard keysignPayload.coin.chain.ticker == "ETH" else {
            return .failure(HelperError.runtimeError("coin is not ETH"))
        }
        let coin = CoinType.ethereum
        guard let intChainID = Int64(coin.chainId) else {
            return .failure(HelperError.runtimeError("fail to get chainID"))
        }
        guard case .ERC20(let maxFeePerGasGWei,
                          let priorityFeeGWei,
                          let nonce,
                          let gasLimit,
                          let contractAddr) = keysignPayload.chainSpecific
        else {
            return .failure(HelperError.runtimeError("fail to get Ethereum chain specific"))
        }

        let input = EthereumSigningInput.with {
            $0.chainID = Data(hexString: intChainID.hexString())!
            $0.nonce = Data(hexString: nonce.hexString())!
            $0.gasLimit = Data(hexString: gasLimit.hexString())!
            $0.maxFeePerGas = EthereumHelper.convertEthereumNumber(input: maxFeePerGasGWei)
            $0.maxInclusionFeePerGas = EthereumHelper.convertEthereumNumber(input: priorityFeeGWei)
            $0.toAddress = contractAddr
            $0.txMode = .enveloped
            $0.transaction = EthereumTransaction.with {
                $0.erc20Transfer = EthereumTransaction.ERC20Transfer.with {
                    $0.to = keysignPayload.toAddress
                    $0.amount = Data(hexString: keysignPayload.toAmount.hexString())!
                }
            }
        }
        do {
            let inputData = try input.serializedData()
            return .success(inputData)
        } catch {
            return .failure(HelperError.runtimeError("fail to get plan"))
        }
    }

    static func getPreSignedImageHash(keysignPayload: KeysignPayload) -> Result<[String], Error> {
        let result = getPreSignedInputData(keysignPayload: keysignPayload)
        switch result {
        case .success(let inputData):
            do {
                let hashes = TransactionCompiler.preImageHashes(coinType: .ethereum, txInputData: inputData)
                let preSigningOutput = try TxCompilerPreSigningOutput(serializedData: hashes)
                return .success([preSigningOutput.dataHash.hexString])
            } catch {
                return .failure(HelperError.runtimeError("fail to get preSignedImageHash,error:\(error.localizedDescription)"))
            }
        case .failure(let err):
            return .failure(err)
        }
    }

    static func getSignedTransaction(vaultHexPubKey: String,
                                     vaultHexChainCode: String,
                                     keysignPayload: KeysignPayload,
                                     signatures: [String: TssKeysignResponse]) -> Result<String, Error>
    {
        let ethPublicKey = PublicKeyHelper.getDerivedPubKey(hexPubKey: vaultHexPubKey, hexChainCode: vaultHexChainCode, derivePath: CoinType.ethereum.derivationPath())
        guard let pubkeyData = Data(hexString: ethPublicKey),
              let publicKey = PublicKey(data: pubkeyData, type: .secp256k1)
        else {
            return .failure(HelperError.runtimeError("public key \(ethPublicKey) is invalid"))
        }
        let result = getPreSignedInputData(keysignPayload: keysignPayload)
        switch result {
        case .success(let inputData):
            do {
                let hashes = TransactionCompiler.preImageHashes(coinType: .ethereum, txInputData: inputData)
                let preSigningOutput = try TxCompilerPreSigningOutput(serializedData: hashes)
                let allSignatures = DataVector()
                let publicKeys = DataVector()
                let signatureProvider = SignatureProvider(signatures: signatures)
                let signature = signatureProvider.getSignatureWithRecoveryID(preHash: preSigningOutput.dataHash)

                guard publicKey.verify(signature: signature, message: preSigningOutput.dataHash) else {
                    return .failure(HelperError.runtimeError("fail to verify signature"))
                }

                allSignatures.add(data: signature)

                // it looks like the pubkey compileWithSignature accept is extended public key
                // also , it can be empty as well , since we don't have extended public key , so just leave it empty
                let compileWithSignature = TransactionCompiler.compileWithSignatures(coinType: .ethereum,
                                                                                     txInputData: inputData,
                                                                                     signatures: allSignatures,
                                                                                     publicKeys: publicKeys)
                let output = try EthereumSigningOutput(serializedData: compileWithSignature)
                return .success(output.encoded.hexString)
            } catch {
                return .failure(HelperError.runtimeError("fail to get signed ethereum transaction,error:\(error.localizedDescription)"))
            }
        case .failure(let err):
            return .failure(err)
        }
    }
}
