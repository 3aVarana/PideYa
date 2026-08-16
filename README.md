# AppName 🛍️✨

[![Swift](https://img.shields.io/badge/Swift-5.10%2B-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-17.0%2B-blue.svg)](https://developer.apple.com/ios/)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20%2F%20TCA%20%2F%20MVVM--C-lightgrey.svg)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

An intelligent iOS e-commerce application leveraging edge machine learning and LLM integrations to provide personalized discovery, visual search, and conversational shopping assistance.

---

## 🌟 Key Features

* **Visual Search & Product Matching:** Real-time on-device object detection and image embedding search using Core ML & Vision framework.
* **Conversational AI Stylist / Assistant:** Streaming chat interface powered by an LLM backend (OpenAI / Claude / Gemini / Private Gateway) with tool-calling for direct checkout and cart management.
* **Smart Personalization:** Dynamic product ranking based on on-device user interaction signals without compromising privacy.
* **Augmented Reality Preview:** AR Quick Look / RealityKit support for in-room 3D product previews.
* **Seamless Checkout:** Native Apple Pay integration and secure tokenized payment flows.

---

## 🏛️ Architecture & Tech Stack

```
├── App/                      # App entry point & App Delegate/Scene lifecycle
├── Core/
│   ├── Network/              # URLSession / async-await network client + SSE streaming
│   ├── Storage/              # SwiftData / Keychain / CoreData persistent layers
│   └── DesignSystem/         # Reusable UI tokens, components, and modifiers
├── Features/
│   ├── Catalog/              # Product browsing & dynamic discovery
│   ├── VisualSearch/         # Vision / Core ML camera pipeline
│   ├── AIChat/               # LLM streaming assistant & tool execution
│   └── Cart/                 # State management & Apple Pay integration
└── AI/
    ├── OnDevice/             # Core ML models (.mlpackage), Vision classifiers
    └── Services/             # AI gateway clients & schema definitions
```

### Core Technologies
* **UI & State:** SwiftUI, Swift Concurrency (`async/await`, `AsyncStream`), SwiftData
* **Edge ML:** Core ML, Vision Framework, Accelerate (Vector similarity/embeddings)
* **Cloud AI:** Server-Sent Events (SSE) for token streaming, Function Calling / Structured Outputs JSON
* **Dependency Management:** Swift Package Manager (SPM)

---

## 🚀 Getting Started

### Prerequisites
* macOS Sonoma (14.0+) or higher
* Xcode 15.3+
* iOS 17.0+ deployment target
* CocoaPods / Bundler (if applicable, else pure SPM)

### Environment Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-org/app-name.git
   cd app-name
   ```

2. **Configure Environment Secrets:**
   Copy the example configuration file and populate your keys:
   ```bash
   cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig
   ```
   > **Note:** Never commit production API keys to the repository. The app expects an internal backend gateway proxy for LLM calls in production.

3. **Install Dependencies & Open:**
   ```bash
   open AppName.xcodeproj
   ```

---

## 🤖 AI & Machine Learning Pipeline

### 1. Visual Search (On-Device)
* Uses a mobile-optimized embedding model (`MobileNetV4` / quantized `CLIP`) running via Core ML.
* Frame processing uses `AVCaptureSession` combined with `VNImageRequestHandler` for low-latency visual feature extraction.

### 2. Conversational Agent (Backend / Gateway)
* Utilizes a secure proxy to forward structured user queries to the LLM backend.
* Implements SSE for character-by-character UI rendering.
* Handles Function Calling schemas:
  * `addToCart(productId: String, quantity: Int)`
  * `queryProductAvailability(sku: String)`
  * `applyDiscountCode(code: String)`

---

## 🔒 Privacy & Security

* **Zero Direct Client-to-LLM Keys:** Direct vendor API keys are not embedded in the client binary. All AI traffic routes through an authenticated gateway.
* **On-Device Data Processing:** Visual search indexing and user behavioral clustering stay strictly on-device.
* **Sensitive Data:** Payment and address tokens are managed strictly via Apple Pay and Keychain Services.

---

## 🧪 Testing & Code Quality

* **Unit Tests:** `Cmd + U` runs domain logic, view model state transitions, and mocked streaming parsers.
* **UI / Snapshot Tests:** Swift Snapshot Testing for design system regressions.
* **Linting:** SwiftLint / SwiftFormat configured via build phase scripts.

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.
