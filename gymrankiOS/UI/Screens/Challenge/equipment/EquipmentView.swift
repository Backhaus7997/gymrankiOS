//
//  EquipmentView.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 10/02/2026.
//

import SwiftUI

struct EquipmentView: View {

    // Si querés devolver lo seleccionado al padre:
    let onSave: ([String]) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selections: Set<String> = []

    private let equipment: [String] = [
        "Barra de dominadas",
        "Barras paralelas (dips)",
        "Soga para saltar",
        "Bandas de resistencia",
        "Kettlebell",
        "Mancuernas"
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()

            VStack(spacing: 14) {

                header

                HStack(spacing: 12) {
                    pillButton("Seleccionar todo") {
                        selections = Set(equipment)
                    }
                    pillButton("Limpiar") {
                        selections.removeAll()
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Equipamiento")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.white.opacity(0.92))

                    equipmentList
                }

                Spacer(minLength: 0)

                saveButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 26)
            .padding(.bottom, 14)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Equipamiento")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                Text("Seleccioná lo que tenés disponible")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.06)))
                    .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }

    private func pillButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.90))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.appGreen.opacity(0.22), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private var equipmentList: some View {
        VStack(spacing: 0) {
            ForEach(equipment, id: \.self) { item in
                HStack {
                    Text(item)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.88))

                    Spacer()

                    Button {
                        toggle(item)
                    } label: {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(Color.white.opacity(0.35), lineWidth: 1.2)
                            .frame(width: 22, height: 22)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .heavy))
                                    .foregroundColor(Color.appGreen.opacity(0.95))
                                    .opacity(selections.contains(item) ? 1 : 0)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 14)

                if item != equipment.last {
                    Divider().overlay(Color.white.opacity(0.06))
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.appGreen.opacity(0.18), lineWidth: 1)
                )
        )
    }

    private var saveButton: some View {
        Button {
            onSave(Array(selections))
            dismiss()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .heavy))
                Text("Guardar")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.appGreen.opacity(0.95))
            )
        }
        .buttonStyle(.plain)
    }

    private func toggle(_ item: String) {
        if selections.contains(item) {
            selections.remove(item)
        } else {
            selections.insert(item)
        }
    }
}

#Preview {
    EquipmentView(onSave: { _ in })
        .presentationDetents([.fraction(0.70), .large])
        .presentationCornerRadius(22)
}
