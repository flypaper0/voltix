import SwiftUI

enum UTXOTransactionError: Error {
    case invalidURL
    case httpError(Int) // Includes the HTTP status code
    case apiError(String) // Error message from the API
    case unexpectedResponse
    case unknown(Error) // Wraps an unknown error
}

@MainActor
public class UTXOTransactionsService: ObservableObject {
    @Published var walletData: [UTXOTransactionMempool]?
    @Published var errorMessage: String?
    
    // Cache structure to hold data and timestamp
    private struct CacheEntry {
        let data: [UTXOTransactionMempool]
        let timestamp: Date
    }
    
    // Dictionary to store cache entries with userAddress as the key
    private var cache: [String: CacheEntry] = [:]
    
    // Function to check if cache for a given userAddress is valid (not older than 5 minutes)
    private func isCacheValid(for userAddress: String) -> Bool {
        if let entry = cache[userAddress], -entry.timestamp.timeIntervalSinceNow < 300 {
            return true // Cache is valid if less than 5 minutes old
        }
        return false
    }
    
    func fetchTransactions(_ userAddress: String, endpointUrl: String) async {
        // Use cache if it's valid for the requested userAddress
        if isCacheValid(for: userAddress), let cachedData = cache[userAddress]?.data {
            self.walletData = cachedData
            return
        }
        
		guard let url = URL(string: endpointUrl) else {
            errorMessage = "Invalid URL"
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            print(String(data: data, encoding: .utf8) ?? "No response body")
            let decoder = JSONDecoder()
            let decodedData = try decoder.decode([UTXOTransactionMempool].self, from: data)
            let updatedData = decodedData.map { transaction in
                UTXOTransactionMempool(txid: transaction.txid, version: transaction.version, locktime: transaction.locktime, vin: transaction.vin, vout: transaction.vout, fee: transaction.fee, status: transaction.status, userAddress: userAddress)
            }
            
            cache[userAddress] = CacheEntry(data: updatedData, timestamp: Date())
            self.walletData = updatedData
        } catch let DecodingError.dataCorrupted(context) {
            errorMessage = "Data corrupted: \(context)"
        } catch let DecodingError.keyNotFound(key, context) {
            errorMessage = "Key '\(key)' not found: \(context.debugDescription)"
        } catch let DecodingError.valueNotFound(value, context) {
            errorMessage = "Value '\(value)' not found: \(context.debugDescription)"
        } catch let DecodingError.typeMismatch(type, context) {
            errorMessage = "Type '\(type)' mismatch: \(context.debugDescription)"
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
        }
        
        print(String(describing: errorMessage))
    }
    	
	public static func broadcastTransaction(_ rawTransaction: String, endpointUrl: String) async throws -> String {
		guard let url = URL(string: endpointUrl) else {
			throw UTXOTransactionError.invalidURL
		}
		
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.addValue("text/plain", forHTTPHeaderField: "Content-Type")
		request.httpBody = rawTransaction.data(using: .utf8)
		
		do {
			let (data, response) = try await URLSession.shared.data(for: request)
			
			guard let httpResponse = response as? HTTPURLResponse else {
				throw UTXOTransactionError.unexpectedResponse
			}
			
			let responseString = String(data: data, encoding: .utf8) ?? ""
			
			if httpResponse.statusCode == 200 {
					// Success, return txid
				return responseString
			} else {
					// Attempt to handle as plain-text error message
				if httpResponse.statusCode == 400, // Or other relevant status codes
				   !responseString.isEmpty {
						// Here you could also attempt to parse the responseString if it's JSON formatted
					throw UTXOTransactionError.apiError(responseString)
				} else {
					throw UTXOTransactionError.httpError(httpResponse.statusCode)
				}
			}
		} catch {
			throw UTXOTransactionError.unknown(error)
		}
	}

}
