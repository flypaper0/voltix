	//
	//  VoltixApp
	//
	//  Created by Enrique Souza Soares
	//
import SwiftUI

struct UTXOTransactionListView: View {
	@StateObject var utxoTransactionsService: UTXOTransactionsService = .init()
	@EnvironmentObject var appState: ApplicationState
	
	@Binding var presentationStack: [CurrentScreen]
	@ObservedObject var tx: SendTransaction
	
	var body: some View {
		VStack {
			List {
				if let transactions = utxoTransactionsService.walletData {
					ForEach(transactions, id: \.txid) { transaction in
						TransactionRow(transaction: transaction, tx: tx)
					}
				} else if let errorMessage = utxoTransactionsService.errorMessage {
					Text("Error fetching transactions: \(errorMessage)")
				} else {
					ProgressView()
				}
			}
			.navigationTitle("Transactions")
			.navigationBarBackButtonHidden()
			.modifier(InlineNavigationBarTitleModifier())
			.toolbar {
				ToolbarItem(placement: .navigationBarLeading) {
					NavigationButtons.backButton(presentationStack: $presentationStack)
				}
				ToolbarItem(placement: .navigationBarTrailing) {
					NavigationButtons.questionMarkButton
				}
			}
			.task {
				
				if tx.coin.chain.name == Chain.Bitcoin.name {
					await utxoTransactionsService.fetchTransactions(tx.coin.address, endpointUrl: Endpoint.fetchBitcoinTransactions(tx.coin.address))
				} else if tx.coin.chain.name == Chain.Litecoin.name {
					await utxoTransactionsService.fetchTransactions(tx.coin.address, endpointUrl: Endpoint.fetchLitecoinTransactions(tx.coin.address))
				}
				
			}
		}
	}
}

struct TransactionRow: View {
	let transaction: UTXOTransactionMempool
	let tx: SendTransaction
	
	var body: some View {
		Section {
			VStack(alignment: .leading) {
				LabelTxHash(title: "TX ID:".uppercased(), value: transaction.txid, isSent: transaction.isSent, coinChainName: tx.coin.chain.name)
					.padding(.vertical, 5)
				Divider() // Adds a horizontal line
				
				if transaction.isSent {
					ForEach(transaction.sentTo, id: \.self) { address in
						LabelText(title: "To:".uppercased(), value: address)
							.padding(.vertical, 1)
					}
					Divider() // Adds a horizontal line
					LabelTextNumeric(title: "Amount:".uppercased(), value: formatAmount(transaction.amountSent))
						.padding(.vertical, 1)
				} else if transaction.isReceived {
					ForEach(transaction.receivedFrom, id: \.self) { address in
						LabelText(title: "From:".uppercased(), value: address)
							.padding(.vertical, 1)
					}
					Divider() // Adds a horizontal line
					LabelTextNumeric(title: "Amount:".uppercased(), value: formatAmount(transaction.amountReceived))
						.padding(.vertical, 1)
				}
				
				if transaction.opReturnData != nil {
					Divider() // Adds a horizontal line
					LabelText(title: "MEMO:".uppercased(), value: transaction.opReturnData ?? "")
						.padding(.vertical, 1)
				}
				
				Divider() // Adds a horizontal line
				LabelTextNumeric(title: "Fee:", value: String(transaction.fee) + " \(tx.coin.feeUnit)")
					.padding(.vertical, 5)
			}
		}
	}
	
	@ViewBuilder
	private func LabelTxHash(title: String, value: String, isSent: Bool, coinChainName: String) -> some View {
		VStack(alignment: .leading) {
			HStack {
				Image(systemName: isSent ? "arrowtriangle.up.square" : "arrowtriangle.down.square")
					.resizable()
					.frame(width: 20, height: 20)
				
				Text(title)
					.font(.body20MenloBold) // Ensure you have this font applied correctly
			}
			
			Link(destination: URL(string: determineURL(value, coinChainName: coinChainName))!) {
				Text(value)
					.font(.body13MontserratMedium) // Ensure you have this font applied correctly
					.padding(.vertical, 5)
					.foregroundColor(Color.blue)
			}
			.buttonStyle(PlainButtonStyle())
		}
	}
	
	private func determineURL(_ value: String, coinChainName: String) -> String {
		if coinChainName == Chain.Litecoin.name {
			return Endpoint.litecoinLabelTxHash(value)
		} else {
			return Endpoint.bitcoinLabelTxHash(value)
		}
	}

	
	@ViewBuilder
	private func LabelText(title: String, value: String) -> some View {
		VStack(alignment: .leading) {
			Text(title)
				.font(.body20MenloBold)
			Text(value)
				.font(.body13MontserratMedium)
				.padding(.vertical, 5)
		}
	}
	
	@ViewBuilder
	private func LabelTextNumeric(title: String, value: String) -> some View {
		HStack {
			Text(title)
				.font(.body20MenloBold)
			Spacer()
			Text(value)
				.font(.title30MenloUltraLight)
				.padding(.vertical, 5)
		}
	}
	
	private func formatAmount(_ amountSatoshis: Int) -> String {
		let amountBTC = Double(amountSatoshis) / 100_000_000 // Convert satoshis to BTC
		let formatter = NumberFormatter()
		formatter.numberStyle = .decimal
		formatter.minimumFractionDigits = 0 // Minimum number of digits after the decimal point
		formatter.maximumFractionDigits = 8 // Maximum number of digits after the decimal point, adjust if needed
		formatter.decimalSeparator = "." // Use dot for decimal separation
		formatter.groupingSeparator = "," // Use comma for thousands separation, adjust if needed
		
		return (formatter.string(from: NSNumber(value: amountBTC)) ?? "\(amountBTC) \(tx.coin.ticker.uppercased())")
	}
}
