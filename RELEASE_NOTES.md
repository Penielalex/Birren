# Release notes

## v1.0.1 — Dual loan tracking

### Loans (restored + improved)
- **Lent to someone:** categorize outgoing money as **Loan** (expense), then link incoming **Returns** to that loan
- **Borrowed money:** categorize incoming money as **Loan** (income), then link outgoing **Loan Repayment** to that loan
- Loans tab shows whether each loan is lent or borrowed, with the correct labels and linked transactions

### Install
Download **app-release.apk** from [GitHub Releases](https://github.com/Penielalex/Birren/releases).

---

## v1.0.0 — Initial production release

**Birren** is a personal finance app for Ethiopia. It reads bank and mobile-money SMS on your Android device, organizes your money across accounts, and helps you stay on budget — with everything stored locally on your phone.

### Install

- Download **app-release.apk** from [GitHub Releases](https://github.com/Penielalex/Birren/releases/tag/v1.0.0)
- Requires **Android 11+** (API 30+)
- Grant **SMS** permission when prompted for automatic transaction import

---

### Accounts & SMS import

- Add accounts for **BOA**, **CBE**, **127 (Telebirr)**, **M-PESA**, and **Cash**
- Import transactions automatically from SMS (Cash is manual-only)
- Display names and balances on a multi-account grid
- Incremental sync — only new messages are processed after the first import

### Transactions & categories

- Track income and expenses with full category lists
- **Notifications** tab for uncategorized SMS transactions
- Link expenses to budget line items when a budget is active
- **Internal transfer** pairing with same-day matching or transfer to **Cash**
- Auto-link **Transfer Fee** when pairing internal transfers
- View transaction details, including source SMS text when available
- Drill into transactions by day or month from the calendar

### Budgets

- Create budget cycles with start/end dates and custom line items
- **Total / Spent / Left** summary on the My Money tab
- Per line-item progress bars (green → amber → red by usage)
- Budget history, edit, and delete
- Calendar indicators based on daily and monthly budget allowance

### Loans

- **Lent:** outgoing Loan (expense) + linked Returns (income)
- **Borrowed:** incoming Loan (income) + linked Loan Repayment (expense)
- Open loans list, close loan with write-off

### Cash

- Manual **Cash** account with in-app FAB to add transactions
- Choose category at entry time (Cash never appears in Notifications)
- Bank withdrawals to cash via internal transfer update the Cash balance automatically

### Spending limits

- Set daily, monthly, and yearly limits
- Limit cards on the Accounts tab

### Security & backup

- Guest or Google sign-in
- Optional **PIN lock** when the app resumes
- All data stored locally in SQLite (Drift)
- **Export and restore** full backups as JSON (accounts, transactions, budgets, loans, limits)

### Android home screen widget

- **Birren Budget** widget mirrors the in-app budget card
- Shows line-item names, spent/allocated amounts, and progress bars
- **Create** button when no budget exists — opens the app to start a new budget

---

### Supported SMS senders

| Sender | Service |
|--------|---------|
| BOA | Bank of Abyssinia |
| CBE | Commercial Bank of Ethiopia |
| 127 | Telebirr |
| MPESA | M-PESA |

---

### Known limitations

- **Android only** in this release (SMS import and home widget are not available on iOS)
- Release APK is signed with the debug keystore — suitable for sideloading, not Play Store distribution without your own signing config
- SMS formats can change; if parsing fails, update the app when a new parser version is available

---

### Build from source

See [README.md](README.md) for Flutter setup and build instructions.
