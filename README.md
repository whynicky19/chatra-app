# Chatra Mobile App (Flutter)

Мобильное приложение для образовательной платформы Chatra, работающее с существующим бэкендом.

## Функционал

- 🔐 **Авторизация** — вход и регистрация (email/пароль, выбор группы)
- 📚 **Классы** — каталог курсов, присоединение по коду, создание (учитель)
- 📖 **Контент класса** — лекции, материалы, задания с дедлайнами
- 💬 **Чаты** — личные сообщения, поиск пользователей, групповые чаты
- 🤖 **AI Ассистент** — чат с ИИ (общий и внутри класса)
- ⚙️ **Настройки** — редактирование профиля, уведомления
- 🎨 **Темы** — поддержка светлой и тёмной темы

## Требования

- **Flutter SDK** >= 3.0.0 (рекомендуется 3.19+)
- **Dart SDK** >= 3.0.0
- **Android Studio** или **VS Code** с Flutter плагином
- **Xcode** (только для iOS)
- Работающий бэкенд Chatra

## Установка Flutter

### macOS / Linux:
```bash
# Скачайте Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable ~/flutter
export PATH="$HOME/flutter/bin:$PATH"

# Проверьте установку
flutter doctor
```

### Windows:
1. Скачайте Flutter SDK с https://flutter.dev/docs/get-started/install/windows
2. Распакуйте в `C:\flutter`
3. Добавьте `C:\flutter\bin` в переменную PATH

## Настройка проекта

### 1. Укажите URL бэкенда

Откройте `lib/main.dart` и измените URL:

```dart
final apiService = ApiService(baseUrl: 'http://YOUR_SERVER_IP:8000');
```

**Варианты:**
| Среда | URL |
|-------|-----|
| Android эмулятор | `http://10.0.2.2:8000` |
| iOS симулятор | `http://localhost:8000` |
| Реальное устройство (в одной WiFi сети) | `http://192.168.X.X:8000` |
| Удалённый сервер | `https://your-domain.com` |

> Чтобы узнать IP вашего компьютера:
> - macOS/Linux: `ifconfig | grep inet`
> - Windows: `ipconfig`

### 2. Установите зависимости

```bash
cd chatra_app
flutter pub get
```

### 3. (Android) Разрешите HTTP трафик

Если ваш бэкенд работает по HTTP (не HTTPS), добавьте в `android/app/src/main/AndroidManifest.xml`:

```xml
<application
    android:usesCleartextTraffic="true"
    ... >
```

### 4. (iOS) Разрешите HTTP трафик

Добавьте в `ios/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## Запуск

### На Android эмуляторе
```bash
# Запустите эмулятор
flutter emulators --launch <emulator_name>

# Запустите приложение
flutter run
```

### На iOS симуляторе (macOS)
```bash
open -a Simulator
flutter run
```

### На реальном устройстве
```bash
# Подключите устройство по USB
# Включите USB-отладку (Android) или режим разработчика (iOS)
flutter run
```

### Сборка APK (Android)
```bash
flutter build apk --release
# APK будет в build/app/outputs/flutter-apk/app-release.apk
```

### Сборка IPA (iOS, только macOS)
```bash
flutter build ios --release
```

## Структура проекта

```
lib/
├── main.dart                    # Точка входа
├── theme/
│   └── app_theme.dart           # Тема и цвета (как на сайте)
├── services/
│   └── api_service.dart         # HTTP клиент (все API эндпоинты)
├── providers/
│   └── auth_provider.dart       # Состояние авторизации
└── screens/
    ├── main_shell.dart           # Bottom navigation
    ├── auth/
    │   ├── login_screen.dart     # Вход
    │   └── register_screen.dart  # Регистрация
    ├── home/
    │   └── home_screen.dart      # Каталог классов
    ├── classes/
    │   └── class_detail_screen.dart  # Детали класса + AI чат
    ├── chats/
    │   └── chats_screen.dart     # Список чатов + переписка
    ├── ai/
    │   └── ai_screen.dart        # AI ассистент
    └── settings/
        └── settings_screen.dart  # Настройки профиля
```

## API эндпоинты (поддерживаемые)

| Модуль | Эндпоинт | Описание |
|--------|----------|----------|
| Auth | `POST /auth/login` | Вход (form-urlencoded) |
| Auth | `POST /auth/register` | Регистрация |
| Auth | `GET /auth/me` | Текущий пользователь |
| Auth | `PATCH /auth/me` | Обновить профиль |
| Auth | `GET /auth/groups/search` | Поиск групп |
| Posts | `GET /posts/` | Все посты (классы, лекции) |
| Posts | `POST /posts/create` | Создать пост |
| Posts | `PUT /posts/{id}` | Обновить пост |
| Posts | `DELETE /posts/{id}` | Удалить пост |
| Assignments | `GET /assignments/` | Список заданий |
| Assignments | `POST /assignments/` | Создать задание |
| Assignments | `POST /assignments/{id}/submit` | Отправить работу |
| Assignments | `GET /assignments/student/my-submissions` | Мои работы |
| Assignments | `GET /assignments/student/my-rating` | Мой рейтинг |
| Chats | `GET /chats/` | Список чатов |
| Chats | `POST /chats/` | Создать чат |
| Chats | `GET /chats/{id}/users` | Участники чата |
| Chats | `POST /chats/{id}/users/{uid}` | Добавить в чат |
| Messages | `GET /messages/chat/{id}` | Сообщения |
| Messages | `POST /messages/chat/{id}` | Отправить |
| AI | `POST /ai/chat` | Чат с ИИ |
| Upload | `POST /upload/` | Загрузить файл |
| Admin | `GET /admin/users` | Все пользователи |

## Решение проблем

### «Connection refused»
- Убедитесь, что бэкенд запущен
- Проверьте правильность URL в `lib/main.dart`
- Для эмулятора Android используйте `10.0.2.2` вместо `localhost`

### «Cleartext HTTP traffic not permitted»
- Добавьте `android:usesCleartextTraffic="true"` в AndroidManifest.xml

### «No devices found»
```bash
flutter devices  # Список доступных устройств
flutter doctor    # Диагностика
```

### Шрифты не загружаются
Приложение использует системные шрифты как fallback. Чтобы добавить Outfit:
1. Скачайте шрифт с Google Fonts
2. Поместите `.ttf` файлы в `assets/fonts/`
3. Они уже прописаны в `pubspec.yaml`
