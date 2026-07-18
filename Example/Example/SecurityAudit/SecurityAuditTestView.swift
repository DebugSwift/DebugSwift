//
//  SecurityAuditTestView.swift
//  Example
//
//  Created by Matheus Gois on 16/07/26.
//

import DebugSwift
import SwiftUI

/// A demo view that seeds insecure storage so the DebugSwift **Security Audit**
/// panel has real findings to display.
///
/// The auditor checks four sources:
/// 1. **UserDefaults** — any key matching `key|secret|token|password|apikey|api_key`
///    with a non-empty `String` value → `.warning`.
/// 2. **Info.plist** — same pattern on `Bundle.main.infoDictionary`.
/// 3. **Bundle** — files with `.cer/.p12/.mobileconfig/.pem/.key` extensions → `.critical`.
/// 4. **Keychain** — items with `AfterFirstUnlock`/`Always` accessibility → `.info`.
///
/// This view seeds (1) so findings appear immediately — the
/// `SecurityAuditorAdapter` currently returns `[:]` for keychain, but
/// UserDefaults findings will show up as soon as you refresh the audit.
@available(iOS 15.0, *)
struct SecurityAuditTestView: View {
    @State private var seeded = false
    @State private var cleared = false

    private let sensitiveDefaults: [(String, String)] = [
        ("api_key", "sk-1234567890abcdef"),
        ("user_token", "eyJhbGciOiJIUzI1NiJ9.test.signature"),
        ("password", "hunter2"),
        ("secret_phrase", "open-sesame")
    ]

    var body: some View {
        Form {
            Section(header: Text("Seed Insecure Data")) {
                Text("Tap below to write sensitive keys into UserDefaults. These will be flagged as warnings by the Security Audit.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("Seed Sensitive UserDefaults") {
                    for (key, value) in sensitiveDefaults {
                        UserDefaults.standard.set(value, forKey: key)
                    }
                    seeded = true
                    cleared = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(seeded && !cleared)

                if seeded && !cleared {
                    Label("UserDefaults seeded — run the audit to see findings", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }

            Section(header: Text("Clean Up")) {
                Text("Remove the seeded keys so the audit is clean again.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("Clear Seeded Data") {
                    for (key, _) in sensitiveDefaults {
                        UserDefaults.standard.removeObject(forKey: key)
                    }
                    cleared = true
                    seeded = false
                }
                .buttonStyle(.bordered)
                .disabled(!seeded)
            }

            Section(header: Text("How to Test")) {
                Text("1. Seed the sensitive UserDefaults above.")
                Text("2. Open the DebugSwift floating ball → Resources → Security Audit.")
                Text("3. Pull to refresh — you should see warning findings for each key.")
                Text("4. Come back here and clear the data, then refresh the audit — findings should disappear.")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .navigationTitle("Security Audit Test")
    }
}
