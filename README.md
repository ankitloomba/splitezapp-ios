# SplitEZ — iOS App

Native iOS app for SplitEZ, built with **SwiftUI** and **MVVM** architecture.

## Requirements

- iOS 17.0+
- Xcode 15+
- Swift 5.9+

## Architecture

```
SplitEZ/
├── App/              # App entry point
├── Models/           # Codable data models matching API
├── Services/         # API client, Auth service, Keychain
├── Views/
│   ├── Auth/         # Login, Register, Forgot Password
│   ├── Home/         # Main tab view, Home dashboard
│   ├── Groups/       # Group list, detail, create
│   ├── Trips/        # Trip list, detail, create
│   ├── Expenses/     # Expense row, create expense
│   ├── Finances/     # Income, personal expenses, summary
│   ├── Notifications/# Notification list
│   └── Settings/     # Profile, people, logout
├── ViewModels/       # (future: complex view models)
└── Utils/            # Theme, Avatar component, Color extension
```

## Features

- ✅ Email + password authentication (register, login, verify, reset)
- ✅ JWT token management with auto-refresh & Keychain storage
- ✅ Home dashboard with balances, activity feed, promo banners
- ✅ Groups — create, list, view members/expenses/balances
- ✅ Trips — create, list, view details/expenses
- ✅ Expenses — create with EQUAL/EXACT/PERCENTAGE splits
- ✅ My Finances — income tracking, personal expenses, monthly summary
- ✅ Notifications — list, mark read, mark all read
- ✅ Settings — edit profile, contacts, logout
- ✅ Pull-to-refresh on all list screens
- ✅ Deterministic avatar colors from user ID

## API

Points to `https://splitez-backend-production.up.railway.app/api`

All monetary values displayed by converting minor units (paise) to major units.
