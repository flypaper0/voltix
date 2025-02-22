//
//  NavigationBackSheetButton.swift
//  VoltixApp
//
//  Created by Amol Kumar on 2024-03-11.
//

import SwiftUI

struct NavigationBackSheetButton: View {
    @Binding var showSheet: Bool
    var tint: Color = Color.neutral0
    
    var body: some View {
        Button(action: {
            showSheet.toggle()
        }) {
            Image(systemName: "chevron.backward")
                .font(.body18MenloBold)
                .foregroundColor(tint)
        }
    }
}

#Preview {
    NavigationBackSheetButton(showSheet: .constant(true))
}
