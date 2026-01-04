<p align="center">
  <img src="assets/images/logo.png" alt="diRead Logo" width="120" height="120">
</p>

<h1 align="center">diRead</h1>

<p align="center">
  <strong>Your Private Family Digital Library</strong><br>
  Read beautifully. Sync seamlessly. Own your books.
</p>

<p align="center">
  <a href="#-why-diread">Why diRead</a> •
  <a href="#-features">Features</a> •
  <a href="#-quick-start">Quick Start</a> •
  <a href="#-screenshots">Screenshots</a> •
  <a href="#-roadmap">Roadmap</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.1+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/FastAPI-0.100+-009688?style=for-the-badge&logo=fastapi&logoColor=white" alt="FastAPI">
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-blueviolet?style=for-the-badge" alt="Platform">
</p>

---

## 📖 Why diRead?

Ever wanted your own private e-book library that just *works*?

**diRead** is built for families who:
- 📚 Have a personal collection of PDFs and EPUBs
- 🔒 Want their reading data private — no tracking, no ads
- 📱 Read across multiple devices and want everything synced
- ✨ Appreciate a clean, distraction-free reading experience

> Think of it as your personal Apple Books — but you own the server too.

---

## ✨ Features

### 📱 Beautiful Reading Experience

| Feature | Description |
|---------|-------------|
| **PDF & EPUB Support** | High-quality rendering with Syncfusion PDF Viewer |
| **6 Reading Themes** | Light, Dark, Sepia, Blue, Green, Cream |
| **3 Scroll Modes** | Horizontal swipe, Vertical swipe, Continuous scroll |
| **Smart Navigation** | Slider, Go-to-page, Table of Contents |
| **Bookmarks** | One-tap bookmark with visual feedback (red when active) |
| **Progress Tracking** | Automatic save & sync across devices |
| **Offline Reading** | Downloaded books work without internet |

### 🔐 Privacy & Security

- **Your server, your data** — Self-hosted backend
- **Secure authentication** — JWT tokens with refresh rotation
- **Encrypted storage** — Tokens stored in secure storage
- **Per-user libraries** — Each family member has private books
- **No telemetry** — Zero tracking, zero analytics

### 📲 Cross-Platform

Works everywhere you read:

| Platform | Status |
|----------|--------|
| Android | ✅ Ready |
| iOS | ✅ Ready |
| Web Browser | ✅ Ready |
| macOS | ✅ Ready |
| Windows | ✅ Ready |
| Linux | ✅ Ready |

---

## 🚀 Quick Start

### What You Need

- **Flutter SDK** 3.1+
- **Python** 3.9+
- **10 minutes** of your time ☕

### Step 1: Clone & Setup Backend

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/diread.git
cd diread/backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Start the server
python main.py
```

🎉 Backend running at `http://localhost:8000`

### Step 2: Run the App

```bash
# From project root
cd ..
flutter pub get
flutter run
```

### Step 3: Create Your Account

1. Open the app
2. Tap "Create Account"
3. Start uploading your books!

---

## 📸 Screenshots

<p align="center">
  <em>Coming soon — beautiful screenshots of the reading experience</em>
</p>

---

## 🎨 Reading Themes

Choose the theme that's easiest on your eyes:

| Theme | Background | Best For |
|-------|------------|----------|
| ☀️ **Light** | Pure White | Bright environments |
| 🌙 **Dark** | Deep Black | Night reading |
| 📜 **Sepia** | Warm Beige | Long reading sessions |
| 💙 **Blue** | Soft Blue | Reduced eye strain |
| 🌿 **Green** | Calm Green | Relaxed reading |
| 🍦 **Cream** | Soft Yellow | Comfortable contrast |

---

## 📂 What Can You Upload?

| Format | Max Size | Features |
|--------|----------|----------|
| **PDF** | 100 MB | Full rendering, zoom, scroll modes |
| **EPUB** | 100 MB | Reflowable text, TOC, custom fonts |

Automatic extraction of:
- 📖 Book title
- ✍️ Author name
- 🖼️ Cover image

---

## 🛠️ Tech Stack

### Frontend (Flutter)
- **Provider** — State management
- **go_router** — Navigation with auth guards
- **Dio** — HTTP client with token refresh
- **Syncfusion** — PDF rendering
- **flutter_secure_storage** — Secure token storage

### Backend (Python)
- **FastAPI** — Async REST API
- **SQLAlchemy** — Database ORM
- **PyJWT** — Authentication
- **bcrypt** — Password hashing
- **pypdf + ebooklib** — Metadata extraction

---

## 🗺️ Roadmap

### ✅ Version 1.0 (Current)
- [x] PDF & EPUB reading
- [x] 6 reading themes
- [x] 3 scroll directions
- [x] Bookmarks with visual feedback
- [x] Session persistence (stay logged in)
- [x] Splash screen
- [x] Cross-platform support
- [x] Offline reading
- [x] Progress sync

### 🔜 Version 1.1 (Next)
- [ ] Full-text search inside books
- [ ] Highlights with notes
- [ ] Export annotations
- [ ] Reading statistics

### 🔮 Future
- [ ] Family sharing
- [ ] Book collections
- [ ] Text-to-speech
- [ ] Reading goals

---

## 📁 Project Structure

```
diread/
├── lib/                    # Flutter app
│   ├── core/               # Config, theme, utilities
│   ├── data/               # Models, repositories, API
│   └── presentation/       # UI screens & providers
│
├── backend/                # FastAPI server
│   ├── app/                # Routes, models, services
│   ├── main.py             # Entry point
│   └── requirements.txt    # Dependencies
│
└── assets/                 # Images, icons, fonts
```

---

## 🔧 Configuration

### Backend (.env)

```env
SECRET_KEY=your-super-secret-key
DATABASE_URL=sqlite+aiosqlite:///./diread.db
MAX_FILE_SIZE_MB=100
```

### Frontend (app_config.dart)

```dart
static const String apiBaseUrl = 'http://YOUR_SERVER:8000/api/v1';
```

---

## 🚢 Deployment

### Android Release

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Backend (Docker)

```bash
cd backend
docker build -t diread-api .
docker run -p 8000:8000 diread-api
```

---

## 🤝 Contributing

We welcome contributions! Here's how:

1. Fork the repository
2. Create your branch: `git checkout -b feature/awesome`
3. Commit changes: `git commit -m 'Add awesome feature'`
4. Push: `git push origin feature/awesome`
5. Open a Pull Request

---

## 📄 License

This project is designed for private/family use. See [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

Built with love using:
- [Flutter](https://flutter.dev) — Beautiful cross-platform apps
- [FastAPI](https://fastapi.tiangolo.com) — Modern Python API framework
- [Syncfusion](https://www.syncfusion.com) — PDF viewer component

---

<p align="center">
  <strong>Made with ❤️ for families who love reading together</strong>
</p>

<p align="center">
  <sub>diRead — Because your books deserve a beautiful home.</sub>
</p>
