# GroceryGenius 🍎  
AI Meal Planner & Smart Grocery List (iOS, SwiftUI)

GroceryGenius is an iOS app that helps you plan meals and manage your groceries with a little help from AI.

- 💬 Chat-style AI meal planner (OpenAI Chat Completions, streaming)
- 📝 Smart grocery list
- 🎙 Voice input for prompts (speech-to-text)
- 🎨 Clean SwiftUI design with a consistent color system

> Built as a learning + portfolio project to practice real-world iOS development: SwiftUI, MVVM, async/await, networking, and AI integration.

---

## Tech Stack

- **Language:** Swift 5+
- **UI:** SwiftUI
- **Architecture:** MVVM
- **Networking:** `URLSession` + `async/await`
- **AI:** OpenAI Chat Completions API (streaming responses)
- **Audio / Speech:** `AVFoundation`, `Speech` framework
- **Minimum iOS:** 17.0 (can be adjusted if needed)
- **IDE:** Xcode 16+

---

## Features

### ✅ AI Meals (Chat Screen)

- WhatsApp-style chat bubbles for **user** and **AI** messages
- **Streaming responses** from the OpenAI API (characters appear as they’re generated)
- Automatic **auto-scroll to bottom** while a response is streaming
- AI answers formatted in **clean, structured Markdown**:
  - Headings like `Day 1`, `Breakfast`, `Lunch`, `Dinner`
  - Bullet points for ingredients and steps
  - Short, readable sections
- A “magic” button that sends a pre-built prompt like  
  _“Make me a quick balanced meal plan for today.”_

### ✅ Voice Input

- Tap the mic icon to dictate your meal request
- Speech recognition converts your voice to text and drops it into the input field
- Uses Apple’s `AVAudioSession` + `SFSpeechRecognizer`

### ✅ Smart UI & Theming

All screens share the same app-wide color palette:

```swift
struct AppColor {
    static let primary   = Color(hex: "#628141") // deep green
    static let secondary = Color(hex: "#8BAE66") // lighter green
    static let accent    = Color(hex: "#E67E22") // orange
    static let background = Color(hex: "#EBD5AB") // warm beige
}
Chat bubbles, buttons, tab bar, and background all use this palette

Uses SwiftUI’s Capsule, RoundedRectangle, blur materials and subtle shadows

Layout follows Apple HIG: generous spacing, readable fonts, clear hierarchy

✅ Screens (High Level)

HomeView – overview cards / entry point

GroceryListView – list of grocery items using GroceryItem model

AIFoodView – chat-style AI meal planner screen

RecipesView – placeholder for recipe browsing (future APIs)

SettingsView – app settings / debug options

Project Structure
GroceryGenius/
├── App/
│   └── GroceryGeniusApp.swift        # App entry point
├── Components/
│   ├── GlassButton.swift
│   ├── GroceryRowView.swift
│   ├── HomeCardView.swift
│   ├── MarkdownText.swift            # Renders Markdown in SwiftUI
│   ├── MessageBubbleView.swift       # Chat bubbles (user + AI)
│   ├── TypingBubbleView.swift        # Three-dot “AI is typing” bubble
│   └── VoiceInputManager.swift       # Speech recognition manager
├── Helpers/
│   ├── AppColor.swift                # Global color palette
│   └── Color+HEX.swift               # Hex → Color helper
├── Models/
│   ├── AIMsg.swift                   # Chat message model (id, text, isUser)
│   └── GroceryItem.swift
├── ViewModels/
│   ├── AIViewModel.swift             # Handles AI chat + streaming
│   └── GroceryViewModel.swift
└── Views/
    ├── AIFoodView.swift              # AI Meals chat UI
    ├── ContentView.swift             # TabView & navigation
    ├── GroceryListView.swift
    ├── HomeView.swift
    ├── RecipesView.swift
    └── SettingsView.swift

AI Integration (Streaming Chat)

The AI integration lives in AIViewModel:

Builds a request to https://api.openai.com/v1/chat/completions

Uses the "gpt-4.1-mini" (or similar) chat model

Enables "stream": true to receive Server-Sent Events (SSE)

Parses each data: line, decodes the delta.content from the stream, and appends it to:

@Published var streamingText: String
@Published var isStreaming: Bool


The UI (AIFoodView) observes these properties:

While isStreaming == true:

Shows a typing bubble if streamingText is empty

Shows a “building” AI bubble when streamingText contains partial content

When the stream ends:

The final streamingText is appended to messages as a full AI message

Auto-scroll is handled with ScrollViewReader + onChange on messages.count and streamingText.

Voice Input

VoiceInputManager wraps the speech recognition logic:

Requests speech recognition permission (SFSpeechRecognizer.requestAuthorization)

Configures AVAudioSession for recording

Streams the microphone buffer to SFSpeechAudioBufferRecognitionRequest

Calls a closure with the best transcription so the text field can be populated live

Don’t forget to add these to Info.plist:

NSSpeechRecognitionUsageDescription

NSMicrophoneUsageDescription

Example descriptions:

“GroceryGenius uses speech recognition so you can dictate meal requests hands-free.”
“GroceryGenius uses the microphone to capture your voice for meal planning.”

Getting Started
1. Requirements

Xcode 16+

iOS 17+ simulator or device

An OpenAI API key (from the OpenAI dashboard)

2. Clone the Project
git clone https://github.com/<your-username>/GroceryGenius.git
cd GroceryGenius


Open GroceryGenius.xcodeproj (or .xcworkspace if you add CocoaPods/SPM packages later) in Xcode.

3. Configure Secrets (OpenAI API Key)

The app expects the API key in a build configuration file and Info.plist.

Create a file named Secrets.xcconfig at the project root (if it doesn’t already exist):

// Secrets.xcconfig
OPENAI_API_KEY = sk-xxxx...your-key-here...


In Xcode, select the project → Build Settings → search for OPENAI_API_KEY.
Make sure the User-Defined setting is not hard-coded, but instead reads from:

${OPENAI_API_KEY}


In Info.plist, add a new key:

Key: OPENAI_API_KEY

Type: String

Value: $(OPENAI_API_KEY)

Important:

Do not commit your actual API key.

Add Secrets.xcconfig to .gitignore if this is a public repo.

4. Run the App

Choose an iOS Simulator (e.g. iPhone 13 mini).

Press Run (⌘R).

Go to the “AI Meals” tab:

Try tapping a quick prompt

Or type / dictate your own question and hit the send button

Roadmap

The project is being built in “weeks” as a learning roadmap:

Week 1 – Foundations: SwiftUI basics, MVVM, folder structure

Week 2 – Authentication: Firebase Auth (Apple / Google / Guest)

Week 3 – Grocery List: Firestore CRUD, offline list, swipe actions

Week 4 – AI Integration: (current stage) ChatGPT-style AI meal planner

Week 5 – Recipes: Integration with real recipe APIs (Spoonacular, Edamam, etc.)

Week 6 – Polish: Animations, blur, dark mode, final UI tweaks

Week 7 – App Store: App Store Connect, screenshots, TestFlight

Week 8 – Pro: Premium features (reminders, shared lists, price comparison, etc.)

Acknowledgements

OpenAI for the chat completion API

Apple’s SwiftUI, AVFoundation, and Speech frameworks

Icons and ideas inspired by modern grocery / meal planning apps

GroceryGenius is primarily a learning & portfolio project, but the goal is to keep the codebase clean enough that it could grow into a real App Store app over time.
