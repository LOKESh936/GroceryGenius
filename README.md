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
