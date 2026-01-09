# Flutter Web Integration Guide

> **Base URL**: `http://localhost:8000/api`

---

## 🔐 Authentication Workflow

### Super Admin Login
1. User enters email + password
2. Call login API
3. Check `user_type === "super_admin"`
4. Store `access_token` and `refresh_token`
5. Redirect to Super Admin Dashboard

### Ministry Admin Login
1. User enters email + password
2. Call login API
3. Check `user_type === "staff"` and `ministry` object exists
4. Store tokens + ministry info
5. Redirect to Ministry Dashboard

### Token Refresh
1. When API returns 401 Unauthorized
2. Call refresh endpoint with `refresh_token`
3. Store new `access_token`
4. Retry original request

### Logout
1. Call logout endpoint
2. Clear all stored tokens
3. Redirect to login page

---

## 👑 Super Admin Workflow

### Dashboard
1. Load → Fetch all ministries
2. Display ministry list with status indicators
3. Search/filter by name or status

### Create Ministry
1. Fill form: name, email, password, logo (optional)
2. Submit → Ministry created with login credentials
3. Show success with ministry email for login

### Edit Ministry
1. Select ministry → Load details
2. Update: name, description, phone, address, website, logo
3. Cannot change email/password here

### Activate/Suspend Ministry
1. Select ministry
2. Click Activate or Suspend
3. Suspended ministries cannot login

### Delete Ministry (Soft Delete)
1. Select ministry → Click Delete
2. Confirm deletion
3. Ministry hidden, data preserved, login blocked
4. Can be restored later

### Restore Deleted Ministry
1. View deleted ministries list
2. Select ministry → Click Restore
3. Ministry active again, login works

### Permanently Delete Ministry (Hard Delete)
1. View deleted ministries
2. Select → Click "Permanently Delete"
3. Double confirm (destructive action)
4. All data removed forever

### Reset Ministry Password
1. Select ministry
2. Enter new password (min 8 chars)
3. Ministry can login with new password

---

## 🏛️ Ministry Admin Workflow

### Dashboard
1. Login → Load own ministry profile
2. Display ministry info and stats

### Edit Profile
1. Update: description, phone, address, website, logo
2. Cannot change name or email

---

## 📋 API Endpoints

### Authentication

| Action | Method | Endpoint | Auth | Body |
|--------|--------|----------|------|------|
| Login | POST | `/auth/login/` | ❌ | `{email, password}` |
| Logout | POST | `/auth/logout/` | ❌ | `{refresh_token}` (optional) |
| Refresh Token | POST | `/auth/token/refresh/` | ❌ | `{refresh_token}` |
| Validate Token | GET | `/auth/token/validate/` | ✅ Bearer | - |

### Super Admin - Ministry Management

| Action | Method | Endpoint | Auth | Body/Params |
|--------|--------|----------|------|-------------|
| List Ministries | GET | `/ministry/admin/` | ✅ Bearer | `?status=active&search=health` |
| List Deleted Ministries | GET | `/ministry/admin/deleted/` | ✅ Bearer | - |
| Get Ministry Details | GET | `/ministry/admin/{id}/` | ✅ Bearer | - |
| Create Ministry | POST | `/ministry/admin/` | ✅ Bearer | `{name, email, password, logo?, description?, phone?, address?, website?}` |
| Update Ministry | PATCH | `/ministry/admin/{id}/` | ✅ Bearer | `{name?, description?, phone?, address?, website?, logo?}` |
| Delete Ministry (Soft) | DELETE | `/ministry/admin/{id}/` | ✅ Bearer | - |
| Restore Ministry | POST | `/ministry/admin/{id}/restore/` | ✅ Bearer | - |
| Hard Delete Ministry | POST | `/ministry/admin/{id}/hard-delete/` | ✅ Bearer | `{confirm: true}` |
| Activate Ministry | POST | `/ministry/admin/{id}/activate/` | ✅ Bearer | - |
| Suspend Ministry | POST | `/ministry/admin/{id}/suspend/` | ✅ Bearer | `{reason?}` |
| Reset Password | POST | `/ministry/admin/{id}/reset-password/` | ✅ Bearer | `{new_password}` |

### Ministry Admin - Self Management

| Action | Method | Endpoint | Auth | Body |
|--------|--------|----------|------|------|
| Get Own Ministry | GET | `/ministry/management/` | ✅ Bearer | - |
| Update Own Ministry | PATCH | `/ministry/management/` | ✅ Bearer | `{description?, phone?, address?, website?, logo?}` |

### Public

| Action | Method | Endpoint | Auth |
|--------|--------|----------|------|
| List Active Ministries | GET | `/ministry/public/` | ❌ |

---

## 🔑 Response Format

All responses follow this format:

```json
{
  "success": true/false,
  "data": { ... },
  "message": "...",
  "error": "..." 
}
```

### Login Response
```json
{
  "success": true,
  "data": {
    "user": { "id", "email", "full_name", "user_type" },
    "tokens": { "access_token", "refresh_token", "expires_in" },
    "ministry": { "id", "name", "slug", "role" }  // Only for ministry staff
  }
}
```

---

## ⚠️ Error Codes

| Code | Meaning |
|------|---------|
| 400 | Bad Request - Invalid input |
| 401 | Unauthorized - Invalid/expired token |
| 403 | Forbidden - No permission or account locked/suspended/deleted |
| 404 | Not Found |
| 500 | Server Error |

---

## 🔧 Implementation Notes for Flutter Web

### Token Storage
- Store `access_token` in memory or secure storage (NOT localStorage)
- Store `refresh_token` in secure storage for token refresh
- Both tokens are returned in login response body

### Authorization Header
```
Authorization: Bearer <access_token>
```

### Token Refresh
- Send `refresh_token` in request **body** (not cookies)
- Works cross-origin without cookie issues
```json
POST /auth/token/refresh/
{ "refresh_token": "your_refresh_token_here" }
```

### Logout
- No authentication required
- Optionally send `refresh_token` in body to blacklist it
- Clear all stored tokens on frontend after calling

### Auto Token Refresh Flow
1. API returns 401 → Token expired
2. Call `/auth/token/refresh/` with stored `refresh_token`
3. Get new `access_token` (and new `refresh_token`)
4. Retry original request with new token
5. If refresh fails → Logout user, redirect to login

### Login Response Structure
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "full_name": "User Name",
      "user_type": "super_admin" | "staff" | "admin" | "citizen"
    },
    "tokens": {
      "access_token": "eyJ...",
      "refresh_token": "eyJ...",
      "token_type": "Bearer",
      "expires_in": 900,
      "refresh_expires_in": 1209600
    },
    "ministry": {  // Only for staff/admin users
      "id": "uuid",
      "name": "Ministry Name",
      "slug": "ministry-slug",
      "role": "admin"
    }
  },
  "message": "Login successful"
}
```

### User Type Routing
| user_type | Redirect To |
|-----------|-------------|
| `super_admin` | Super Admin Dashboard |
| `staff` or `admin` | Ministry Dashboard (use `ministry` object) |

### File Upload (Logo)
- Use `multipart/form-data` for endpoints with logo
- Logo is uploaded to Cloudinary
- Response returns `logo_url` with full Cloudinary URL
