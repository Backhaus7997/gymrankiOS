//
//  ProfileSheet.swift
//  gymrankiOS
//

import SwiftUI
import PhotosUI

struct ProfileSheet: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager

    @StateObject private var vm = ProfileSheetViewModel()

    let onLogout: () -> Void
    @State private var showLogoutConfirm = false

    // ✅ Fix alert (no usar .constant)
    @State private var showErrorAlert = false

    // ✅ Privacy picker (action sheet)
    @State private var showPrivacyPicker = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 12) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        profileCard
                        requestsCard
                        actionsCard
                        Spacer().frame(height: 8)
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
                }
            }
            .frame(maxWidth: 560)
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.black.opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.55), radius: 24, x: 0, y: 14)
            .transition(.scale.combined(with: .opacity))

            // ✅ Absorbe taps dentro del modal para que NO llegue al fondo
            .contentShape(Rectangle())
            .onTapGesture { }
        }
        .task {
            let uid = session.userId
            guard !uid.isEmpty else { return }
            await vm.load(myUid: uid)
        }
        .onChange(of: vm.pickedAvatarItem) { _ in
            Task { await vm.onPickedAvatarChanged() }
        }
        .onChange(of: vm.errorMessage) { newValue in
            showErrorAlert = (newValue != nil)
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .confirmationDialog("Cuenta", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
            Button("Cerrar sesión", role: .destructive) {
                do {
                    try AuthService.shared.logout()
                    onLogout()
                    dismiss()
                } catch {
                    vm.errorMessage = (error as NSError).localizedDescription
                }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("¿Querés cerrar sesión?")
        }
        .confirmationDialog("Privacidad del perfil", isPresented: $showPrivacyPicker, titleVisibility: .visible) {
            Button("Público") { Task { await vm.updatePrivacy(.public) } }
            Button("Solo amigos") { Task { await vm.updatePrivacy(.friendsOnly) } }
            Button("Privado") { Task { await vm.updatePrivacy(.private) } }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esto define quién puede ver tus entrenamientos en el feed.")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Perfil")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.10)))
                    .overlay(Circle().stroke(Color.white.opacity(0.14), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
    }

    // MARK: - Profile card

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack(spacing: 12) {
                avatarBig

                VStack(alignment: .leading, spacing: 4) {
                    Text(topName)
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(.white.opacity(0.92))

                    Text(vm.profile?.displaySubtitle ?? "En progreso")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                }

                Spacer()

                PhotosPicker(selection: $vm.pickedAvatarItem, matching: .images) {
                    HStack(spacing: 8) {
                        if vm.isUploadingAvatar {
                            SwiftUI.ProgressView().tint(Color.appGreen.opacity(0.95))
                        }
                        Text("Cambiar foto")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundColor(Color.appGreen.opacity(0.95))
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.appGreen.opacity(0.25), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }

            Divider().overlay(Color.white.opacity(0.10))

            VStack(spacing: 10) {
                field(title: "Nombre", text: $vm.fullName)

                pickerRow(
                    title: "Experiencia",
                    selection: $vm.experience,
                    options: ["Principiante", "Intermedio", "Avanzado"]
                )

                pickerRow(
                    title: "Género",
                    selection: $vm.gender,
                    options: ["Masculino", "Femenino", "Otro"]
                )
            }

            // ✅ Privacidad del perfil (botón que abre opciones)
            privacySection

            Button {
                Task { await vm.saveProfile() }
            } label: {
                Text(vm.isLoading ? "GUARDANDO..." : "GUARDAR CAMBIOS")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Capsule().fill(Color.appGreen.opacity(0.95)))
            }
            .buttonStyle(.plain)
            .disabled(vm.isLoading)
            .opacity(vm.isLoading ? 0.6 : 1.0)

            if vm.didSave {
                Text("✅ Guardado")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.70))
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Privacidad del perfil")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.85))

            Text("Esto define quién puede ver tus entrenamientos en el feed.")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.55))

            Button {
                showPrivacyPicker = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color.appGreen.opacity(0.95))
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color.appGreen.opacity(0.12)))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(privacyTitle(vm.selectedFeedVisibility))
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundColor(.white.opacity(0.92))

                        Text(privacySubtitle(vm.selectedFeedVisibility))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.55))
                            .lineLimit(2)
                    }

                    Spacer()

                    if vm.isUpdatingPrivacy {
                        SwiftUI.ProgressView().tint(Color.appGreen.opacity(0.95))
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white.opacity(0.35))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(vm.isUpdatingPrivacy)
            .opacity(vm.isUpdatingPrivacy ? 0.7 : 1.0)
        }
        .padding(.top, 2)
    }

    private func privacyTitle(_ v: FeedVisibility) -> String {
        switch v {
        case .public: return "Público"
        case .friendsOnly: return "Solo amigos"
        case .private: return "Privado"
        }
    }

    private func privacySubtitle(_ v: FeedVisibility) -> String {
        switch v {
        case .public: return "Cualquiera puede ver tus entrenamientos."
        case .friendsOnly: return "Solo tus amigos pueden ver tus entrenamientos."
        case .private: return "Nadie más puede ver tus entrenamientos."
        }
    }

    private var topName: String {
        let n = vm.fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !n.isEmpty { return n }
        return vm.profile?.displayName ?? "Usuario"
    }

    private var avatarBig: some View {
        Group {
            if let ui = vm.avatarPreviewImage {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else if
                let urlStr = vm.profile?.avatarUrl,
                urlStr.lowercased().hasPrefix("http"),
                let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                        case .failure:
                            fallbackAvatar
                        case .empty:
                            fallbackAvatar.opacity(0.6)
                        @unknown default:
                            fallbackAvatar
                        }
                    }
                } else {
                    fallbackAvatar
                }
        }
        .frame(width: 56, height: 56)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
    }

    private var fallbackAvatar: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.10))
            Image(systemName: "person.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white.opacity(0.65))
        }
    }

    // MARK: - Requests

    private var requestsCard: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                Text("Solicitudes de amistad")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))

                Spacer()

                if vm.isLoading {
                    SwiftUI.ProgressView().tint(Color.appGreen.opacity(0.95))
                }
            }

            if vm.incomingRequests.isEmpty {
                Text("No tenés solicitudes pendientes.")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            } else {
                VStack(spacing: 10) {
                    ForEach(vm.incomingRequests) { u in
                        requestRow(u)
                    }
                }
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    private func requestRow(_ u: UserProfile) -> some View {
        HStack(spacing: 12) {

            ZStack {
                Circle().fill(Color.white.opacity(0.10))
                Image(systemName: "person.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.65))
            }
            .frame(width: 40, height: 40)
            .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))

            VStack(alignment: .leading, spacing: 3) {
                Text(u.displayName)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))
                    .lineLimit(1)

                Text(u.displaySubtitle)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(1)
            }

            Spacer()

            Button {
                Task { await vm.acceptRequest(from: u.uid) }
            } label: {
                Text("Aceptar")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .frame(height: 34)
                    .background(Capsule().fill(Color.appGreen.opacity(0.95)))
            }
            .buttonStyle(.plain)

            Button {
                Task { await vm.rejectRequest(from: u.uid) }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.75))
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white.opacity(0.06)))
                    .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.22))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    // MARK: - Logout

    private var actionsCard: some View {
        VStack(spacing: 10) {
            Button {
                showLogoutConfirm = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 14, weight: .bold))

                    Text("Cerrar sesión")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))

                    Spacer()
                }
                .foregroundColor(.white.opacity(0.92))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(cardBackground)
    }

    // MARK: - UI helpers

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
    }

    private func field(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.70))

            TextField(title, text: text)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.92))
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
        }
    }

    private func pickerRow(title: String, selection: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.70))

            Menu {
                ForEach(options, id: \.self) { opt in
                    Button(opt) { selection.wrappedValue = opt }
                }
            } label: {
                HStack {
                    Text(selection.wrappedValue)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.92))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.45))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }
}
