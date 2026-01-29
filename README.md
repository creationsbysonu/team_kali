# Sewa Sathi - Digital Government Services App

<p align="center">
  <img src="assets/images/app_logo.png" alt="Sewa Sathi Logo" width="120"/>
</p>

<p align="center">
  <strong>सेवा साथी</strong> - Your companion for government services
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#getting-started">Getting Started</a> •
  <a href="#project-structure">Project Structure</a> •
  <a href="#api-integration">API Integration</a>
</p>

---

## 📱 Overview

**Sewa Sathi** is a mobile application designed to streamline access to government services in Nepal. It provides citizens with a digital queue management system, AI-powered assistance, community engagement features, and real-time government notices - all in one place.

### 🎯 Mission
To reduce wait times, increase transparency, and improve citizen engagement with government services through digital transformation.

---

## ✨ Features

### 🎟️ Digital Queue Management
- **Get Token**: Book tokens for government services from ministries
- **View My Tokens**: Track your booked tokens and queue status
- **Real-time Updates**: Live queue position and estimated wait times
- **Multiple Booking Types**: Regular, Pre-booked, and Emergency tokens
- **Service Details**: View required documents, office hours, and service process

### 🤖 AI-Powered Chat Assistant
- Natural language queries about government services
- Context-aware responses with source citations
- Links to official notices and documents
- Multi-turn conversation support

### 📢 Government Notices
- Real-time official announcements
- Filter by ministry and category
- Detailed notice view with attachments
- Search functionality

### 🏘️ Community Features
- **Issues**: Report local problems (roads, sanitation, etc.)
- **Ideas**: Share suggestions for community improvement
- **AI Image Moderation**: Automatic content filtering
- **Local Storage**: Offline-first with Hive database

### 👤 User Profile
- OTP-based authentication via email
- Location-based service discovery
- Profile management

---

## 🏗️ Architecture

This project follows **Clean Architecture** with feature-first organization:

```
┌─────────────────────────────────────────────────────────────┐
│                     PRESENTATION                            │
│  (Widgets, Pages, BLoC - UI logic and state management)     │
├─────────────────────────────────────────────────────────────┤
│                        DOMAIN                               │
│  (Entities, Repositories [Abstract], Use Cases)             │
├─────────────────────────────────────────────────────────────┤
│                         DATA                                │
│  (Models, Data Sources, Repository Implementations)         │
└─────────────────────────────────────────────────────────────┘
```

### Key Architectural Decisions

| Component | Technology | Purpose |
|-----------|------------|---------|
| State Management | `flutter_bloc` | Predictable state with separation of concerns |
| Dependency Injection | `get_it` | Service locator for loose coupling |
| HTTP Client | `dio` | Powerful HTTP client with interceptors |
| Error Handling | `dartz` | Functional Either type for explicit errors |
| Local Storage | `hive` | Fast NoSQL database for offline data |
| Secure Storage | `flutter_secure_storage` | JWT tokens and sensitive data |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `^3.10.4`
- Dart SDK `^3.10.4`
- Android Studio / VS Code
- Physical device or emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/sewa_sathi.git
   cd sewa_sathi
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API endpoints**
   
   Update the base URL in `lib/core/constants/api_endpoints.dart`:
   ```dart
   // For physical device: use your computer's local IP
   static const String baseUrl = 'http://YOUR_IP:8000';
   
   // For emulator
   static const String baseUrl = 'http://10.0.2.2:8000';
   ```

4. **Run the app**
   ```bash
   # For Android
   flutter run -d <device_id>
   
   # For iOS
   flutter run -d <ios_device>
   
   # For Web
   flutter run -d chrome
   ```

### Build for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

---

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point
├── app/
│   ├── app.dart                 # Root MaterialApp widget
│   └── app_bloc_observer.dart   # BLoC debugging observer
│
├── core/
│   ├── auth/
│   │   └── token_manager.dart   # JWT token management
│   ├── constants/
│   │   └── api_endpoints.dart   # API endpoint constants
│   ├── di/
│   │   └── injection_container.dart  # Dependency injection
│   ├── errors/
│   │   ├── exceptions.dart      # Data layer exceptions
│   │   └── failures.dart        # Domain layer failures
│   ├── network/
│   │   ├── api_client.dart      # Dio HTTP client wrapper
│   │   └── network_info.dart    # Connectivity checker
│   ├── routes/
│   │   ├── dashboard_router.dart     # Route generator
│   │   └── route_names.dart          # Route constants
│   ├── theme/
│   │   └── theme.dart           # App theme (Cobalt Blue + Red)
│   └── usecases/
│       └── usecase.dart         # Base UseCase interface
│
└── features/
    ├── auth/                    # Authentication feature
    │   ├── data/
    │   │   ├── data_sources/    # Remote & local data sources
    │   │   ├── models/          # JSON serializable models
    │   │   └── repositories/    # Repository implementation
    │   ├── domain/
    │   │   ├── entities/        # Business entities
    │   │   ├── repositories/    # Abstract repository
    │   │   └── usecases/        # Business logic
    │   └── presentation/
    │       ├── bloc/            # BLoC state management
    │       ├── pages/           # Screen widgets
    │       └── widgets/         # Reusable components
    │
    ├── get_token/               # Queue management feature
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    │
    ├── chat/                    # AI assistant feature
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    │
    ├── notice/                  # Government notices feature
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    │
    ├── community/               # Community posts feature
    │   ├── data/
    │   │   └── services/        # AI moderation service
    │   ├── domain/
    │   └── presentation/
    │
    ├── profile/                 # User profile feature
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    │
    └── home/                    # Home screen
        └── presentation/
