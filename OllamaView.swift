import SwiftUI

// MARK: - Ollama Service
class OllamaService: ObservableObject {
    @Published var response: String = ""
    @Published var isLoading: Bool = false

    func ask(_ prompt: String) {
        isLoading = true
        response = ""
        guard let url = URL(string: "http://localhost:11434/api/generate") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "model": "gemma2:2b",
            "prompt": prompt,
            "stream": false
        ])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, _, _ in
            DispatchQueue.main.async {
                self.isLoading = false
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let text = json["response"] as? String {
                    self.response = text
                } else {
                    self.response = "⚠️ Make sure Ollama is running"
                }
            }
        }.resume()
    }
}

// MARK: - Ollama Chat View
struct OllamaView: View {
    @StateObject private var service = OllamaService()
    @State private var prompt: String = ""

    var body: some View {
        VStack(spacing: 8) {
            ScrollView {
                Text(service.isLoading ? "Thinking..." : service.response)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
            }
            .frame(maxHeight: 150)
            .background(Color.black.opacity(0.3))
            .cornerRadius(10)

            HStack {
                TextField("Ask anything...", text: $prompt)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .onSubmit { sendMessage() }

                // Study Mode Toggle Button
                Button(action: { NSApp.hide(nil) }) {
                    Image(systemName: "book.closed.fill")
                        .foregroundColor(.orange)
                }
                .help("Study Mode: Hide notch")
            }
        }
        .padding(10)
    }

    private func sendMessage() {
        guard !prompt.isEmpty else { return }
        let msg = prompt
        prompt = ""
        service.ask(msg)
    }
}