# TindaTap v1.0.3

**Offline-first Point of Sale (POS) & Inventory Management App**

A powerful Android application designed for sari-sari store owners to manage their inventory, sales, and customer transactions completely offline. All data is stored securely on your device using SQLite.

## Features

- ✅ **Fully Offline** - Complete functionality without internet connection
- ✅ **Inventory Management** - Track stock levels, product details, and pricing
- ✅ **Point of Sale (POS)** - Easy-to-use checkout system with item search
- ✅ **Sales History** - View and manage transaction records
- ✅ **QR Code Support** - Generate product QR codes for labels and inventory
- ✅ **Data Backup** - Export and backup your database anytime
- ✅ **Lightweight** - Minimal storage footprint, works on low-end devices
- ✅ **User-Friendly** - Simple interface designed for store operators

## System Requirements

- **Android Version:** Android 6.0 (API Level 21) or higher
- **Storage:** Minimum 50 MB free space
- **RAM:** 1 GB or more recommended
- **Device:** Any Android smartphone or tablet

## Installation

### From APK File

1. Download the `TindaTap_v1.0.3.apk` file to your Android device
2. Open your file manager and navigate to the Downloads folder
3. Tap the APK file to start installation
4. Grant necessary permissions when prompted
5. Tap "Install" and wait for completion
6. Launch the app from your app drawer

### From Source (Developers)

1. Install Flutter 3.16 or higher from [flutter.dev](https://flutter.dev)
2. Clone this repository: `git clone <repository-url>`
3. Navigate to the project folder: `cd TindaTap_v1.0.3`
4. Install dependencies: `flutter pub get`
5. Connect an Android device or start an emulator
6. Run the app: `flutter run`

## First Launch

On your first login, TindaTap will guide you through:

1. Store setup (store name, location, etc.)
2. Initial product inventory configuration
3. Cashier profile setup

## How to Use

### Basic Workflow

1. **Add Products** - Go to Inventory and add your products with prices
2. **Manage Stock** - Update quantities as you receive or sell items
3. **Ring Up Sales** - Use the POS interface to search products and complete transactions
4. **View Reports** - Check sales history and inventory status
5. **Backup Data** - Regularly export your database through Settings

## Important Notes

- **Data Storage** - All customer and transaction data is stored locally on your device in SQLite database
- **QR Codes** - Generated QR code images are saved in your app's documents folder
- **Backups** - Use the Export button in Settings to create database backups and store them safely
- **Security** - Keep your device secure to protect your business data
- **Permissions** - The app may request file access for backups

## Troubleshooting

| Issue                  | Solution                                                                  |
| ---------------------- | ------------------------------------------------------------------------- |
| App won't install      | Enable "Unknown sources" in device Security settings                      |
| App crashes on startup | Clear app cache: Settings > Apps > TindaTap > Storage > Clear Cache       |
| Database export fails  | Ensure you have file storage permission and sufficient free storage space |

## Permissions Required

- **Storage** - For database backups and QR code images
- **Internet** - Not required (used only for diagnostic/logging if enabled)

## Support & Feedback

For issues, suggestions, or feature requests, please contact the development team or open an issue in the project repository.

## Version Information

- **Current Version:** 1.0.3
- **Built With:** Flutter Framework
- **Database:** SQLite
- **Target Audience:** Sari-sari store operators and small retailers

## License

This project is proprietary software. All rights reserved.

---

**Last Updated:** May 2026
**Made for sari-sari store owners by developers who understand your needs.**
