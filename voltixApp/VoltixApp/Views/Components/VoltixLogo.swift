//
//  Logo.swift
//  VoltixApp
//
//  Created by Mac on 05.02.2024.
//

import SwiftUI

struct VoltixLogo: View {
    var isAnimated: Bool = true
    
    @State var didAppear = false
    
    var body: some View {
        VStack {
            logo
            title
        }
        .onAppear {
            setData()
        }
    }
    
    var logo: some View {
        ZStack {
            stroke3
            stroke2
            stroke1
            primaryLogo
        }
    }
    
    var primaryLogo: some View {
        Image("VoltixLogo")
            .resizable()
            .frame(width: 160, height: 160)
            .scaleEffect(didAppear ? 1 : 0)
            .opacity(didAppear ? 1 : 0)
    }
    
    var stroke1: some View {
        Image("VoltixLogoStroke1")
            .resizable()
            .frame(width: 179.8, height: 154.5)
            .offset(y: 2)
            .scaleEffect(didAppear ? 1 : 0)
            .opacity(didAppear ? 1 : 0)
            .animation(
                isAnimated ? .spring(duration: 0.5).delay(0.2) : .none,
                value: didAppear
            )
    }
    
    var stroke2: some View {
        Image("VoltixLogoStroke2")
            .resizable()
            .frame(width: 201.3, height: 171.2)
            .offset(y: 4)
            .scaleEffect(didAppear ? 1 : 0)
            .opacity(didAppear ? 1 : 0)
            .animation(
                isAnimated ? .spring(duration: 0.5).delay(0.3) : .none,
                value: didAppear
            )
    }
    
    var stroke3: some View {
        Image("VoltixLogoStroke3")
            .resizable()
            .frame(width: 222.8, height: 190)
            .offset(y: 5)
            .scaleEffect(didAppear ? 1 : 0)
            .opacity(didAppear ? 1 : 0)
            .animation(
                isAnimated ? .spring(duration: 0.5).delay(0.4) : .none,
                value: didAppear
            )
    }
    
    var title: some View {
        Text("Voltix")
            .font(.title40MontserratSemiBold)
            .foregroundColor(.neutral0)
            .opacity(didAppear ? 1 : 0)
            .animation(
                isAnimated ? .easeIn(duration: 1) : .none,
                value: didAppear)
    }
    
    private func setData() {
        withAnimation(isAnimated ? .spring : .none) {
            didAppear = true
        }
    }
}

#Preview {
    ZStack {
        Color.backgroundBlue
            .ignoresSafeArea()
        VoltixLogo()
    }
}
