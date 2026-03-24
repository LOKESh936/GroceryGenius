# 🛒 GroceryGenius — Intelligent Grocery & Meal Planning iOS App

GroceryGenius is a **modern, production-grade iOS application** designed to simplify grocery management and meal planning using **AI-assisted workflows**, **offline-first architecture**, and **scalable SwiftUI patterns**.
Live App: https://apps.apple.com/us/app/grocerygenius-smart-groceries/id6758969627
This project demonstrates real-world iOS engineering practices, focusing on **clean architecture**, **data consistency**, **performance**, and **maintainability**.

---

## ✨ Key Highlights

- AI-powered meal planning with ingredient extraction
- Smart grocery list management with deduplication
- Recipe creation, editing, tagging, and search
- Offline-first data handling with conflict-safe syncing
- Clean MVVM architecture with SwiftUI & Combine
- Firestore-backed cloud persistence
- Designed with Apple Human Interface Guidelines (HIG)

---

## 🚀 Features

### 🧠 AI Meal Assistant
- Conversational AI for generating meal ideas
- Structured parsing of AI responses into ingredients
- One-tap ingredient import into grocery list
- Session-based AI conversations stored in Firestore

---

### 🛍️ Grocery Management
- Centralized grocery list per user
- Quantity tracking and item normalization
- Intelligent deduplication (case-insensitive, semantic)
- Instant UI updates with local-first writes
- Cloud synchronization with Firestore

---

### 📚 Recipe Management
- Create and edit recipes with ingredients
- Reusable ingredient editor UI
- Tag-based filtering and search
- Sorting by recency or alphabetical order
- Shared UI components between create/edit flows

---

### 🔄 Offline-First & Data Consistency
- Optimistic UI updates for responsiveness
- Firestore batch writes for efficiency
- Conflict-aware updates when reconnecting
- Designed for eventual consistency
- Single source of truth enforced at ViewModel level

---

## 🧱 Architecture Overview

GroceryGenius follows **MVVM with clear separation of concerns**, optimized for SwiftUI.

### Architecture Principles
- Declarative UI with SwiftUI
- ViewModels as state owners
- Business logic isolated from UI
- Thread safety using `@MainActor` and structured concurrency
- Predictable state updates via Combine

SwiftUI View
↓
ViewModel (@MainActor, ObservableObject)
↓
Service Layer (Firestore / AI / Persistence)
↓
Models (Codable, Equatable, Identifiable)

yaml
Copy code

---

## 🧩 State Management

- `ObservableObject` + `@Published` for UI updates
- Combine pipelines for derived state
- Explicit ownership of mutable state
- No shared mutable state across views
- Clear lifecycle boundaries for async tasks

---

## 🔥 Firestore Data Model

```text
users/{uid}
 ├── groceryItems/{itemId}
 │     ├── name: String
 │     ├── quantity: String
 │     ├── updatedAt: Timestamp
 │
 ├── recipes/{recipeId}
 │     ├── title: String
 │     ├── ingredients: [Ingredient]
 │     ├── tags: [String]
 │     ├── createdAt: Timestamp
 │     ├── updatedAt: Timestamp
 │
 └── aiMeals/{conversationId}
       ├── createdAt: Timestamp
       ├── updatedAt: Timestamp
       └── messages/{messageId}
            ├── text: String
            ├── isUser: Bool
            ├── createdAt: Timestamp
Design Notes
One AI conversation per app session

Subcollections used for scalability

Timestamps used for ordering & conflict resolution

Designed to support future multi-device sync

🧪 Offline & Sync Strategy
Local state updates immediately reflect in UI

Firestore writes queued automatically when offline

Batched updates reduce network overhead

Latest-write-wins conflict strategy

Designed to evolve toward versioned conflict resolution

🧰 Tech Stack
Language: Swift

UI Framework: SwiftUI

Architecture: MVVM

Reactive Layer: Combine

Backend: Firebase Firestore

Authentication: Firebase Auth

Concurrency: Swift Concurrency (async/await, @MainActor)

Testing: XCTest (ViewModel-focused)

Tools: Xcode, Git

🎨 UI & Design
Apple Human Interface Guidelines compliant

System fonts & dynamic type support

Reusable UI components

Clear visual hierarchy

Accessibility-ready structure

🛠️ Setup Instructions
Prerequisites
Xcode 16+

iOS 17+

Firebase project

Steps
Clone the repository

bash
Copy code
git clone https://github.com/your-username/GroceryGenius.git
Open the project

bash
Copy code
open GroceryGenius.xcodeproj
Configure Firebase

Add GoogleService-Info.plist

Enable Firestore

Enable Firebase Authentication

Build & Run 🚀

🧪 Testing Strategy
ViewModel unit tests

Deterministic business logic

Mocked service layers

Designed for easy expansion to UI tests

📌 Future Enhancements
Shared grocery lists (multi-user)

Nutrition and calorie tracking

Siri & Shortcuts integration

Recipe recommendations

Cloud Functions for AI post-processing

Advanced conflict resolution strategies

🎯 Project Goals
Demonstrate real-world iOS engineering

Showcase SwiftUI + Firebase architecture

Highlight offline-first design decisions

Serve as a portfolio-quality production app

👨‍💻 Author
Lokeshwar Reddy
Senior iOS Engineer

Expertise:
Swift • SwiftUI • UIKit • Combine • Firebase • MVVM • Offline-first systems

📄 License
This project is for educational and portfolio purposes.

