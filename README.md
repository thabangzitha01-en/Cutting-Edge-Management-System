# Cutting Edge Salon — Booking & Management System

A full-stack salon booking system for **ITC327W – Group B**. Includes a Flutter mobile app (Customer/Stylist), an ASP.NET web portal (Manager), and a shared Supabase backend.

## Architecture
Flutter App (Customer/Stylist) ─┐
├──▶ Supabase (PostgreSQL + Auth + RLS)
ASP.NET Web App (Manager) ──────┘

Both apps share the same Supabase project, auth, and RLS policies. Booking statuses are standardised: `Pending → Confirmed → Cancelled → Completed`.

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile | Flutter (Dart) |
| Web | ASP.NET (C#) |
| Backend | Supabase (PostgreSQL, Auth, RLS) |
| Version Control | Git / GitHub |

## Features

**Customer / Stylist (Flutter)**
- Register/login, view services & pricing (FR-01)
- Book appointments with double-booking prevention (FR-03, FR-04)
- Select payment method: Cash/Card (FR-18)
- View & cancel own bookings (FR-08)
- Stylist: view appointments, manage availability, block dates

**Manager (ASP.NET)**
- Login with predefined credentials
- Dashboard with live metrics
- Manage all bookings (FR-06), approve requests, view cancellations
- Manage stylist profiles (FR-07), services, prices, promotions
- View reports and manage gallery

## Database Schema

| Table | Key Fields |
|---|---|
| `profiles` | `id` (PK), `full_name`, `email`, `phone`, `role_id` |
| `stylists` | `stylist_id` (PK), `profile_id` (FK), `active` |
| `services` | `service_id` (PK), `name`, `price`, `duration_minutes` |
| `bookings` | `booking_id` (PK), `customer_id`, `stylist_id`, `service_id`, `payment_method_id` (FKs), `appointment_date`, `start_time`, `status` |

All tables use UUID primary keys with FK relationships and NOT NULL constraints.

## User Roles

| Role | Access |
|---|---|
| Customer | Register, login, view services, book, cancel own bookings, select payment |
| Stylist | Login, view own appointments, manage availability, block dates |
| Manager | Manage all bookings, services, stylists, promotions, view reports |

Access enforced via Supabase RLS policies.

## Integration Workflows

| Process | Flutter | ASP.NET | Shared Data |
|---|---|---|---|
| Booking request | Customer submits | Manager approves | `Pending → Confirmed` |
| Cancellation | Customer cancels | Manager views reason | Status `Cancelled` |
| Availability | Stylist updates | Manager views schedule | `work_date`, times |
| Service/price | Customer views | Manager updates | Service record |

## Getting Started

### Prerequisites
- Flutter SDK
- .NET SDK
- Supabase project
- Git

### Backend (Supabase)
1. Create a Supabase project.
2. Run SQL migrations to create `profiles`, `stylists`, `services`, `bookings`, `payment_methods`.
3. Enable Supabase Auth.
4. Apply RLS policies per role.
5. Seed test data.

### Flutter App
```bash
cd mobile
flutter pub get
flutter run

ASP.NET Web App
cd web
dotnet restore
dotnet run
Functional Requirements
Req	App	Status
FR-01: View service catalogue	Flutter	✅
FR-03: Book appointment online	Flutter	✅
FR-04: Prevent double bookings	Flutter + Supabase	✅
FR-06: Manage all bookings	ASP.NET	✅
FR-08: Customer cancellation	Flutter	✅
FR-18: Payment method selection	Flutter	✅
Known Limitations
Automated email reminders (FR-09) simplified to manual reminders via admin dashboard.

No real-time updates — users must refresh to see cross-app changes.

Online payments not implemented; Cash/Card is a preference only.

Project Structure
Group-B-/
├── mobile/       # Flutter app (Customer / Stylist)
├── web/          # ASP.NET app (Manager)
├── supabase/     # SQL migrations, RLS policies, seed data
└── README.md
