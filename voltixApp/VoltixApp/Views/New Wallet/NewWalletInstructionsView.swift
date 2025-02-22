//
//  NewWalletInstructions.swift
//  VoltixApp
//

import SwiftData
import SwiftUI

struct NewWalletInstructions: View {
    @Binding var presentationStack: [CurrentScreen]
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: ApplicationState
    @Query var vaults: [Vault]

    var body: some View {
        VStack {
            VStack {
                Text("YOU NEED THREE DEVICES.")
                    .fontWeight(.medium)
                Spacer()
                VStack {
                    DeviceView(
                        number: "1.circle",
                        description: "MAIN",
                        deviceImg: "macbook",
                        deviceDescription: "A MACBOOK"
                    )
                    DeviceView(
                        number: "2.circle",
                        description: "PAIR",
                        deviceImg: "macbook.and.iphone",
                        deviceDescription: "ANY"
                    )
                    DeviceView(
                        number: "3.circle",
                        description: "PAIR",
                        deviceImg: "macbook.and.ipad",
                        deviceDescription: "ANY"
                    )
                }
                Spacer()
                WifiBar()
                Spacer()
                HStack {
                    Button("PAIR") {
                        let vault = Vault(name: "Vault #\(vaults.count + 1)")
                        self.presentationStack.append(.joinKeygen(vault))
                    }
                    .fontWeight(.black)
                    .font(.title30MenloBold)
                    .buttonStyle(PlainButtonStyle())
                    Spacer()

                    Button(action: {
                        let vault = Vault(name: "Vault #\(vaults.count + 1)")
                        appState.creatingVault = vault
                        self.presentationStack.append(.peerDiscovery(vault: vault, tssType: .Keygen))
                    }) {
                        HStack {
                            Text("START")
                                .font(.title30MenloBlack)
                            Image(systemName: "chevron.right")
                                .resizable()
                                .frame(width: 10, height: 15)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                }.padding()
            }
            .navigationTitle("SETUP")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationButtons.backButton(presentationStack: $presentationStack)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationButtons.questionMarkButton
                }
            }
        }
    }
}

#Preview {
    NewWalletInstructions(presentationStack: .constant([]))
}
