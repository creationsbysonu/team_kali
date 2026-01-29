# Sewa Sathi Web Admin Dashboard

<p align="center">
  <img src="assets/images/logo.png" alt="Sewa Sathi Logo" width="200"/>
</p>

> **Government Web Admin Dashboard for Multi-Tenant Ministry Management**

A comprehensive Flutter web application for managing government services, queue systems, staff attendance, and ministry operations across multiple administrative units.

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Architecture](#-architecture)
- [Project Structure](#-project-structure)
- [Tech Stack](#-tech-stack)
- [Getting Started](#-getting-started)
- [Configuration](#-configuration)
- [User Roles](#-user-roles)
- [API Documentation](#-api-documentation)
- [Screenshots](#-screenshots)
- [Contributing](#-contributing)

---

## 🎯 Overview

**Sewa Sathi** (सेवा साथी - "Service Companion") is a multi-tenant government service management platform designed for Nepal's administrative offices. The platform enables:

- **Citizens**: Book appointments, track queue status, access services online
- **Ministry Admins**: Manage staff, configure services, monitor operations
- **Staff Members**: Handle queue tokens, manage daily operations
- **Super Admins**: Oversee multiple places and ministries

### Key Objectives

1. **Digitize Government Services** - Transform paper-based processes into efficient digital workflows
2. **Reduce Wait Times** - Smart queue management with pre-booking capabilities
3. **Transparency** - Real-time status tracking for citizens
4. **Multi-Tenant Architecture** - Support multiple places (districts) and ministries under one platform

---

## ✨ Features

### 🏛️ Ministry Admin Panel
- **Staff Service Management** - Create, update, and manage staff-service assignments
- **Queue Configuration** - Configure office hours, daily capacity, prebooking slots, emergency fees
- **Officials Management** - Manage higher officials for escalation workflows
- **Attendance Tracking** - Calendar-based attendance system with holiday integration
- **Notice Board** - Publish announcements and notices
- **Holiday Management** - Configure public holidays and office closures

### 👨‍💼 Staff Dashboard
- **Token Management** - View active, pending, and all tokens
- **Queue Operations** - Call next token, mark complete, skip, or transfer
- **Real-time Updates** - Live queue status monitoring

### 🔐 Super Admin Panel
- **Place Management** - Manage districts/administrative units
- **Ministry Management** - Create and manage ministries across places
- **System-wide Configuration** - Global settings and configurations

### 🎫 Queue Management
- **Smart Queue System** - Automatic token generation and distribution
- **Prebooking Support** - Citizens can book appointments in advance
- **Emergency Handling** - Priority queue for emergency cases with configurable fees
- **Multi-step Progress** - Track service progress through defined steps

---

## 🏗️ Architecture

The project follows **Clean Architecture** with **BLoC Pattern** for state management:

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐        │
│  │  Pages  │  │ Widgets │  │  BLoCs  │  │ States  │        │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘        │
├─────────────────────────────────────────────────────────────┤
│                     DOMAIN LAYER                             │
│  ┌──────────┐  ┌──────────────┐  ┌─────────────────┐       │
│  │ Entities │  │  Use Cases   │  │  Repositories   │       │
│  │          │  │              │  │  (Interfaces)   │       │
│  └──────────┘  └──────────────┘  └─────────────────┘       │
├─────────────────────────────────────────────────────────────┤
│                      DATA LAYER                              │
│  ┌──────────┐  ┌──────────────┐  ┌─────────────────┐       │
│  │  Models  │  │ Data Sources │  │  Repositories   │       │
│  │          │  │ (Remote/Local)│  │  (Impl)        │       │
│  └──────────┘  └──────────────┘  └─────────────────┘       │
└─────────────────────────────────────────────────────────────┘
```

### Key Architectural Decisions

| Concept | Implementation |
|---------|----------------|
| State Management | BLoC (flutter_bloc) |
| Dependency Injection | GetIt |
| Error Handling | Either<Failure, Success> with dartz |
| HTTP Client | Dio with interceptors |
| Local Storage | SharedPreferences |
| Routing | Custom Router 2.0 with URL sync |

---

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point
├── app/
│   ├── app.dart                 # Root widget with providers
│   └── app_bloc_observer.dart   # BLoC debugging observer
│
├── core/                        # Shared/Core functionality
│   ├── auth/
│   │   └── token_manager.dart   # JWT token management
│   ├── constants/
│   │   └── api_endpoints.dart   # API endpoint definitions
│   ├── di/
│   │   └── injection_container.dart  # Dependency injection setup
│   ├── errors/
│   │   ├── exceptions.dart      # Custom exceptions
│   │   └── failures.dart        # Failure classes for Either
│   ├── network/
│   │   ├── api_client.dart      # Dio HTTP client wrapper
│   │   ├── network_info.dart    # Connectivity checker
│   │   └── interceptors/        # Auth, logging interceptors
│   ├── routes/
│   │   ├── app_router.dart      # Main app router
│   │   ├── dashboard_router.dart # Nested dashboard routes
│   │   └── route_names.dart     # Route name constants
│   ├── theme/
│   │   └── theme.dart           # App theme & colors
│   ├── usecases/
│   │   └── usecase.dart         # Base UseCase class
│   ├── utils/
│   │   └── responsive_helper.dart # Responsive breakpoints
│   └── widget/                  # Shared widgets
│       ├── dashboard_shell.dart
│       ├── dashboard_side_bar.dart
│       └── loading_overlay.dart
│
├── features/                    # Feature modules
│   ├── auth/                    # Authentication
│   │   ├── data/
│   │   │   ├── data_sources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── bloc/
│   │       └── pages/
│   │
│   ├── ministry/                # Ministry management
│   ├── queue_management/        # Queue configuration
│   ├── staff_queue/             # Staff token management
│   ├── attendance/              # Attendance tracking
│   ├── holidays/                # Holiday management
│   ├── officials/               # Higher officials
│   ├── notice/                  # Notice board
│   ├── places/                  # Place/District management
│   ├── services/                # Service definitions
│   ├── staff/                   # Staff operations
│   └── super_admin/             # Super admin features
│
├── assets/
│   ├── fonts/                   # Custom fonts (Poppins, Roboto, Playfair)
│   └── images/                  # App images & logos
│
└── web/
    └── index.html               # Web entry HTML
```

---

## 🛠️ Tech Stack

### Frontend (Flutter)

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_bloc | ^9.1.1 | State management |
| get_it | ^7.6.4 | Dependency injection |
| dio | ^5.4.0 | HTTP client |
| dartz | ^0.10.1 | Functional programming (Either) |
| equatable | ^2.0.5 | Value equality |
| shared_preferences | ^2.2.2 | Local storage |
| flutter_form_builder | ^10.2.0 | Form handling |
| form_builder_validators | ^11.2.0 | Form validation |
| cached_network_image | ^3.3.0 | Image caching |
| syncfusion_flutter_calendar | ^32.1.25 | Calendar widget |
| intl | ^0.20.2 | Internationalization |
| connectivity_plus | ^6.0.1 | Network connectivity |
| image_picker | ^1.0.7 | Image selection |
| file_picker | ^6.1.1 | File selection |
| uuid | ^4.3.3 | UUID generation |
| url_launcher | ^6.2.5 | URL handling |

### Backend (Django)
- Django 6.0.1 with Django REST Framework
- Supabase (PostgreSQL) for database
- JWT Authentication (access + refresh tokens)
- CORS enabled for web
- Daphne ASGI server

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK ^3.10.4
- Dart SDK ^3.10.4
- Chrome browser (for web development)
- Django backend running (separate repository)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-org/sewa_sathi_web.git
   cd sewa_sathi_web/sewa_web
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app (Web)**
   ```bash
   flutter run -d chrome
   ```

4. **Run the app (Android)**
   ```bash
   # List available devices
   flutter devices
   
   # Run on specific device
   flutter run -d <device_id>
   ```

### Adding Mobile Platform Support

If the Android folder doesn't exist:
```bash
flutter create --platforms android .
```

Then run:
```bash
flutter run -d <device_id>
```

---

## ⚙️ Configuration

### API Base URL

Edit `lib/core/constants/api_endpoints.dart`:

```dart
class ApiEndpoints {
  // Development URL (local - for web/emulator)
  static const String baseUrl = "http://127.0.0.1:8000";
  
  // For mobile device testing (use your machine's IP)
  // static const String baseUrl = "http://192.168.x.x:8000";
  
  // Production URL
  // static const String baseUrl = "https://api.sewasathi.gov.np";
}
```

### Mobile Device Testing

When testing on a physical device via USB or hotspot:

1. **Find your machine's IP address:**
   ```bash
   # macOS
   ipconfig getifaddr en0
   
   # Linux
   hostname -I
   
   # Windows
   ipconfig
   ```

2. **Update `baseUrl`** to use that IP instead of `127.0.0.1`

3. **Run Django with `0.0.0.0:8000`** to accept external connections:
   ```bash
   python manage.py runserver 0.0.0.0:8000
   ```

4. **Ensure devices are on the same network**

---

## 👥 User Roles

| Role | Access | Login Route |
|------|--------|-------------|
| **Super Admin** | All places & ministries | `/login/superadmin` |
| **Ministry Admin** | Single ministry management | `/login/ministry/{place}/{ministry}` |
| **Staff** | Queue operations only | `/login/staff/{place}/{ministry}` |

### Default Test Credentials

| Role | Email | Password |
|------|-------|----------|
| Ministry Admin | cdo@gmail.com | cdo12345 |
| Staff | staff@gmail.com | staff12345 |

---

## 📡 API Documentation

### Authentication Flow

```http
POST /ministry/public/{place}/{ministry}/login/
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password",
  "place_slug": "dharan",
  "ministry_slug": "cdo-office"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "ministry": {
      "id": "uuid",
      "name": "CDO Office",
      "slug": "cdo-office",
      "logo_url": "https://..."
    },
    "tokens": {
      "access_token": "eyJ...",
      "refresh_token": "eyJ...",
      "token_type": "Bearer",
      "expires_in": 900,
      "refresh_expires_in": 1209600
    },
    "place": {
      "id": "uuid",
      "name": "Dharan",
      "slug": "dharan"
    }
  },
  "message": "Login successful"
}
```

### Key Endpoints

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/places/public/` | GET | ❌ | List all places |
| `/ministry/public/{place}/ministries/` | GET | ❌ | List ministries in a place |
| `/ministry/management/staff-services/` | GET | ✅ | Get staff services |
| `/queue/config/` | GET/POST | ✅ | Queue configuration |
| `/queue/config/?staff_service={id}` | GET | ✅ | Get config for service |
| `/officials/` | GET/POST | ✅ | Officials management |
| `/attendance/` | GET/POST | ✅ | Attendance records |
| `/holidays/` | GET/POST | ✅ | Holiday management |
| `/notices/` | GET/POST | ✅ | Notice board |

### Token Refresh

```http
POST /auth/token/refresh/
Content-Type: application/json

{
  "refresh": "eyJ..."
}
```

---

## 🎨 Theme Colors

The app uses a government-appropriate color palette:

| Color | Hex | Usage |
|-------|-----|-------|
| Primary Cobalt | `#0047AB` | Main brand color |
| Primary Dark | `#003580` | Darker variant |
| Primary Light | `#4A7BA7` | Lighter variant |
| Accent Red | `#DC143C` | Secondary/Action color |
| Success | `#2E7D32` | Positive status |
| Warning | `#F57C00` | Warnings |
| Error | `#B71C1C` | Errors |
| Background | `#F5F5F5` | Page backgrounds |
| Card Background | `#FFFFFF` | Card surfaces |

### Typography

| Font | Weight | Usage |
|------|--------|-------|
| Poppins | 400, 600 | Body text, headings |
| Roboto | 400, 700 | UI elements |
| Playfair Display | 700 | Titles, branding |

---

## 📱 Screenshots

<details>
<summary>Click to expand screenshots</summary>

### Login Screen
*Screenshot placeholder*

### Ministry Dashboard
*Screenshot placeholder*

### Queue Configuration
*Screenshot placeholder*

### Staff Token Panel
*Screenshot placeholder*

### Attendance Calendar
*Screenshot placeholder*

</details>

---

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/widget_test.dart
```

---

## 🔧 Troubleshooting

### Common Issues

1. **Connection Timeout on Mobile**
   - Update `baseUrl` to use machine IP instead of `localhost`
   - Ensure device is on the same network as the backend server
   - Make sure firewall allows connections on port 8000

2. **CORS Errors (Web)**
   - Ensure Django CORS is configured to allow the Flutter web origin
   - Check browser console for specific CORS error messages
   - Add `http://localhost:port` to Django's `CORS_ALLOWED_ORIGINS`

3. **Backend Connection Issues**
   - Verify Django server is running
   - Check Supabase connection (SSL/connection pooling issues)
   - Review Django logs for database errors

4. **file_picker Warnings**
   - These are harmless warnings from the package maintainers
   - Can be ignored for web platform

5. **Android Build Fails**
   - Run `flutter clean` then `flutter pub get`
   - Check minimum SDK version in `android/app/build.gradle.kts`
   - Ensure Android SDK is properly installed

---

## 🔄 Build & Deploy

### Web Build
```bash
flutter build web --release
```
Output: `build/web/`

### Android Build
```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

---

## 📝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter_lints` for linting
- Format code with `dart format .`

---

## 📄 License

This project is proprietary software developed for government use.

---

## 👨‍💻 Authors

- **Development Team** - Sewa Sathi Project

---

## 🙏 Acknowledgments

- Flutter Team for the amazing framework
- BLoC Library contributors
- Syncfusion for calendar component
- All open-source package maintainers

---

<p align="center">
  Made with ❤️ for Nepal 🇳🇵
</p>
