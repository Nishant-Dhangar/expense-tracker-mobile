# 💰 Expense Tracker Mobile

A cross-platform personal finance mobile application built with **Flutter**, connected to a **Spring Boot REST API** and **MySQL** backend.

The app allows users to securely track income and expenses, manage monthly budgets, view spending analytics, and quickly add expenses using a shake-to-open Quick Expense feature.

---

## 📱 Features

### 🔐 Authentication & Security

- User registration and login
- Secure session-based authentication
- Persistent login sessions
- Logout functionality
- Protected user data
- Per-user transaction and budget isolation

### 💸 Expense & Income Tracking

- Add income and expenses
- Edit transactions
- Delete transactions
- Categorize transactions
- Transaction history
- Current balance calculation
- Income and expense summaries

### 📊 Dashboard & Analytics

- Current balance overview
- Income vs. expenses
- Spending breakdown
- Monthly spending trends
- Month-to-month comparison
- Savings rate
- Recent transactions

### 💰 Monthly Budgets

- Create monthly budgets
- Track current-month spending
- Budget progress indicators
- Remaining budget calculation
- Budget alerts when spending reaches important thresholds

### ⚡ Quick Expense

A dedicated quick-entry experience designed for fast expense recording.

**Shake the phone → Quick Expense opens → enter the expense → save → overlay closes.**

This allows users to record an expense without navigating through the full dashboard.

### 🔔 Notifications

- Budget spending notifications
- 80% budget threshold alert
- 100% budget threshold alert
- User-controlled notification settings

### 🎨 User Experience

- Responsive Flutter UI
- Dark mode
- Persistent app settings
- Clean dashboard interface
- Mobile-focused navigation

---

## 🏗️ Architecture

```text
┌──────────────────────────────┐
│       Flutter Mobile App     │
│                              │
│  Android        iOS          │
│       │          │            │
│       └────┬─────┘            │
│            │ HTTPS             │
└────────────┼──────────────────┘
             │
             ▼
┌──────────────────────────────┐
│     Spring Boot REST API     │
│                              │
│  Spring Security             │
│  Authentication              │
│  Transaction APIs             │
│  Budget APIs                  │
│  Category APIs                │
└────────────┼──────────────────┘
             │ JDBC
             ▼
┌──────────────────────────────┐
│          MySQL               │
│                              │
│  Users                       │
│  Transactions                │
│  Categories                  │
│  Budgets                     │
└──────────────────────────────┘



🛠️ Tech Stack

Mobile
Flutter
Dart
Dio
Local notifications
Device sensors
Backend
Java
Spring Boot
Spring Security
Spring Data JPA
Hibernate
REST API
Database
MySQL
Deployment
Flutter — Android / iOS
Render — Spring Boot backend
Aiven — MySQL database
Vercel — Web dashboard
🔒 Security

The application implements several security measures:

Spring Security authentication
BCrypt password hashing
Session-based authentication
CSRF protection
Secure session cookies in production
Server-side authorization
Per-user transaction ownership
Per-user budget ownership
Input validation
Safe API response DTOs

Users can only access their own transactions and budgets.

🌐 Related Projects
Backend

Spring Boot REST API and MySQL integration:

Repository:
https://github.com/Nishant-Dhangar/Expense-tracker

Web Dashboard

Responsive web interface for the same backend:

Live Web App:
https://expense-tracker-web-eight-alpha.vercel.app/

🚀 Getting Started
Prerequisites

Make sure you have installed:

Flutter SDK
Dart SDK
Android Studio / Android SDK
Xcode for iOS development
Git
Clone the repository
git clone <https://github.com/Nishant-Dhangar/expense-tracker-mobile>
cd expense_tracker_mobile
Install dependencies
flutter pub get
Check Flutter environment
flutter doctor
Run the application
flutter run

You can run the application on:

Android emulator
Android physical device
iOS simulator
iOS physical device
📌 Project Status

Version: v1.0.0

The mobile application currently includes authentication, transaction management, budgets, analytics, notifications, dark mode, and Quick Expense functionality.

🔮 Future Improvements
App store deployment
Push notifications
Recurring transactions
Advanced financial reports
Export transactions
Custom user categories
Improved offline support
Additional financial insights

👨‍💻 Author
Nishant Dhangar

GitHub:
https://github.com/Nishant-Dhangar
