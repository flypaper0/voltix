    //
    //  MenuView.swift
    //  VoltixApp
    //

import SwiftUI

struct MenuView: View {
    @Binding var presentationStack: Array<CurrentScreen>
    
    var body: some View {
        VStack() {
            
            VStack(alignment: .leading) {
                Text("Choose Vault")
                    .font(.body20Menlo)
                    .lineSpacing(30)
                ;
                HStack() {
                    Text("Main Vault")
                        .font(.body20MenloBold)
                        .lineSpacing(30)
                    ;
                    Spacer()
                    Image(systemName: "chevron.right")
                        .resizable()
                    
                        .frame(width: 9, height: 15)
                        .rotationEffect(.degrees(90));
                }
                .padding(.leading, 16)
                .padding(.trailing, 16)
                .foregroundColor(.clear)
                .frame(width: .infinity, height: 55)
                .background(Color.gray400)
                .cornerRadius(10);
            }
            Spacer().frame(height: 30)
            MenuItem(
                content: "ADD VAULT",
                onClick: {}
            )
            MenuItem(
                content: "EXPORT VAULT",
                onClick: {}
            )
            MenuItem(
                content: "FORGET VAULT",
                onClick: {}
            )
            MenuItem(
                content: "VAULT RECOVERY",
                onClick: {}
            )
            Spacer()
            VStack {
                Text("VOLTIX APP V1.23")
                    .font(.body20MenloBold)
                    .lineSpacing(30)
                ;
            }
            .frame(width: .infinity, height: 110)
        }
        .padding(.trailing, 20)
        .padding(.leading, 20)
        .frame(
            minWidth: 0,
            maxWidth: .infinity,
            minHeight: 0,
            maxHeight: .infinity,
            alignment: .topLeading
        )
    }
}

#Preview {
    MenuView(presentationStack: .constant([]))
}
