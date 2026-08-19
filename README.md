# ParkMap — два Flutter-приложения (Клиент + Админ)

Готовые проекты:
- `parkmap_client/` — приложение клиента
- `parkmap_admin/` — приложение администратора

Оба приложения подключаются к **одному и тому же проекту Firebase** и
используют **вход только через Google (Firebase Auth + Google Sign-In)**,
любая почта подходит. Общие данные хранятся в Cloud Firestore, поэтому оба
приложения видят одну и ту же базу в реальном времени.

## Что умеет клиент
- Вход/регистрация только через Google.
- Карта парковок (flutter_map + OpenStreetMap), список, поиск по названию/адресу.
- Экран парковки: адрес, карта, всего/свободно мест, цена.
- Бронирование: дата → время начала → продолжительность → расчёт стоимости →
  выбор свободного места (занятые места недоступны) → подтверждение.
- Оплата бронирования списывается с внутреннего баланса (кошелька) клиента.
- Кнопка **«Пополнить на 10 000 ₸»** прямо на главном экране.
- «Мои бронирования»: просмотр и отмена активных бронирований.
- Возможность оставить **отзыв** (со звёздами) или **жалобу** по бронированию,
  и посмотреть статус своей жалобы (на рассмотрении / принята и деньги
  возвращены / отклонена).

## Что умеет админ
- Вход только через Google, но пускает только пользователей с ролью `admin`
  в Firestore (роль назначается вручную в базе — см. ниже).
- CRUD парковок: добавление, редактирование, удаление, координаты, цена,
  количество мест.
- Экран мест: сколько свободно / занято прямо сейчас и **сколько времени
  осталось** до освобождения каждого занятого места (обновляется каждую минуту).
- Вкладка «Отзывы»: список хороших отзывов с оценками.
- Вкладка «Жалобы»: принять (деньги автоматически возвращаются клиенту на
  баланс за конкретное бронирование) или отклонить (деньги не возвращаются).
- Штрафы: выбрать клиента (через одно из его бронирований), указать сумму и
  причину — сумма списывается с баланса клиента, штраф сохраняется в истории.

## Архитектура (в обоих проектах)
```
lib/
├── main.dart
├── firebase_options.dart     # заглушка, см. настройку Firebase ниже
├── models/                   # User, ParkingLot, Booking, Review, Fine
├── services/                 # AuthService, FirestoreService — вся работа
│                              # с Firebase/Firestore идёт только тут,
│                              # UI никогда не обращается к базе напрямую
├── pages/                    # экраны
└── widgets/                  # переиспользуемые виджеты
```

## Модель данных в Firestore
- `users/{uid}` — { name, email, photoUrl, role: 'user'|'admin', balance, isBanned }
- `parkingLots/{id}` — { name, address, latitude, longitude, totalSpots, pricePerHour }
- `bookings/{id}` — { parkingId, parkingName, userId, userName, date, startTime,
  endTime, spotNumber, totalPrice, status: active|cancelled|refunded }
- `reviews/{id}` — { userId, userName, bookingId, parkingId, type: review|complaint,
  rating, comment, status: pending|accepted|rejected, refunded, createdAt }
- `fines/{id}` — { userId, userName, amount, reason, createdAt }

## Настройка Firebase (один проект на оба приложения)
1. Создайте проект в [Firebase Console](https://console.firebase.google.com/).
2. Authentication → Sign-in method → включите **Google**.
3. Cloud Firestore → создайте базу (production mode), затем задеплойте правила
   из файла `firestore.rules` (Firestore → Rules, либо `firebase deploy --only firestore:rules`).
4. Установите инструменты и сгенерируйте конфиги для каждого приложения:
   ```bash
   dart pub global activate flutterfire_cli
   firebase login

   cd parkmap_client
   flutterfire configure   # выберите тот же Firebase-проект

   cd ../parkmap_admin
   flutterfire configure   # выберите тот же Firebase-проект
   ```
   Команда сама заменит заглушки в `lib/firebase_options.dart` и добавит
   `google-services.json` / `GoogleService-Info.plist`.
5. Для Android дополнительно нужен SHA-1/SHA-256 отпечаток debug-ключа,
   добавленный в настройки проекта Firebase (иначе Google Sign-In не
   заработает на Android):
   ```bash
   keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore
   ```
6. Создайте первого администратора: зарегистрируйтесь через Google в
   приложении **клиента** (это создаст документ в `users/{uid}` с
   `role: "user"`), затем в Firestore Console вручную поменяйте его
   `role` на `"admin"`. После этого этот же Google-аккаунт сможет войти в
   приложение **админа**.
7. Добавьте хотя бы одну парковку через админ-приложение — она сразу
   появится на карте и в списке у клиента.

## Запуск
```bash
cd parkmap_client && flutter pub get && flutter run
cd parkmap_admin  && flutter pub get && flutter run
```

## Важно
- Вход везде — **только Google Sign-In через Firebase**, отдельного экрана
  регистрации с email/паролем нет, как и запрашивалось.
- Оплата — учебная, «понарошку»: списание/пополнение идёт с внутреннего
  баланса пользователя в Firestore, без подключения настоящих платёжных
  систем.
