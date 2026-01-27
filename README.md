# 📱 Fest OC Attendance App

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg?style=for-the-badge)](https://github.com/nadarallen/Fest-OC-Attendence-App/graphs/commit-activity)

> **Modern, efficient, and offline-first attendance management.**
>
> Streamline your event or class attendance with barcode scanning, local database storage, and easy CSV exports.

---

## 🚀 Overview

The **Fest OC Attendance App** is designed to simplify the process of tracking attendance. Whether you're managing a classroom, a workshop, or a large festival organizing committee, this app provides a seamless experience.

Built with **Flutter**, it ensures a smooth, native performance on both Android and iOS. It leverages local **SQLite** databases for robust offline capabilities, ensuring you never lose data even without an internet connection.

## ✨ Key Features

- **📷 Instant Scanning**: Uses `mobile_scanner` for fast and accurate QR and Barcode scanning.
- **💾 Offline-First**: All data is stored locally using `sqflite`, ensuring privacy and reliability.
- **📊 Data Export**: Easily export your attendance records to CSV format for external analysis or reporting.
- **🎨 Modern UI**: Clean, intuitive interface powered by Google Fonts and Material Design 3.
- **⚡ High Performance**: Optimized for speed and low battery consumption.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/)
- **Language**: [Dart](https://dart.dev/)
- **Database**: [SQLite](https://pub.dev/packages/sqflite)
- **Scanning**: [Mobile Scanner](https://pub.dev/packages/mobile_scanner)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Export**: [CSV](https://pub.dev/packages/csv)

## 📂 Project Structure

```
lib/
├── models/         # Data models (Student, Attendance)
├── providers/      # State management logic
├── screens/        # UI screens (Dashboard, Scanner, List)
└── main.dart       # Entry point
```

## 🏁 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) installed.
- An Android/iOS device or emulator.

### Installation

1. **Clone the repository:**

    ```bash
    git clone https://github.com/nadarallen/Fest-OC-Attendence-App.git
    cd Fest-OC-Attendence-App
    ```

2. **Install dependencies:**

    ```bash
    flutter pub get
    ```

3. **Run the app:**

    ```bash
    flutter run
    ```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  Made with ❤️ by Salmo.dev
</p>
