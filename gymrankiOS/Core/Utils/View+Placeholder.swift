//
//  View+Placeholder.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 05/02/2026.
//

import SwiftUI

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            content().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
