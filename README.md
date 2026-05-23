# Chatra Mobile App

Flutter-приложение для образовательной платформы [Chatra](https://github.com/whynicky19).

## Стек

- **Flutter** >= 3.19 / **Dart** >= 3.0
- **Provider** — управление состоянием
- **HTTP** — взаимодействие с REST API
- Бэкенд: FastAPI + PostgreSQL ([chatra-backend](https://github.com/whynicky19))

## Функционал

| Модуль | Описание |
|--------|----------|
| 🔐 Авторизация | Вход / регистрация, выбор группы |
| 📚 Классы | Каталог курсов, вступление по коду, создание (учитель) |
| 📖 Контент | Лекции, материалы, задания с дедлайнами и рейтингом |
| 💬 Чаты | Личные и групповые сообщения, поиск пользователей |
| 🤖 AI | Чат-ассистент (общий и внутри класса) |
| ⚙️ Настройки | Редактирование профиля |
| 🎨 Темы | Светлая и тёмная тема |

## Быстрый старт

### 1. Клонировать и установить зависимости

```bash
git clone https://github.com/whynicky19/chatra-app.git
cd chatra-app
flutter pub get
```

### 2. Указать URL бэкенда

В `lib/main.dart`:

```dart
final apiService = ApiService(baseUrl: 'http://YOUR_SERVER_IP:8000');
```

| Среда | URL |
|-------|-----|
| Android эмулятор | `http://10.0.2.2:8000` |
| iOS симулятор | `http://localhost:8000` |
| Реальное устройство (Wi-Fi) | `http://192.168.X.X:8000` |
| Продакшн | `https://your-domain.com` |

### 3. (Android) Разрешить HTTP

В `android/app/src/main/AndroidManifest.xml`:

```xml
<application android:usesCleartextTraffic="true" ...>
```

### 4. Запустить

```bash
flutter run
```

## Сборка

```bash
# Android APK
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk

# iOS (только macOS)
flutter build ios --release
```

## Структура проекта

```
lib/
├── main.dart
├── theme/
│   └── app_theme.dart        # Цвета и тема
├── services/
│   └── api_service.dart      # HTTP-клиент
├── providers/
│   └── auth_provider.dart    # Состояние авторизации
└── screens/
    ├── main_shell.dart        # Bottom navigation
    ├── auth/                  # Вход / регистрация
    ├── home/                  # Каталог классов
    ├── classes/               # Детали класса + AI чат
    ├── chats/                 # Чаты
    ├── ai/                    # AI ассистент
    └── settings/              # Настройки
```

