# 🏛️ Sewa Sathi - Government Digital Service Platform

<p align="center">
  <img src="https://img.shields.io/badge/Django-6.0.1-green?style=for-the-badge&logo=django" alt="Django">
  <img src="https://img.shields.io/badge/Python-3.12-blue?style=for-the-badge&logo=python" alt="Python">
  <img src="https://img.shields.io/badge/PostgreSQL-15-blue?style=for-the-badge&logo=postgresql" alt="PostgreSQL">
  <img src="https://img.shields.io/badge/Redis-8-red?style=for-the-badge&logo=redis" alt="Redis">
  <img src="https://img.shields.io/badge/Celery-5.6-green?style=for-the-badge&logo=celery" alt="Celery">
</p>

> **Sewa Sathi** (Service Companion) is a comprehensive digital queue management and government service delivery platform designed for Nepal. It connects citizens with government ministries through a mobile app, enabling efficient token-based service delivery.

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Features](#-features)
- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [API Documentation](#-api-documentation)
- [WebSocket Integration](#-websocket-integration)
- [Deployment](#-deployment)
- [Development](#-development)
- [Contributing](#-contributing)

---

## 🎯 Overview

Sewa Sathi is a multi-tenant government service platform that:

- **Eliminates Physical Queues**: Citizens book tokens via mobile app, arrive at scheduled time
- **Decentralized Architecture**: Supports multiple places (cities), each with multiple ministries
- **Real-time Updates**: WebSocket-powered live queue status and notifications
- **Multi-role System**: Citizens, Staff, Ministry Admins, and Super Admins
- **RAG-Powered Chat**: AI assistant for citizen queries using government notices

### User Roles

| Role | Description |
|------|-------------|
| **Citizen** | Book tokens, view queue status, chat with AI assistant |
| **Staff** | Serve tokens, manage daily queue operations |
| **Ministry Admin** | Configure services, manage staff, set holidays |
| **Super Admin** | Manage places, ministries, system-wide settings |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                                  │
├─────────────────────────────────────────────────────────────────────┤
│  Flutter Mobile App    │   Web Dashboard    │   Admin Panel         │
│  (Citizens)            │   (Staff)          │   (Ministry/Super)    │
└───────────┬────────────┴────────┬───────────┴───────────┬───────────┘
            │                     │                       │
            │  HTTP/WS            │  HTTP                 │  HTTP
            │                     │                       │
┌───────────▼─────────────────────▼───────────────────────▼───────────┐
│                       API GATEWAY (Daphne ASGI)                      │
│                   HTTP + WebSocket Support                           │
└───────────┬─────────────────────┬───────────────────────┬───────────┘
            │                     │                       │
┌───────────▼──────────┐ ┌────────▼────────┐ ┌────────────▼──────────┐
│   REST API Layer     │ │  WebSocket      │ │   Background Tasks    │
│   (DRF Views)        │ │  (Channels)     │ │   (Celery Workers)    │
│                      │ │                 │ │                       │
│  • Authentication    │ │  • Citizen Chat │ │  • Token Cancellation │
│  • Token Booking     │ │  • Queue Updates│ │  • Queue Creation     │
│  • Queue Management  │ │  • Notifications│ │  • Email Sending      │
│  • Notice Portal     │ │                 │ │  • Token Cleanup      │
└───────────┬──────────┘ └────────┬────────┘ └────────────┬──────────┘
            │                     │                       │
┌───────────▼─────────────────────▼───────────────────────▼───────────┐
│                        SERVICE LAYER                                 │
│              Business Logic, Validations, Caching                    │
└───────────┬─────────────────────┬───────────────────────┬───────────┘
            │                     │                       │
┌───────────▼──────────┐ ┌────────▼────────┐ ┌────────────▼──────────┐
│   PostgreSQL         │ │   Redis         │ │   Cloudinary          │
│   (Supabase)         │ │   (Cache/Queue) │ │   (Media Storage)     │
│                      │ │                 │ │                       │
│  • User Data         │ │  • JWT Tokens   │ │  • Logos              │
│  • Ministries        │ │  • API Cache    │ │  • Documents          │
│  • Queue Data        │ │  • Celery Broker│ │  • Notice Files       │
│  • Notices           │ │  • Channel Layer│ │                       │
└──────────────────────┘ └─────────────────┘ └───────────────────────┘
                                │
                    ┌───────────▼───────────┐
                    │   RAG Server          │
                    │   (External Service)  │
                    │                       │
                    │  • Notice Ingestion   │
                    │  • AI Chat Responses  │
                    └───────────────────────┘
```

---

## ✨ Features

### 🏢 Multi-Tenant Ministry Management
- **Places**: Decentralized locations (Kathmandu, Pokhara, etc.)
- **Ministries**: Government offices within each place
- **Services**: Staff-provided services with queue configuration
- **Officials**: Higher officials for progress tracking

### 🎫 Queue Management System
- **Dynamic Capacity**: Auto-calculated based on office hours and service time
- **Booking Types**: Regular, Pre-booking, Emergency (with fee)
- **Token Statuses**: Waiting → In Service → Completed/Cancelled/Pending
- **Progress Tracking**: Multi-step document verification with official signatures
- **No-Show Handling**: Automatic push-back after 2 no-shows

### 📅 Attendance & Holidays
- **Staff Attendance**: Controls service availability
- **Official Attendance**: Controls progress step completion
- **Universal Holidays**: All offices closed on defined dates
- **Weekend Rules**: Saturday = automatic closure (Nepal)

### 📢 Notice Portal
- **Government Notices**: PDF/Image uploads with RAG ingestion
- **AI Chat**: Citizens query notices using natural language
- **File Management**: Cloudinary storage with size limits

### 🔔 Real-time Features
- **WebSocket Chat**: Live AI assistant communication
- **Push Notifications**: Token status updates
- **Queue Updates**: Real-time position tracking

---

## 🛠️ Tech Stack

### Backend
| Technology | Version | Purpose |
|------------|---------|---------|
| Django | 6.0.1 | Web Framework |
| Django REST Framework | 3.16.1 | REST API |
| Django Channels | 4.3.2 | WebSocket Support |
| Daphne | 4.2.1 | ASGI Server |
| Celery | 5.6.2 | Async Task Queue |
| PostgreSQL | 15 | Primary Database |
| Redis | 8 | Cache & Message Broker |

### Infrastructure
| Technology | Purpose |
|------------|---------|
| Supabase | Managed PostgreSQL |
| Cloudinary | Media Storage (CDN) |
| Docker | Containerization |
| Nginx | Reverse Proxy |

### Authentication
- JWT (SimpleJWT) with access/refresh tokens
- OTP-based login for citizens
- Password-based login for staff/admins
- Multi-user type authentication middleware

---

## 📁 Project Structure

```
sewa_sathi_backend/
├── manage.py                    # Django management script
├── docker-compose.yml           # Docker orchestration
├── Dockerfile                   # Container definition
│
├── sewa_sathi/                  # Project configuration
│   ├── settings.py              # Django settings
│   ├── urls.py                  # Root URL configuration
│   ├── celery.py                # Celery configuration
│   ├── asgi.py                  # ASGI entry point (HTTP + WebSocket)
│   └── wsgi.py                  # WSGI entry point (HTTP only)
│
├── core/                        # Shared utilities
│   ├── middleware.py            # Database connection middleware
│   ├── mixins.py                # View mixins
│   ├── pagination.py            # Custom pagination classes
│   ├── permissions.py           # Permission classes
│   └── utils/                   # Utility modules
│       └── nepal_time.py        # Nepal timezone helpers
│
├── authentication/              # User authentication
│   ├── models.py                # CustomUser, OTPLog
│   ├── auth/                    # Auth services (login, registration)
│   ├── otp/                     # OTP generation & verification
│   └── core/                    # JWT utilities, authentication classes
│
├── places/                      # Geographic locations
│   ├── models.py                # Place model
│   ├── admin/                   # Admin views (Super Admin)
│   └── public/                  # Public views (list places)
│
├── ministry/                    # Ministries & Services
│   ├── models.py                # Ministry, StaffService
│   ├── admin/                   # Ministry admin views
│   ├── public/                  # Public ministry views
│   └── core/                    # Middleware, permissions
│
├── officials/                   # Ministry Officials
│   ├── models.py                # MinistryOfficial
│   └── views.py                 # CRUD operations
│
├── attendance/                  # Attendance Tracking
│   ├── models.py                # AttendanceRecord
│   └── services.py              # Attendance business logic
│
├── holidays/                    # Holiday Management
│   ├── models.py                # Holiday
│   └── services.py              # Holiday business logic
│
├── queue_management/            # Queue System (Core)
│   ├── models.py                # QueueConfiguration, DailyQueue,
│   │                            # QueueToken, QueueEventLog,
│   │                            # ServiceProgressStep, TokenProgress
│   ├── services.py              # Queue business logic
│   ├── tasks.py                 # Celery tasks (auto-cancel, cleanup)
│   ├── progress_tracking_service.py  # Progress tracking logic
│   └── progress_views.py        # Progress tracking API
│
├── notifications/               # In-app Notifications
│   ├── models.py                # Notification
│   └── services.py              # Notification triggers
│
├── get_token/                   # Citizen Token Booking
│   ├── views.py                 # Booking API views
│   ├── services.py              # Booking business logic
│   └── serializers.py           # Request/Response serializers
│
├── citizen_api/                 # Optimized Citizen API (v1)
│   ├── views.py                 # Paginated, cached endpoints
│   ├── services.py              # Optimized queries
│   └── serializers.py           # Lean response serializers
│
├── notices/                     # Government Notices
│   ├── models.py                # Notice
│   ├── public/                  # Public notice endpoints
│   └── admin_panel/             # Admin notice management
│
├── filters/                     # Notice Filtering
│   └── services.py              # RAG filter integration
│
├── rag_bridge/                  # RAG Server Integration
│   └── services.py              # RAG API client
│
├── citizen_chat/                # AI Chat (WebSocket)
│   ├── consumers.py             # WebSocket consumer
│   ├── routing.py               # WebSocket URL routing
│   └── middleware.py            # JWT auth for WebSocket
│
├── staff/                       # Staff Management
│   └── admin.py                 # Staff admin panel
│
├── services/                    # Service Catalog
│   └── models.py                # Service model
│
├── mobile_initial/              # Mobile App Setup
│   └── views.py                 # Profile completion flow
│
├── templates/                   # Email templates
│   └── emails/                  # OTP, verification emails
│
├── docs/                        # Documentation
│   ├── FLUTTER_CITIZEN_API_GUIDE.md
│   ├── FLUTTER_TOKEN_BOOKING_API.md
│   └── STAFF_ADMIN_PANEL_IMPLEMENTATION.md
│
└── nginx/                       # Nginx configuration
    └── conf.d/
```

---

## 🚀 Installation

### Prerequisites

- Python 3.12+
- PostgreSQL 15+ (or Supabase account)
- Redis 8+
- Cloudinary account

### Local Development Setup

```bash
# 1. Clone the repository
git clone https://github.com/your-org/sewa-sathi-backend.git
cd sewa-sathi-backend

# 2. Create virtual environment
python -m venv .venv
source .venv/bin/activate  # Linux/macOS
# or
.venv\Scripts\activate     # Windows

# 3. Install dependencies
pip install -r requirements.txt

# 4. Copy environment file
cp .env.example .env
# Edit .env with your configuration

# 5. Run migrations
python manage.py migrate

# 6. Create superuser
python manage.py createsuperuser

# 7. Start Redis (in separate terminal)
redis-server

# 8. Start Celery worker (in separate terminal)
celery -A sewa_sathi worker --loglevel=info

# 9. Start Celery beat (in separate terminal)
celery -A sewa_sathi beat --loglevel=info

# 10. Start development server
python manage.py runserver 0.0.0.0:8000

# For WebSocket support, use Daphne instead:
daphne -b 0.0.0.0 -p 8000 sewa_sathi.asgi:application
```

### Docker Setup

```bash
# 1. Copy environment file
cp .env.example .env
# Edit .env with your configuration

# 2. Build and start all services
docker-compose up -d --build

# 3. Run migrations
docker-compose exec web python manage.py migrate

# 4. Create superuser
docker-compose exec web python manage.py createsuperuser

# Services available:
# - Web: http://localhost:8000
# - Flower (Celery monitoring): http://localhost:5555
# - PostgreSQL: localhost:5432
# - Redis: localhost:6379
```

---

## ⚙️ Configuration

### Environment Variables

```bash
# =========================
# Django Settings
# =========================
SECRET_KEY=your-secret-key
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1,your-domain.com
BASE_URL=http://localhost:8000

# =========================
# Database (PostgreSQL/Supabase)
# =========================
DB_NAME=postgres
DB_USER=postgres
DB_PASSWORD=your-password
DB_HOST=localhost          # Use 'db' for Docker
DB_PORT=5432               # Use Session Pooler port for Supabase

# =========================
# Redis
# =========================
REDIS_HOST=localhost       # Use 'redis' for Docker
REDIS_PORT=6379

# =========================
# Email (Gmail SMTP)
# =========================
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password

# =========================
# Cloudinary (Media Storage)
# =========================
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret

# =========================
# JWT Settings
# =========================
JWT_COOKIE_SECURE=False    # True in production

# =========================
# RAG Server (AI Chat)
# =========================
RAG_SERVER_URL=http://localhost:8001
RAG_API_KEY=your-rag-api-key
```

---

## 📡 API Documentation

### Base URLs

| Environment | URL |
|-------------|-----|
| Development | `http://localhost:8000` |
| Production | `https://api.sewasathi.com` |

### Authentication

All protected endpoints require JWT Bearer token:

```http
Authorization: Bearer <access_token>
```

### API Endpoints Overview

#### Authentication (`/auth/`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/register/` | Register new citizen |
| POST | `/auth/login/` | Login (OTP for citizens, password for staff) |
| POST | `/auth/token/refresh/` | Refresh access token |
| POST | `/auth/logout/` | Logout (blacklist token) |
| POST | `/auth/otp/request/` | Request OTP |
| POST | `/auth/otp/verify/` | Verify OTP |

#### Citizen API (`/api/citizen/v1/`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/places/{id}/ministries/` | List ministries in a place |
| GET | `/ministries/{id}/services/` | List services in a ministry |
| GET | `/services/{id}/` | Service details with queue config |
| GET | `/services/{id}/availability/` | Quick availability check |
| GET | `/tokens/` | User's tokens (active & history) |
| GET | `/tokens/{id}/` | Token details |

#### Token Booking (`/api/get-token/`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/book/` | Book a token |
| GET | `/my-tokens/` | User's tokens |
| POST | `/cancel/{token_id}/` | Cancel a token |

#### Queue Management (`/api/queue/`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/staff/active-tokens/` | Staff's active queue |
| POST | `/staff/call-next/` | Call next token |
| POST | `/staff/complete/{token_id}/` | Complete token service |
| POST | `/staff/no-show/{token_id}/` | Mark token as no-show |
| POST | `/staff/move-to-pending/{token_id}/` | Move to pending |

#### Notice Portal (`/api/public/notices/`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | List all notices |
| GET | `/{id}/` | Notice details |

### Response Format

All API responses follow this structure:

```json
// Success
{
    "success": true,
    "data": { ... },
    "message": "Operation successful"
}

// Error
{
    "success": false,
    "error": "Human-readable error message"
}

// Paginated
{
    "success": true,
    "data": {
        "results": [...],
        "count": 100,
        "next": "http://api/endpoint/?page=2",
        "previous": null
    }
}
```

---

## 🔌 WebSocket Integration

### Citizen Chat

**Endpoint:** `ws://localhost:8000/ws/chat/`

**Authentication:** JWT token as query parameter

```javascript
const ws = new WebSocket('ws://localhost:8000/ws/chat/?token=<jwt_token>');

// Send message
ws.send(JSON.stringify({
    type: 'chat_message',
    message: 'What documents do I need for citizenship?'
}));

// Receive response
ws.onmessage = (event) => {
    const data = JSON.parse(event.data);
    console.log(data.response);
};
```

---

## 🐳 Deployment

### Docker Compose (Recommended)

```yaml
# docker-compose.yml services:
# - db: PostgreSQL database
# - redis: Cache and message broker
# - web: Django application (Gunicorn)
# - celery: Background task worker
# - celery-beat: Scheduled task scheduler
# - flower: Celery monitoring UI
```

### Production Checklist

- [ ] Set `DEBUG=False`
- [ ] Configure `ALLOWED_HOSTS`
- [ ] Set `JWT_COOKIE_SECURE=True`
- [ ] Use production PostgreSQL (Supabase)
- [ ] Configure Redis with authentication
- [ ] Set up Nginx reverse proxy
- [ ] Enable HTTPS (SSL certificate)
- [ ] Configure CORS for production domains
- [ ] Set up log aggregation
- [ ] Configure monitoring (Flower, Sentry)

---

## 💻 Development

### Code Style

This project follows the [Django coding style guide](https://docs.djangoproject.com/en/dev/internals/contributing/writing-code/coding-style/) with additional conventions:

- **Service Layer Architecture**: Business logic in `services.py`, views are thin
- **UUID Primary Keys**: All models use UUID for security
- **Timestamps**: All models include `created_at` and `updated_at`
- **Soft Delete**: Use `is_deleted` flag instead of hard delete
- **Nepal Timezone**: All datetime operations use `Asia/Kathmandu`

### Running Tests

```bash
# Run all tests
python manage.py test

# Run specific app tests
python manage.py test queue_management

# With coverage
coverage run manage.py test
coverage report
```

### Celery Tasks

```bash
# View scheduled tasks
celery -A sewa_sathi inspect scheduled

# View active tasks
celery -A sewa_sathi inspect active

# Purge all tasks
celery -A sewa_sathi purge
```

### Scheduled Tasks (Celery Beat)

| Task | Schedule | Description |
|------|----------|-------------|
| `auto-cancel-tokens-end-of-day` | Daily 6:00 PM | Cancel all active tokens |
| `create-daily-queues-tomorrow` | Daily 11:30 PM | Create next day's queues |
| `cleanup-old-tokens` | Sunday 2:00 AM | Delete tokens older than 90 days |

---

## 📚 Additional Documentation

- [Flutter Citizen API Guide](docs/FLUTTER_CITIZEN_API_GUIDE.md) - Complete Flutter integration
- [Token Booking API](docs/FLUTTER_TOKEN_BOOKING_API.md) - Token booking flow
- [Staff Admin Panel](docs/STAFF_ADMIN_PANEL_IMPLEMENTATION.md) - Staff dashboard implementation
- [Docker Deployment](DOCKER_DEPLOYMENT.md) - Production deployment guide
- [Redis & Celery Configuration](REDIS_CELERY_CONFIG.md) - Background task setup

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is proprietary software developed for government digital services in Nepal.

---

## 👥 Team

**Sewa Sathi Development Team**

For support or questions, contact: support@sewasathi.com

---

<p align="center">
  Made with ❤️ for Digital Nepal 🇳🇵
</p>
