//
//  GalleryView.swift
//  LocalPhotosApp
//
//  Created by Ralph
//

import SwiftUI
import Photos

struct GalleryView: View {
    @StateObject private var permissionManager = PhotoLibraryPermissionManager()

    var body: some View {
        NavigationStack {
            Group {
                switch permissionManager.authorizationStatus {
                case .notDetermined:
                    PermissionRequestView(permissionManager: permissionManager)
                case .authorized, .limited:
                    AuthorizedGalleryContent(isLimited: permissionManager.authorizationStatus == .limited)
                case .denied, .restricted:
                    PermissionDeniedView(permissionManager: permissionManager)
                @unknown default:
                    Text("Unknown permission state")
                }
            }
            .navigationTitle("Gallery")
        }
    }
}

struct PermissionRequestView: View {
    @ObservedObject var permissionManager: PhotoLibraryPermissionManager

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Access Your Photos")
                .font(.title2)
                .fontWeight(.semibold)

            Text(permissionManager.statusMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Allow Photo Access") {
                Task {
                    await permissionManager.requestAuthorization()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct PermissionDeniedView: View {
    @ObservedObject var permissionManager: PhotoLibraryPermissionManager

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Photo Access Required")
                .font(.title2)
                .fontWeight(.semibold)

            Text(permissionManager.statusMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Open Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct AuthorizedGalleryContent: View {
    let isLimited: Bool

    var body: some View {
        VStack {
            if isLimited {
                HStack {
                    Image(systemName: "info.circle")
                    Text("Limited access - Some photos may not be visible")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            }

            Text("Gallery content will be displayed here")
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(.top)
    }
}

#Preview {
    GalleryView()
}
