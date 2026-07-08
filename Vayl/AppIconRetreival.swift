////
////  AppIconRetreival.swift
////  Open Lightly
////
////  Created by Bryan Jorden on 4/26/26.
////
//
// import SwiftUI
//
// func exportIcon() {
//    let sizes: [CGFloat] = [1024, 180, 120, 87, 80, 60, 58, 40, 29]
//    for size in sizes {
//        let renderer = ImageRenderer(content: VaylAppIcon(size: size))
//        renderer.scale = 1.0
//        if let uiImage = renderer.uiImage,
//           let data = uiImage.pngData() {
//            let url = URL(fileURLWithPath: "/Users/bryanjorden/Desktop/VaylAppIcon-\(Int(size)).png")
//            try? data.write(to: url)
//            print("Saved: \(url)")
//        }
//    }
// }
//
// struct AppIconExportView: View {
//    var body: some View {
//        Text("Exporting...")
//            .onAppear {
//                exportIcon()
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//                        .appendingPathComponent("VaylAppIcon-1024.png")
//                    let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
//                    UIApplication.shared.connectedScenes
//                        .compactMap { $0 as? UIWindowScene }
//                        .first?.windows.first?.rootViewController?
//                        .present(av, animated: true)
//                }
//            }
//    }
// }
