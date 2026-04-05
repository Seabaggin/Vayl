//
//  PairingSettingsView.swift
//  Open Lightly
//
//  Pairing settings and partner code management
//

import SwiftUI

struct PairingSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var pairingCode: String = "AX7-QM2"
    @State private var showPairingCopied: Bool = false
    @State private var partnerCode: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Your Pairing Code Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("YOUR CODE")
                            .font(AppFonts.sectionLabelSmall)
                            .foregroundStyle(AppColors.textMuted)
                        
                        Text("Share this code with your partner so they can link their app to yours.")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textTertiary)
                        
                        // Pairing code display
                        HStack(spacing: 12) {
                            Text(pairingCode)
                                .font(AppFonts.scoreDisplay)
                                .foregroundColor(AppColors.cyan)
                                .kerning(2)
                            
                            Spacer()
                            
                            Button {
                                UIPasteboard.general.string = pairingCode
                                withAnimation { showPairingCopied = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation { showPairingCopied = false }
                                }
                            } label: {
                                Image(systemName: showPairingCopied ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(showPairingCopied ? AppColors.success : AppColors.textSecondary)
                            }
                        }
                        .padding(14)
                        .cardStyle(background: AppColors.surfaceBg, cornerRadius: 10)
                    }
                    
                    // Enter Partner Code Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PARTNER'S CODE")
                            .font(AppFonts.sectionLabelSmall)
                            .foregroundStyle(AppColors.textMuted)
                        
                        Text("Enter your partner's code to link your accounts.")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textTertiary)
                        
                        InteractiveField(
                            placeholder: "Enter partner's code",
                            icon: "link",
                            text: $partnerCode
                        )
                        
                        GradientButton(title: "Link Partner") {
                            // Pairing logic implementation pending
                        }
                    }
                    
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Partner Pairing")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    PairingSettingsView()
        .preferredColorScheme(.dark)
}
