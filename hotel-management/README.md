# 🏨 Hotel Management System

A complete, production-ready Hotel Management Software built with **Flutter** (frontend), **Node.js + Express** (backend), and **PostgreSQL** (database).

---

## 📁 Project Structure

```
hotel-management/
├── backend/                        # Node.js + Express API
│   ├── src/
│   │   ├── index.js                # App entry point
│   │   ├── config/
│   │   │   ├── db.js               # PostgreSQL connection pool
│   │   │   ├── cloudinary.js       # Cloudinary + multer upload
│   │   │   └── migrate.js          # DB migration runner
│   │   ├── middleware/
│   │   │   ├── auth.js             # JWT authenticate + authorize
│   │   │   └── errorHandler.js     # Global error handler
│   │   ├── controllers/
│   │   │   ├── authController.js
│   │   │   ├── roomController.js
│   │   │   ├── guestController.js
│   │   │   ├── checkinController.js
│   │   │   ├── invoiceController.js
│   │   │   ├── staffController.js
│   │   │   └── dashboardController.js
│   │   ├── routes/
│   │   │   ├── auth.js
│   │   │   ├── rooms.js
│   │   │   ├── guests.js
│   │   │   ├── checkins.js
│   │   │   ├── invoices.js
│   │   │   ├── staff.js
│   │   │   └── dashboard.js
│   │   └── utils/
│   │       ├── response.js         # Standard response helpers
│   │       └── invoiceGenerator.js # PDF generation (pdfkit)
│   ├── migrations/
│   │   └── 001_init.sql            # Full PostgreSQL schema
│   ├── package.json
│   └── .env.example
│
└── flutter_app/                    # Flutter cross-platform app
    ├── lib/
    │   ├── main.dart               # App entry + provider setup
    │   ├── config/
    │   │   ├── api_config.dart     # API endpoints
    │   │   └── theme.dart          # Light + dark themes
    │   ├── models/                 # Data models (User, Room, Guest, etc.)
    │   ├── providers/              # State management (ChangeNotifier)
    │   ├── services/               # API service layer
    │   ├── screens/
    │   │   ├── auth/               # Login screen
    │   │   ├── dashboard/          # Dashboard + charts
    │   │   ├── rooms/              # Room management
    │   │   ├── checkin/            # Check-in / Check-out
    │   │   ├── invoice/            # Billing & invoices
    │   │   ├── staff/              # Staff management
    │   │   └── guests/             # Guest management
    │   └── widgets/                # Reusable components
    └── pubspec.yaml
```

---

## 🚀 Setup & Installation

### 1. PostgreSQL Database

```bash
# Create database
psql -U postgres -c "CREATE DATABASE hotel_management;"

# Run migrations
cd backend
npm install
npm run migrate
# Creates all tables + default admin: admin@hotel.com / admin123
```

### 2. Backend (Node.js)

```bash
cd backend

# Copy and configure environment
cp .env.example .env
# Edit .env with your actual values

# Install dependencies
npm install

# Start development server
npm run dev

# Start production server
npm start
```

**Server runs at:** `http://localhost:5000`

### 3. Flutter App

```bash
cd flutter_app

# Get dependencies
flutter pub get

# Create assets folder
mkdir -p assets/images

# Run on device/emulator
flutter run

# Build for web
flutter build web

# Build for Android
flutter build apk --release

# Build for iOS
flutter build ios --release
```

---

## ⚙️ Environment Variables (.env)

| Variable | Description |
|---|---|
| `PORT` | Server port (default: 5000) |
| `DATABASE_URL` | PostgreSQL connection string |
| `JWT_SECRET` | JWT signing secret (min 32 chars) |
| `JWT_EXPIRES_IN` | Token expiry (default: 7d) |
| `CLOUDINARY_CLOUD_NAME` | Cloudinary cloud name |
| `CLOUDINARY_API_KEY` | Cloudinary API key |
| `CLOUDINARY_API_SECRET` | Cloudinary API secret |
| `HOTEL_NAME` | Hotel name for invoices |
| `HOTEL_ADDRESS` | Hotel address for invoices |
| `HOTEL_PHONE` | Hotel phone for invoices |
| `HOTEL_GST_NUMBER` | GST registration number |

---

