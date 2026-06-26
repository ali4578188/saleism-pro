# SALEISM PRO — Flutter Source Code

Wholesale Inventory Management System for Android (Flutter + SQLite).

---

## 🚀 Quick Setup

### Prerequisites
- Flutter SDK 3.10+: https://docs.flutter.dev/get-started/install
- Android Studio or VS Code with Flutter plugin
- Android phone or emulator (Android 6.0+, minSdkVersion 23)

### Steps
```bash
# 1. Extract this ZIP and open folder
cd saleism_pro

# 2. Get dependencies
flutter pub get

# 3. Run on connected Android device
flutter run

# 4. Build release APK
flutter build apk --release
# APK output: build/app/outputs/flutter-apk/app-release.apk
```

---

## 🔐 Default Login
- **PIN:** `1234`
- **Role:** Admin (full access)

---

## ✨ Features

| Feature | Details |
|---|---|
| 🔐 Auth | PIN + Fingerprint login, Admin/Staff roles |
| 📦 Stock | Cartons/Boxes/Pieces tracking, Low stock alerts |
| 🏢 Companies | Suppliers & customers with ledger & credit |
| 🛒 Purchases | Invoice entry, multi-item, payment tracking |
| 💰 Sales | Invoice generation, discount, cash/credit/bank |
| 📊 Reports | Sales report, Profit report (Admin only), Stock report |
| 📈 Charts | Bar chart profit trend (fl_chart) |
| 🔍 Barcode | Scanner via camera (mobile_scanner) |
| 💾 Backup | SQLite backup to external storage |
| 🌙 Theme | Dark orange + black UI |

---

## 📁 Project Structure

```
lib/
├── main.dart               # Entry point
├── app.dart                # App + providers
├── core/
│   ├── constants/          # Colors, theme, strings
│   ├── database/           # SQLite (database_helper.dart)
│   └── utils/              # Currency & date formatting
├── providers/              # State: auth, company, product, purchase, sale, dashboard
├── screens/
│   ├── auth/               # Login screen (PIN + fingerprint)
│   ├── dashboard/          # Summary + stats + alerts
│   ├── companies/          # CRUD + ledger
│   ├── products/           # CRUD + barcode scan
│   ├── purchases/          # Entry + item management
│   ├── sales/              # Entry + item management + profit
│   ├── stock/              # Stock view + low stock
│   ├── reports/            # Sales/Profit/Stock reports + chart
│   └── settings/           # Company settings + backup + users
└── widgets/                # StatCard, etc.
```

---

## 🗄️ Database Tables

- `users` — admin & staff accounts
- `companies` — suppliers/customers
- `categories` — product categories
- `products` — with stock (cartons/boxes/pieces)
- `purchases` + `purchase_items` — purchase invoices
- `sales` + `sale_items` — sale invoices with profit tracking
- `ledger` — company credit/debit history
- `payments` — payment records
- `settings` — app configuration

---

## 📦 Build APK

```bash
flutter build apk --release
```
APK location: `build/app/outputs/flutter-apk/app-release.apk`

Transfer to your Android device and install.

---

## 🔑 Key Dependencies

```yaml
provider: ^6.1.2       # State management
sqflite: ^2.3.3        # SQLite database
fl_chart: ^0.68.0      # Charts
mobile_scanner: ^5.2.3  # Barcode scanner
local_auth: ^2.2.0     # Fingerprint auth
pdf + printing          # PDF export
excel: ^4.0.3          # Excel export
permission_handler      # Runtime permissions
```

---

## 🎨 Theme

- **Primary:** `#FF6B00` (Dark Orange)
- **Background:** `#0A0A0A` (Near Black)
- **Cards:** `#1A1A1A`
- **Accent text:** `#FF6B00`
- **Success:** `#00C853` (Green)
- **Error:** `#FF1744` (Red)

---

## ⚙️ Permissions (Android)
- `USE_BIOMETRIC` — fingerprint login
- `CAMERA` — barcode scanning
- `WRITE_EXTERNAL_STORAGE` — backup files
- `MANAGE_EXTERNAL_STORAGE` — Android 11+

---

## 💡 Tips

- First run creates the database automatically with default admin PIN `1234`
- Change your PIN in Settings > User Management
- Backup created at: `/sdcard/SaleismProBackup/backup_TIMESTAMP.db`
- Staff users see all features EXCEPT profit reports
- Admin users have full access including user management

---

Made with ❤️ using Flutter + SQLite
