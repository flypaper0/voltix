//
//  OnboardingView.swift
//  VoltixApp
//
//  Created by Amol Kumar on 2024-03-14.
//

import SwiftUI

struct OnboardingView: View {
    @State var tabIndex = 0
    
    var body: some View {
        ZStack {
            background
            view
        }
    }
    
    var background: some View {
        Color.backgroundBlue
            .ignoresSafeArea()
    }
    
    var view: some View {
        VStack {
            title
            Spacer()
            tabs
            Spacer()
            buttons
        }
    }
    
    var title: some View {
        Image("LogoWithTitle")
            .padding(.top, 30)
    }
    
    var tabs: some View {
        TabView(selection: $tabIndex) {
            OnboardingView1().tag(0)
            OnboardingView2().tag(1)
            OnboardingView3().tag(2)
        }
        .tabViewStyle(PageTabViewStyle())
        .frame(height: .infinity)
    }
    
    var buttons: some View {
        VStack(spacing: 15) {
            nextButton
            skipButton
        }
        .padding(40)
    }
    
    var nextButton: some View {
        FilledButton(title: "next")
    }
    
    var skipButton: some View {
        Button {
            skipTapped()
        } label: {
            Text(NSLocalizedString("skip", comment: ""))
                .padding(12)
                .frame(maxWidth: .infinity)
                .foregroundColor(Color.turquoise600)
                .font(.body16MontserratMedium)
        }
        .opacity(tabIndex==2 ? 0 : 1)
        .disabled(tabIndex==2 ? true : false)
        .animation(.easeInOut, value: tabIndex)
    }
    
    private func skipTapped() {
        
    }
}

#Preview {
    OnboardingView()
}
