<div align="center">

<img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
<img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"/>
<img src="https://img.shields.io/badge/TMDB-01B4E4?style=for-the-badge&logo=themoviedatabase&logoColor=white" alt="TMDB"/>
<img src="https://img.shields.io/badge/Version-1.0.0-brightgreen?style=for-the-badge" alt="Version"/>
<img src="https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge" alt="License"/>

# 🎬 CineMovie

### *Your ultimate cinematic companion — discover, explore, and track movies & TV shows*

[Features](#-features) • [Screenshots](#-screenshots) • [Demo](#-demo) • [Installation](#-installation) • [Architecture](#-architecture) • [API](#-api-integration) • [Contributing](#-contributing)

---

</div>

## ✨ Overview

**CineMovie** is a beautifully crafted Flutter application that brings the world of cinema to your fingertips. Browse trending movies and TV shows, explore detailed cast & crew information, watch trailers, and discover hidden gems — all powered by The Movie Database (TMDB) API.

Built with clean architecture principles and a modern, cinematic UI, CineMovie delivers a seamless experience across Android and iOS platforms.

---

## 🚀 Features

### 🎥 Movie & TV Discovery
- **Trending Now** — Real-time trending movies and TV shows updated daily
- **Now Playing / On Air** — Latest theatrical releases and currently airing shows
- **Top Rated** — Critically acclaimed titles ranked by audience ratings
- **Upcoming** — Preview future releases with trailers and details

### 🔍 Smart Search
- Instant search across millions of movies, TV shows, and people
- Filtered results with genre, year, and rating support
- Search history and personalized suggestions

### 📋 Rich Detail Pages
- Full movie/show metadata: synopsis, rating, runtime, genres, release date
- **Cast & Crew** — Tap to explore any actor or director's full filmography
- **Video Trailers** — Watch official trailers directly in-app via YouTube
- **Similar Titles** — Discover related content based on your current selection
- **Production Details** — Studios, budgets, revenue, and original language

### 👤 People Profiles
- Detailed biography and personal info for cast & crew
- Complete filmography with role highlights
- Profile photos and social media links

### 🎨 UI/UX Highlights
- Sleek dark theme with cinematic aesthetics
- Smooth hero animations and page transitions
- Responsive grid and list layouts
- Shimmer loading effects for polished feel
- Cached network images for blazing fast performance

---

## 📱 Screenshots

<div align="center">

| Home Screen | Trending | Movie Detail |
|:-----------:|:--------:|:------------:|
| <img src="https://github.com/user-attachments/assets/eca60878-5c37-4a94-a00c-cf50a1739eb0" width="200"/> | <img src="https://github.com/user-attachments/assets/d902c160-3104-4fdb-b8ce-c80ccac06947" width="200"/> | <img src="https://github.com/user-attachments/assets/9ead77d9-1760-4e42-b293-7cedfca879ed" width="200"/> |

| Cast & Crew | Actor Profile | Search |
|:-----------:|:-------------:|:------:|
| <img src="https://github.com/user-attachments/assets/66f51808-bdb3-462e-aa9b-e527cc87d37f" width="200"/> | <img src="https://github.com/user-attachments/assets/fd834675-f538-46ae-b968-2ed324ddc061" width="200"/> | <img src="https://github.com/user-attachments/assets/4e867957-dfb5-432e-8234-bc0eea1d139b" width="200"/> |

</div>

---

## 🎬 Demo

<div align="center">

https://github.com/user-attachments/assets/f68a110d-2d4a-4647-8245-288bf735abf2

</div>

---

## 🛠 Installation

### Prerequisites

| Tool | Version |
|------|---------|
| Flutter SDK | ≥ 3.0.0 |
| Dart SDK | ≥ 3.0.0 |
| Android Studio / Xcode | Latest stable |
| TMDB API Key | [Get one free →](https://www.themoviedb.org/settings/api) |

### Step-by-step Setup

**1. Clone the repository**
```bash
git clone https://github.com/your-username/cinemovie_app.git
cd cinemovie_app
```

**2. Install dependencies**
```bash
flutter pub get
```

**3. Configure your API key**

Create a `.env` file in the project root (or update `lib/core/constants/api_constants.dart`):
```env
TMDB_API_KEY=your_tmdb_api_key_here
TMDB_BASE_URL=https://api.themoviedb.org/3
TMDB_IMAGE_BASE_URL=https://image.tmdb.org/t/p
```

**4. Run the app**
```bash
# Debug mode
flutter run

# Release mode
flutter run --release

# Specific device
flutter run -d <device_id>
```

**5. Build APK / IPA**
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

---

## 🏗 Architecture

CineMovie follows **Clean Architecture** with clear separation of concerns:

```
lib/
├── core/
│   ├── constants/          # API endpoints, theme colors, asset paths
│   ├── errors/             # Failure classes and exception handling
│   ├── network/            # Dio HTTP client, interceptors, connectivity
│   └── utils/              # Helpers, formatters, extensions
│
├── data/
│   ├── datasources/        # Remote (TMDB API) & local (cache) sources
│   ├── models/             # JSON serializable data models
│   └── repositories/       # Repository implementations
│
├── domain/
│   ├── entities/           # Core business objects
│   ├── repositories/       # Abstract repository contracts
│   └── usecases/           # Business logic (GetTrending, SearchMovies, etc.)
│
├── presentation/
│   ├── blocs/              # BLoC state management
│   ├── pages/              # Full screen pages
│   ├── widgets/            # Reusable UI components
│   └── themes/             # App theming
│
└── injection_container.dart  # Dependency injection setup
```

### State Management

CineMovie uses **BLoC (Business Logic Component)** pattern for predictable state management:

```
UI Event → BLoC → UseCase → Repository → Data Source
                  ↓
             BLoC State → UI Rebuild
```

---

## 🌐 API Integration

Powered by **[The Movie Database (TMDB) API v3](https://developers.themoviedb.org/3)**

| Endpoint Category | Endpoints Used |
|-------------------|---------------|
| Movies | `/movie/trending`, `/movie/popular`, `/movie/top_rated`, `/movie/upcoming`, `/movie/{id}` |
| TV Shows | `/tv/trending`, `/tv/popular`, `/tv/top_rated`, `/tv/on_the_air`, `/tv/{id}` |
| People | `/person/{id}`, `/person/{id}/movie_credits` |
| Search | `/search/multi`, `/search/movie`, `/search/tv`, `/search/person` |
| Media | `/movie/{id}/videos`, `/movie/{id}/credits`, `/movie/{id}/similar` |

---

## 📦 Dependencies

```yaml
dependencies:
  # State Management
  flutter_bloc: ^8.x
  equatable: ^2.x

  # Networking
  dio: ^5.x
  retrofit: ^4.x

  # Dependency Injection
  get_it: ^7.x
  injectable: ^2.x

  # UI & Media
  cached_network_image: ^3.x
  shimmer: ^3.x
  youtube_player_flutter: ^8.x
  carousel_slider: ^4.x
  smooth_page_indicator: ^1.x

  # Local Storage
  hive_flutter: ^1.x
  shared_preferences: ^2.x

  # Utilities
  dartz: ^0.10.x
  intl: ^0.18.x
  url_launcher: ^6.x
  logger: ^2.x
```

---

## 🗺 Roadmap

- [x] Movie & TV browsing with categories
- [x] Detailed movie/show pages
- [x] Cast & crew profiles
- [x] Video trailer playback
- [x] Search functionality
- [ ] User authentication (Firebase)
- [ ] Watchlist & favorites
- [ ] Ratings & personal reviews
- [ ] Push notifications for new releases
- [ ] Offline mode with local caching
- [ ] Tablet / iPad optimized layout
- [ ] Dark / Light theme toggle
- [ ] Multiple language support (i18n)

---

## 🤝 Contributing

Contributions are warmly welcome! Here's how to get started:

1. **Fork** this repository
2. **Create** your feature branch: `git checkout -b feature/amazing-feature`
3. **Commit** your changes: `git commit -m 'feat: add amazing feature'`
4. **Push** to the branch: `git push origin feature/amazing-feature`
5. **Open** a Pull Request

Please follow our [Code of Conduct](CODE_OF_CONDUCT.md) and check the [Contributing Guidelines](CONTRIBUTING.md) for more details.

### Bug Reports & Feature Requests

Found a bug or have a feature idea? [Open an issue](../../issues/new/choose) with the appropriate template.

---

## 📄 License

```
MIT License

Copyright (c) 2026 CineMovie

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction...
```

See the full [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgements

- [The Movie Database (TMDB)](https://www.themoviedb.org/) for the incredible free API
- [Flutter](https://flutter.dev/) for the amazing cross-platform framework
- [flutter_bloc](https://bloclibrary.dev/) for state management excellence
- All open-source contributors whose packages made this possible

---

<div align="center">

Made with ❤️ and Flutter

⭐ **Star this repo if you find it useful!** ⭐

</div>
