⚙️ Backend — Node.js + Express (backend/src/)
| Layer | Files | |---| | Config | index.js, db.js, cloudinary.js, migrate.js | | Middleware | auth.js (JWT), errorHandler.js | | Controllers | auth, room, guest, checkin, invoice, staff, dashboard | | Routes | All 7 route files with role-based access | | Utils | response.js, invoiceGenerator.js (professional PDF with PDFKit) |

📱 Flutter App (flutter_app/lib/)

Layer	Files
Config	api_config.dart, theme.dart (Light + Dark)
Models	User, Room, Guest, Checkin, Invoice, Payment, Staff
Providers	AuthProvider, RoomProvider, DashboardProvider
Services	AuthService, ApiService, RoomService, CheckinService, InvoiceService, StaffService, DashboardService
Screens	Login, Dashboard (with bar chart), Rooms, Check-in/out, Invoices, Staff, Guests
Widgets	StatCard, RoomCard, StatusBadge, AppSidebar
🚀 Quick Start
bash

# 1. Setup database
psql -U postgres -c "CREATE DATABASE hotel_management;"
cd backend && npm install && npm run migrate


# 2. Start backend
cp .env.example .env  # fill in your values
npm run dev           # runs on :5000

# 3. Run Flutter app
cd flutter_app
flutter pub get
mkdir -p assets/images
flutter run           # or: flutter build apk
🌟 Key Features Delivered

Feature	Details
Auth	JWT login, role-based access (admin/manager/receptionist/housekeeping)
Check-in/out	Full flow with room assignment, guest capture, auto room status update
Invoices	Auto GST calc (CGST 9% + SGST 9%), multi-payment support, PDF download
Dashboard	Live stats, revenue bar chart (fl_chart), recent check-ins
Rooms	Grid view, status filters, status badges, per-room status update
Staff	Create staff + user account in one transaction, attendance marking
Responsive UI	Sidebar on desktop, drawer on mobile, dark mode support
ID Proof Upload	Cloudinary integration via multer

