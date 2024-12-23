import SwiftUI

struct DebugTimeView: View {
    @State private var currentTime = Date.now
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            Text("Test Time: \(timeString(from: currentTime))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .onReceive(timer) { _ in
            currentTime = Date.now
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}