```

---

## 🔌 API Integration

### Backend Services

| Service | Port | Purpose |
|---------|------|---------|
| Main API | 8000 | Authentication, Queue, Notices, Chat |
| AI Moderation | 8003 | Image classification for community posts |

### API Endpoints

#### Authentication
```
POST /auth/otp/request/     # Request OTP
POST /auth/otp/verify/      # Verify OTP
POST /auth/otp/resend/      # Resend OTP
POST /auth/token/refresh/   # Refresh JWT token
```

#### Citizen Queue API (v1)
```
GET  /api/citizen/v1/places/{place_id}/ministries/     # Get ministries
GET  /api/citizen/v1/ministries/{ministry_id}/services/ # Get services
GET  /api/citizen/v1/services/{service_id}/            # Service details
GET  /api/citizen/v1/tokens/                           # My tokens
POST /api/citizen/v1/tokens/book/                      # Book token
```

#### Notices
```
GET /api/public/notices/           # List notices
GET /api/public/notices/{id}/      # Notice details
GET /api/public/notices/filters/   # Filter options
```

#### Chat
```
POST /api/chat/    # Send message to AI assistant
```

### Pagination

The API uses cursor-based pagination:
```dart
// Request
GET /api/citizen/v1/tokens/?cursor=abc123&page_size=20

// Response
{
  "success": true,
  "data": {
    "items": [...],
    "pagination": {
      "next_cursor": "xyz789",
      "has_more": true,
      "total_estimate": 100
    }
  }
}
```

---

## 🎨 Theme & Design

### Color Palette

| Color | Hex | Usage |
|-------|-----|-------|
| Primary Cobalt | `#0047AB` | Main brand color |
| Accent Red | `#DC143C` | CTAs and highlights |
| Success | `#2E7D32` | Positive states |
| Warning | `#F57C00` | Warning states |
| Error | `#B71C1C` | Error states |

### Typography

- **Primary Font**: Poppins (Regular, SemiBold)
- **Display Font**: Playfair Display (Bold)
- **System Font**: Roboto (Regular, Bold)

---

## 📦 Dependencies

### Core
```yaml
flutter_bloc: ^9.1.1      # State management
get_it: ^7.6.4            # Dependency injection
dio: ^5.4.0               # HTTP client
dartz: ^0.10.1            # Functional programming
equatable: ^2.0.5         # Value equality
```

### Storage
```yaml
hive: ^2.2.3                    # NoSQL database
hive_flutter: ^1.1.0            # Flutter integration
flutter_secure_storage: ^9.2.4  # Secure storage
shared_preferences: ^2.2.2      # Simple key-value
```

### UI
```yaml
cached_network_image: ^3.3.0    # Image caching
shimmer: ^3.0.0                 # Loading effects
carousel_slider: ^5.0.0         # Image carousel
flutter_snake_navigationbar: ^0.6.1  # Bottom nav
pinput: ^5.0.1                  # OTP input
```

### Utilities
```yaml
connectivity_plus: ^6.0.1       # Network status
url_launcher: ^6.2.3            # Open URLs
intl: ^0.20.2                   # Date formatting
uuid: ^4.3.3                    # Unique IDs
```

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/widget_test.dart
```

---

## 🔒 Security

- **JWT Authentication**: Access and refresh tokens
- **Secure Storage**: Tokens stored in platform keychain
- **Token Auto-refresh**: Automatic token refresh on 401
- **OTP Verification**: Email-based authentication

---

## 📝 Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `dart format` for consistent formatting
- Run `flutter analyze` before committing
- See [.github/copilot-instructions.md](.github/copilot-instructions.md) for detailed guidelines

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is proprietary software developed for government services digitization.

---

## 👥 Team

- **Development**: Sewa Sathi Team
- **Architecture**: Clean Architecture with BLoC

---

## 📞 Support

For support and queries:
- Create an issue in this repository
- Contact the development team

---

<p align="center">
  Made with ❤️ for Nepal 🇳🇵
</p>
