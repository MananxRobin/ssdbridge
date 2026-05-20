import SwiftUI

/// Form for creating magic links with all options.
struct CreateLinkView: View {
    @EnvironmentObject var appState: AppState

    @State private var scopePath = "/Volumes"
    @State private var ttlMinutes = "15"
    @State private var oneTimeJoin = false
    @State private var password = ""
    @State private var permissions = "read"
    @State private var encrypted = false
    @State private var createdLink: (token: Token, url: String)?
    @State private var copied = false
    @State private var selectedPreset: String? = nil
    @State private var showSavePresetAlert = false
    @State private var presetName = ""

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 16) {
                // Preset picker
                if !appState.linkPresets.isEmpty {
                    Picker("Preset", selection: $selectedPreset) {
                        Text("None").tag(nil as String?)
                        ForEach(appState.linkPresets) { preset in
                            Text(preset.name).tag(preset.id as String?)
                        }
                    }
                    .onChange(of: selectedPreset) { newId in
                        if let id = newId, let preset = appState.linkPresets.first(where: { $0.id == id }) {
                            scopePath = preset.scopePath
                            ttlMinutes = String(preset.ttlMinutes)
                            oneTimeJoin = preset.oneTimeJoin
                            password = preset.password ?? ""
                            permissions = preset.permissions
                            encrypted = preset.encrypted
                        }
                    }
                }

                // Scope path
                HStack {
                    Text("Shared Path")
                        .frame(width: 100, alignment: .trailing)
                    TextField("/Volumes or /path/to/folder", text: $scopePath)
                        .textFieldStyle(.roundedBorder)
                    Button("Browse…") {
                        browseFolder()
                    }
                }

                // TTL + One-time
                HStack {
                    Text("Expires in")
                        .frame(width: 100, alignment: .trailing)
                    TextField("15", text: $ttlMinutes)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                    Text("minutes")
                        .foregroundColor(.secondary)

                    Spacer().frame(width: 24)

                    Toggle("One-time use", isOn: $oneTimeJoin)
                }

                // Password
                HStack {
                    Text("Password")
                        .frame(width: 100, alignment: .trailing)
                    SecureField("Leave empty for no password", text: $password)
                        .textFieldStyle(.roundedBorder)
                }

                // Permissions toggle
                HStack {
                    Text("Permissions")
                        .frame(width: 100, alignment: .trailing)
                    Picker("", selection: $permissions) {
                        Label("Read Only", systemImage: "eye")
                            .tag("read")
                        Label("Read & Write", systemImage: "pencil")
                            .tag("readwrite")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 250)
                }

                // E2E Encryption toggle
                HStack {
                    Text("Encryption")
                        .frame(width: 100, alignment: .trailing)
                    Toggle("End-to-End Encrypted", isOn: $encrypted)
                    if encrypted {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.green)
                    }
                }

                // Create / Save buttons
                HStack {
                    Button {
                        showSavePresetAlert = true
                    } label: {
                        Label("Save Preset…", systemImage: "bookmark")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Spacer()

                    Button {
                        createLink()
                    } label: {
                        Label("Generate Link", systemImage: "sparkles")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!appState.isServerRunning)
                }

                // Created link display
                if let created = createdLink {
                    Divider()
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Link created!")
                            .fontWeight(.semibold)

                        // Link type badge
                        if appState.isGlobalLinkMode {
                            Label("Global", systemImage: "globe.americas.fill")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.15))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        } else {
                            Label("LAN", systemImage: "wifi")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.15))
                                .foregroundColor(.secondary)
                                .cornerRadius(4)
                        }
                    }

                    HStack {
                        Text(created.url)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(8)
                            .background(Color(nsColor: .textBackgroundColor))
                            .cornerRadius(6)

                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(created.url, forType: .string)
                            copied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                copied = false
                            }
                        } label: {
                            Label(copied ? "Copied!" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                        }
                    }

                    HStack(spacing: 12) {
                        Text("Expires: \(created.token.timeRemaining)")
                            .foregroundColor(.secondary)
                        if created.token.hasPassword {
                            Label("Password", systemImage: "lock.fill")
                                .foregroundColor(.orange)
                        }
                        if created.token.oneTimeJoin {
                            Label("One-time", systemImage: "key.fill")
                                .foregroundColor(.blue)
                        }
                        Text(created.token.permissions == "readwrite" ? "✏️ Read & Write" : "👁️ Read Only")
                            .foregroundColor(created.token.permissions == "readwrite" ? .purple : .blue)
                        if created.token.encrypted {
                            Label("Encrypted", systemImage: "lock.shield.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .font(.caption)

                // QR Code
                if let qrImage = generateQRImage(from: created.url) {
                    Divider()
                    HStack {
                        Spacer()
                        Image(nsImage: qrImage)
                            .resizable()
                            .interpolation(.none)
                            .frame(width: 140, height: 140)
                        Spacer()
                    }
                    Text("Scan to join")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                }
            }
        } label: {
            Label("Create Magic Link", systemImage: "link.badge.plus")
        }
        .alert("Save Preset", isPresented: $showSavePresetAlert) {
            TextField("Preset name", text: $presetName)
            Button("Save") {
                guard !presetName.isEmpty else { return }
                let ttl = Int(ttlMinutes) ?? Config.defaultTTLMinutes
                let pwd = password.isEmpty ? nil : password
                let preset = LinkPreset(
                    name: presetName,
                    scopePath: scopePath,
                    ttlMinutes: ttl,
                    oneTimeJoin: oneTimeJoin,
                    password: pwd,
                    permissions: permissions,
                    encrypted: encrypted
                )
                appState.savePreset(preset)
                presetName = ""
            }
            Button("Cancel", role: .cancel) { presetName = "" }
        } message: {
            Text("Save current form fields as a reusable link preset.")
        }
    }

    // MARK: - Helpers

    private func generateQRImage(from string: String) -> NSImage? {
        guard let data = string.data(using: .utf8) else { return nil }
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
        let rep = NSCIImageRep(ciImage: scaled)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        return nsImage
    }

    // MARK: - Actions

    private func createLink() {
        let ttl = Int(ttlMinutes) ?? Config.defaultTTLMinutes
        let pwd = password.isEmpty ? nil : password
        let token = appState.createLink(
            scopePath: scopePath,
            ttlMinutes: ttl,
            oneTimeJoin: oneTimeJoin,
            password: pwd,
            permissions: permissions,
            encrypted: encrypted
        )
        var url = appState.buildLinkURL(token: token)
        if encrypted {
            // Generate a random 256-bit key and append as URL fragment
            let keyBytes = (0..<32).map { _ in UInt8.random(in: 0...255) }
            let keyBase64 = Data(keyBytes).base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
            url += "#key=\(keyBase64)"
        }
        createdLink = (token, url)
        password = ""
    }

    private func browseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Select Folder"
        if panel.runModal() == .OK, let url = panel.url {
            scopePath = url.path
        }
    }
}
