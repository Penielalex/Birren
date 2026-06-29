# Birren

Birren is a Flutter personal finance app built for Ethiopia. It reads bank and mobile-money SMS on your device, turns them into transactions, and helps you track accounts, budgets, loans, and spending limits — all stored locally on your phone.

## Features

### Accounts & SMS import
- Connect **BOA**, **CBE**, **127**, **M-PESA**, and a manual **Cash** account
- Automatic transaction import from SMS (Cash is manual-only)
- Multi-account grid with balance display and account nicknames
- Per-bank sync checkpoints so only new messages are processed

### Transactions
- Income and expense tracking with categories
- **Notifications** tab for uncategorized SMS transactions
- Category assignment with budget line-item linking for expenses
- **Internal transfer** pairing (same-day match or transfer to Cash)
- **Transfer fee** auto-linking when categorizing internal transfers
- Transaction detail view with optional SMS source text
- Date and month drill-down from the calendar

### Budgets
- Budget cycles with start/end dates and named line items
- Total / Spent / Left summary on the My Money tab
- Per line-item progress bars (green → amber → red by usage)
- Budget history, edit, and delete
- Calendar heat indicators tied to daily/monthly budget allowance

### Loans
- Track money **borrowed from outside** (Income → Loan)
- Record repayments (Expense → Loan Repayment)
- Open loans list with return history
- Close loan with write-off expense (category + budget line item)

### Cash
- Manual cash account with FAB to add transactions
- Categories chosen at entry time (not via Notifications)
- Internal transfers from banks can credit/debit Cash automatically

### Limits
- Daily, monthly, and yearly spending limits
- Visual limit cards on Accounts

### Security & data
- Guest or Google sign-in
- Optional PIN lock on resume
- Local SQLite database (Drift) — data stays on device
- JSON backup export and restore (accounts, transactions, budgets, loans, limits)

### Android home screen widget
- **Birren Budget** widget shows the active budget (same layout as the app)
- Line-item bars and spent/allocated amounts
- **Create** button when no budget exists (opens the app to add one)

## Tech stack

| Layer | Tools |
|-------|--------|
| UI | Flutter, GetX |
| Database | Drift (SQLite) |
| SMS | Android `ContentResolver` + regex parser |
| Widget | `home_widget` + Jetpack Glance |
| Other | `shared_preferences`, `permission_handler`, `intl`, `google_fonts` |

## Architecture

Clean architecture with use cases between UI and data:

```
lib/
├── app/              # Use cases
├── domain/           # Entities & repository interfaces
├── data/             # Drift DAOs, repositories, SMS & backup services
├── presentation/     # GetX controllers, pages, widgets
└── main.dart
```

## Requirements

- **Flutter** SDK `^3.6.1`
- **Android** device or emulator (API 30+); SMS features require a physical device with SMS permission
- Android Studio or VS Code with Flutter/Dart extensions

## Getting started

```bash
# Clone the repository
git clone https://github.com/Penielalex/Birren.git
cd Birren

# Install dependencies
flutter pub get

# Generate Drift code (if you change database schema)
dart run build_runner build --delete-conflicting-outputs

# Run on a connected device
flutter run
```

## Building a release APK

```bash
flutter build apk --release
```

The APK is written to:

```
build/app/outputs/flutter-apk/app-release.apk
```

Install on a device with USB debugging or sideload the APK. Release builds are currently signed with the debug keystore for local testing; configure your own signing config in `android/app/build.gradle` before Play Store distribution.

## Permissions (Android)

| Permission | Purpose |
|------------|---------|
| `READ_SMS` / `RECEIVE_SMS` | Import bank transaction SMS |
| `INTERNET` | Google sign-in (optional) |

## Adding the budget widget (Android)

1. Long-press the home screen → **Widgets**
2. Find **Birren Budget**
3. Place and resize the widget
4. Open the app at least once so budget data syncs to the widget

## Supported banks (SMS)

| Sender | Service |
|--------|---------|
| BOA | Bank of Abyssinia |
| CBE | Commercial Bank of Ethiopia |
| 127 | Bank |
| MPESA | M-PESA mobile money |

SMS formats change over time; parser rules live in `lib/data/service/sms_regex_parser.dart`.

## Project scripts (optional)

| Script | Purpose |
|--------|---------|
| `scripts/validate_sms_parser.dart` | Validate SMS regex against sample messages |
| `scripts/analyze_sms_logs.py` | Analyze exported SMS logs |
| `scripts/download_model.ps1` | Download optional on-device model weights (not required for core app) |

## License

This project is provided as-is for personal use. See repository history for authorship.