## 🔌 REST API Reference

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/login` | Login with email + password |
| GET | `/api/auth/me` | Get current user |
| PUT | `/api/auth/change-password` | Change password |

### Rooms
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/rooms` | List rooms (filter: status, room_type, floor) |
| GET | `/api/rooms/stats` | Room counts by status |
| GET | `/api/rooms/:id` | Room detail |
| POST | `/api/rooms` | Create room (admin/manager) |
| PUT | `/api/rooms/:id` | Update room (admin/manager) |
| PATCH | `/api/rooms/:id/status` | Update room status |
| DELETE | `/api/rooms/:id` | Delete room (admin) |

### Guests
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/guests` | List guests (search, pagination) |
| GET | `/api/guests/search?q=` | Quick search |
| GET | `/api/guests/:id` | Guest + checkin history |
| POST | `/api/guests` | Create guest (multipart/form-data with id_proof) |
| PUT | `/api/guests/:id` | Update guest |

### Check-ins
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/checkins` | All checkins (filter by status) |
| GET | `/api/checkins/active` | Active checkins only |
| GET | `/api/checkins/:id` | Checkin detail with guest+room+invoice |
| POST | `/api/checkins` | New check-in |
| PUT | `/api/checkins/:id/checkout` | Check out guest |

### Invoices
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/invoices` | All invoices (filter by payment_status) |
| GET | `/api/invoices/:id` | Invoice detail with payments |
| GET | `/api/invoices/checkin/:checkinId` | Invoice for a checkin |
| POST | `/api/invoices/generate` | Generate/recalculate invoice |
| PUT | `/api/invoices/:id` | Update extra charges / discount |
| POST | `/api/invoices/:id/payment` | Record payment |
| GET | `/api/invoices/:id/download` | Download PDF |

### Staff
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/staff` | All staff list |
| GET | `/api/staff/attendance/today` | Today's attendance |
| GET | `/api/staff/:id` | Staff detail + attendance |
| POST | `/api/staff` | Create staff (admin/manager) |
| PUT | `/api/staff/:id` | Update staff |
| POST | `/api/staff/:id/attendance` | Mark attendance |
| GET | `/api/staff/:id/attendance?month=YYYY-MM` | Monthly attendance |

### Dashboard
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/dashboard/stats` | All dashboard statistics |

---

## 🗄️ Database Schema

### Tables
- **users** — Admin, manager, receptionist, housekeeping logins
- **staff** — Staff profile linked to users
- **staff_attendance** — Daily attendance records
- **rooms** — Room inventory with status tracking
- **guests** — Guest registry with ID proof
- **checkins** — Check-in/out records
- **invoices** — Auto-calculated invoices with GST
- **payments** — Payment records per invoice

### Auto-computed Features (DB Triggers)
- `updated_at` auto-updated on all tables
- Room status auto-synced on checkin status change
- Invoice number auto-generated (`INV-2024-0001`)
- Invoice totals auto-recalculated on update
- Invoice payment_status auto-updated on payment insert

---

## 🎨 Flutter App Features

| Screen | Features |
|--------|----------|
| **Login** | Email/password, error handling, responsive (side panel on wide screens) |
| **Dashboard** | Live stats cards, revenue bar chart (fl_chart), recent check-ins |
| **Rooms** | Tab filters, grid layout, status badges, status update dropdown |
| **Check-in** | Active list with checkout button, new check-in form with date pickers |
| **Invoices** | Filter by status, bottom sheet detail, add payment dialog, PDF download |
| **Staff** | Role filter, add staff dialog, mark attendance |
| **Guests** | Search, list, detail sheet with stay history |

---

## 🛡️ Role-Based Access

| Action | Admin | Manager | Receptionist | Housekeeping |
|--------|-------|---------|--------------|--------------|
| Create/Delete rooms | ✅ | ✅ | ❌ | ❌ |
| Check-in / Check-out | ✅ | ✅ | ✅ | ❌ |
| View invoices | ✅ | ✅ | ✅ | ❌ |
| Add staff | ✅ | ✅ | ❌ | ❌ |
| Update room status | ✅ | ✅ | ✅ | ✅ |

---

## 🧪 Default Credentials

After running migrations:
- **Email:** `admin@hotel.com`
- **Password:** `admin123`

---

## 📦 Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.x (Dart, Provider, fl_chart) |
| Backend | Node.js + Express.js |
| Database | PostgreSQL 14+ |
| Storage | Cloudinary (ID proof images) |
| Auth | JWT (jsonwebtoken + bcryptjs) |
| PDF | PDFKit |
| File Upload | Multer + multer-storage-cloudinary |

---

## 📝 License

MIT — Free to use for personal and commercial projects.
