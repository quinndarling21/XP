import SwiftUI

struct AddPathwayView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: PathwayViewModel
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedColorIndex = 0
    @State private var selectedEmoji = "✨"
    @State private var cadenceFrequency: CadenceFrequency = .none
    @State private var objectiveCount = 3
    @State private var showingEmojiPicker = false
    
    private var isValid: Bool {
        !name.isEmpty && 
        !description.isEmpty && 
        (cadenceFrequency == .none || (objectiveCount >= 1 && objectiveCount <= 50))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Pathway Details")) {
                    HStack {
                        Button(action: {
                            showingEmojiPicker = true
                        }) {
                            Text(selectedEmoji)
                                .font(.system(size: 32))
                                .frame(width: 44, height: 44)
                                .background(Color.secondary.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        TextField("Name", text: $name)
                    }
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Appearance")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<Pathway.pathwayColors.count, id: \.self) { index in
                                Circle()
                                    .fill(Pathway.pathwayColors[index])
                                    .frame(width: 40, height: 40)
                                    .overlay {
                                        if index == selectedColorIndex {
                                            Circle()
                                                .strokeBorder(.white, lineWidth: 3)
                                                .padding(2)
                                        }
                                    }
                                    .onTapGesture {
                                        selectedColorIndex = index
                                    }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section {
                    CadenceSettingsView(
                        frequency: $cadenceFrequency,
                        count: $objectiveCount
                    )
                }
                
                Section {
                    Button("Create Pathway") {
                        viewModel.addPathway(
                            name: name,
                            description: description,
                            colorIndex: selectedColorIndex,
                            emoji: selectedEmoji,
                            cadenceFrequency: cadenceFrequency,
                            objectivesCount: objectiveCount
                        )
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(!isValid)
                }
            }
            .navigationTitle("New Pathway")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEmojiPicker) {
                EmojiPickerView(selectedEmoji: $selectedEmoji)
            }
        }
    }
}

struct EmojiPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedEmoji: String
    
    // Emoji categories with descriptions
    private let emojiCategories: [(name: String, emojis: [String])] = [
        ("Activities", ["🎯", "⚽️", "🎾", "🏈", "🎮", "🎨", "🎭", "🎪", "🎤", "🎧", "🎼", "🎹", "🎸", "🎺", "🎻", "🎲", "🎳", "⛳️", "🎣", "🎽", "🎿", "🛷", "🥌", "🎱"]),
        ("Health & Fitness", ["🧘‍♀️", "🏃‍♀️", "🏋️‍♀️", "🤸‍♀️", "🚴‍♀️", "🏊‍♀️", "💪", "🧠", "🫀", "🧘‍♂️", "🏃‍♂️", "🏋️‍♂️", "🤸‍♂️", "🚴‍♂️", "🏊‍♂️"]),
        ("Learning", ["📚", "✏️", "📝", "💡", "🎓", "📖", "📕", "🔬", "🔭", "🎨", "🗣️", "🧮", "📐", "✍️", "🎯"]),
        ("Lifestyle", ["🌱", "🍳", "🏠", "💐", "🌿", "☕️", "🧋", "🥗", "🛁", "🛋️", "📱", "💻", "🎬", "📷", "🎵"]),
        ("Mindfulness", ["🧘‍♀️", "🌸", "🕊️", "☮️", "🌅", "🌊", "🍃", "🌺", "✨", "💫", "🌙", "⭐️", "🌟", "💭", "🕯️"]),
        ("Productivity", ["⏰", "📅", "✓", "📊", "📈", "💼", "📱", "💻", "✉️", "📝", "✏️", "📌", "🎯", "⚡️", "💡"]),
        ("Goals", ["🎯", "🏆", "🌟", "💫", "⭐️", "🔥", "💪", "🚀", "🎨", "📈", "💡", "✨", "🌈", "🎉", "🎊"]),
        ("Nature", ["🌱", "🌲", "🌺", "🌸", "🌼", "🌻", "🌹", "🍀", "🌿", "🍃", "🌎", "🌍", "🌏", "☘️", "🌳"]),
        ("Fun", ["🎉", "🎊", "🎈", "🎨", "🎭", "🎪", "🎢", "🎡", "🎠", "🎮", "🎲", "🎯", "🎳", "🎤", "🎧"])
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                ForEach(emojiCategories, id: \.name) { category in
                    VStack(alignment: .leading) {
                        Text(category.name)
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 45))],
                            spacing: 12
                        ) {
                            ForEach(category.emojis, id: \.self) { emoji in
                                Button(action: {
                                    selectedEmoji = emoji
                                    dismiss()
                                }) {
                                    Text(emoji)
                                        .font(.system(size: 30))
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Select Emoji")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Preview provider
struct AddPathwayView_Previews: PreviewProvider {
    static var previews: some View {
        AddPathwayView(viewModel: PathwayViewModel())
    }
} 