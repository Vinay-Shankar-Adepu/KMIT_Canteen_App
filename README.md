# 🍴 KMIT Canteen App

A mobile application built with Flutter for KMIT College to streamline the canteen experience for students and administrators.

## 🚀 Features

### 👨‍🎓 For Students
- 📋 View full menu with images and prices
- ❤️ Mark favorites
- 🛒 Add items to cart and confirm orders
- 🔁 Reorder from previous orders
- 📦 Track order status (Pending → Preparing → Ready → Delivered)
- 📍 Choose a pickup point
- 📱 Receive a QR confirmation code for pickup

### 🛠️ For Admin
- 🧾 Admin dashboard to view and filter all active orders
- 🚦 Change order status in real-time
- 📷 Scan student QR codes to confirm delivery
- 📊 See order counts, prices, and live updates

## 📦 Tech Stack

- **Flutter** for UI
- **Firebase Firestore** for real-time data storage
- **Firebase Auth** for authentication
- **Hive** for local storage
- **Razorpay** (Test mode) for payments
- **mobile_scanner** for QR code scanning

## 📲 Getting Started

### Prerequisites

- Flutter SDK (>= 3.0.0)
- Firebase CLI (if using Firebase Hosting or Emulator)

### Clone and Run

```bash
git clone https://github.com/yourusername/kmit-canteen.git
cd kmit-canteen
flutter pub get
flutter run
