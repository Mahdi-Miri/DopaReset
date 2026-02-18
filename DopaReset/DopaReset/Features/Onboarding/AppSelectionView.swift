// AppSelectionView.swift
// Standalone sheet that presents FamilyActivityPicker

import SwiftUI
import FamilyControls

struct AppSelectionView: View {

    @Binding var selection: FamilyActivitySelection
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            FamilyActivityPicker(selection: $selection)
                .navigationTitle("Select Apps")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                            .foregroundStyle(Color.dopaPurple)
                    }
                }
        }
    }
}

#Preview {
    AppSelectionView(selection: .constant(FamilyActivitySelection()))
}
