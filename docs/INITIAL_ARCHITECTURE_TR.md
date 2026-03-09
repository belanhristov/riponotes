# Ripo Notes - İlk Mimari Taslak (v0.1)

Bu doküman, verilen ürün vizyonunu ilk kodlama aşamasına çevirmek için hazırlanmış teknik başlangıç paketidir.
Odak: **iPhone + macOS (iPad destekli)**, tek kullanıcı, offline-first, Apple-first deneyim.

## 1) Mimari Prensipler

- İstemci: SwiftUI tabanlı, platforma özel UX (iOS/macOS) ama ortak domain modeli.
- Katmanlar:
  - `Presentation` (SwiftUI + ViewModels)
  - `Domain` (use-case + entity + protocol)
  - `Data` (local store + sync adapters + system integrations)
- Veri modeli platform bağımsız tasarlanır; Apple framework bağımlılıkları Data katmanında izole edilir.
- `Feature Flags` ile faz dışı modüller kapalı gelir (örn. Outlook, takım/workspace).
- Offline-first: yazma ve okuma yerelden; sync asenkron kuyrukla arkada çalışır.

## 2) Önerilen Modül Ağacı

- `AppCore`
  - App lifecycle, dependency container, feature flags
- `Auth`
  - Sign in with Apple, Google (flag ile)
- `Notes`
  - Note create/edit, blocks, tags, templates
- `QuickCapture`
  - Brain Dump, Widget entry, App Intents entry
- `Reminders`
  - Reminder/Alarm/Push model + scheduling
- `People`
  - Contacts mapping, person-linked notes
- `Meetings`
  - Meeting template, participants, action items, share/email
- `CalendarLayer`
  - EventKit linking
- `LocationLayer`
  - MapKit links, geofenced reminders
- `Sync`
  - Sync abstraction, conflict policy, retry queue
- `Infrastructure`
  - Local DB, notifications, telemetry, attachments

## 3) Veri Modeli (İlk Taslak)

Not: Alan tipleri teknoloji bağımsız tutulmuştur.

### User
- `id`
- `authProvider` (apple, google)
- `displayName`
- `email`
- `locale`
- `createdAt`, `updatedAt`

### Note
- `id`
- `ownerUserId`
- `title`
- `plainTextBody`
- `folderId` (nullable)
- `isPinned`
- `status` (active, archived, deleted)
- `source` (manual, widget, siri, mail, shared)
- `createdAt`, `updatedAt`, `deletedAt`

### NoteBlock
- `id`
- `noteId`
- `type` (paragraph, checklist, heading, quote)
- `position`
- `payload` (json)

### Reminder
- `id`
- `noteId`
- `type` (reminder, alarm, push)
- `triggerAt`
- `repeatRule` (nullable)
- `priority` (silent, critical, follow_up)
- `isEnabled`
- `createdAt`, `updatedAt`

### List
- `id`
- `noteId` (nullable, nottan üretildiyse)
- `title`
- `templateType` (shopping, project, custom)
- `createdAt`, `updatedAt`

### ListItem
- `id`
- `listId`
- `text`
- `isDone`
- `order`
- `dueAt` (nullable)

### ContactLink
- `id`
- `noteId`
- `contactIdentifier` (OS contacts id)
- `displayNameSnapshot`
- `createdAt`

### LocationLink
- `id`
- `noteId`
- `latitude`
- `longitude`
- `radiusMeters`
- `label`
- `triggerType` (onEnter, onExit)

### Tag
- `id`
- `ownerUserId`
- `name`
- `color`

### Attachment
- `id`
- `noteId`
- `type` (image, audio, file, mail)
- `localPath`
- `remoteUrl` (nullable)
- `metadataJson`

### MailCapture
- `id`
- `noteId`
- `provider` (apple_mail, outlook)
- `messageId`
- `subject`
- `fromEmail`
- `capturedAt`

## 4) Ekran Ağacı

- `Launch`
  - Auth Gate
- `Main Tab / Sidebar`
  - Inbox
  - Today
  - Notes
  - Lists
  - People
  - Calendar
  - Search
  - Settings
- `Modal/Flows`
  - Quick Add (Brain Dump)
  - Note Detail (create/edit)
  - Convert Sheet (Note -> Reminder/List/Person/Location)
  - Meeting Note Flow
  - Share/Email Composer
  - Contact Picker
  - Date & Repeat Picker
  - Location Picker

## 5) Navigation Yapısı

- iPhone: `TabView + NavigationStack`
- iPad/macOS: `NavigationSplitView` (sidebar + content + detail)
- Deep links / Intent routes:
  - `ripo://quick-add`
  - `ripo://note/{noteId}`
  - `ripo://inbox`
  - `ripo://meeting/new`
- Widget ve App Intent doğrudan `Quick Add` veya belirli template create ekranını açar.

## 6) Note Create/Edit Akışı

1. Giriş kaynağı: app, widget, siri, mail.
2. Varsayılan hedef klasör: son kullanılan, yoksa `Inbox`.
3. Yazım sırasında canlı parse:
   - Tarih/saat algılama
   - `#tag` algılama
   - kişi adı eşleşme önerisi (opsiyonel)
4. Kaydetme:
   - Local store'a anında yaz
   - `syncState = pending`
5. Convert aksiyonu:
   - Reminder oluştur
   - List oluştur
   - Contact link ekle
   - Location link ekle
6. Background:
   - Notification schedule
   - Sync queue enqueue

## 7) Template Sistemi

Template türleri:
- `meeting`
- `shopping`
- `project`
- `daily`
- `idea`

Önerilen model:
- `TemplateDefinition`
  - `id`, `name`, `defaultTitle`, `defaultBlocks`, `suggestedActions`
- Çalışma şekli:
  - Kullanıcı template seçer -> prefilled Note + Block seti oluşturulur.
  - Template'ler JSON/PLIST benzeri tanımlardan yüklenebilir.

## 8) Reminder Servisi

Amaç: tek bir arayüz altında üç bildirim tipi.

- `Reminder`: standart takip bildirimi
- `Alarm`: daha dikkat çekici/sesli/öncelikli
- `Push`: uygulama olayları/paylaşım bildirimleri (faz 2+ backend ile)

Arayüz (domain):
- `schedule(noteId, type, trigger, repeat, priority)`
- `cancel(reminderId)`
- `snooze(reminderId, duration)`
- `reschedule(reminderId, newTrigger)`

İlk faz implementasyonu:
- Local notifications + repeat rule desteği
- Kritik alarm için ayrı kategori/action set

## 9) Contact Linking Mantığı

- Contacts framework üzerinden kişi seçimi.
- Not içine `ContactLink` olarak yalnızca `contactIdentifier` + snapshot saklanır.
- Arama katmanı:
  - Note text + tag + contact name snapshot üzerinden indeks.
- Kullanım örneği:
  - "Ahmet ile konuşulacaklar" filtrelemesi -> kişi ilişkili notlar.

## 10) Meeting Notes Share Akışı

1. `meeting` template ile not açılır.
2. Katılımcı seçimi (Contacts).
3. Aksiyon maddeleri checklist veya task block olarak işaretlenir.
4. Share:
   - mail body üret (özet + aksiyon maddeleri)
   - Apple Mail compose (ilk faz)
   - Outlook share path (feature flag, faz 3)

## 11) Widget / App Intents Uçları

Widget aksiyonları:
- `Quick Note`
- `Quick Shopping Item`
- `Open Inbox`

App Intents:
- `CreateNoteIntent(text, targetFolder?)`
- `CreateMeetingNoteIntent(title, participants?)`
- `AddToListIntent(listId, itemText)`

Beklenen davranış:
- Intent çağrısı UI açmadan local create yapabilmeli.
- Başarılı create sonrası uygun deep link döndürülebilir.

## 12) Local Storage + Sync Abstraction

Öneri:
- İlk faz: SwiftData (veya Core Data) + repository pattern
- Sync abstraction:
  - `SyncEngineProtocol`
  - `SyncJob` (create/update/delete)
  - `ConflictResolver` (last-write-wins + audit)

Temel durum alanları:
- `syncState` (synced, pending, failed)
- `version`
- `lastSyncedAt`

Backend seçimi (başlangıç değerlendirme):
- Supabase: hızlı MVP + Postgres avantajı
- Firebase: güçlü realtime + auth kolaylığı

Karar kriteri:
- offline merge karmaşıklığı
- auth provider uyumu
- maliyet/operasyon sadeliği

## 13) Feature Flags (Başlangıç Seti)

- `ff_google_sign_in = false`
- `ff_outlook_integration = false`
- `ff_team_workspaces = false`
- `ff_ai_summary = false`
- `ff_mail_capture_advanced = false`
- `ff_android_sync_compat = true` (model uyumluluğu için)

## 14) Faz Bazlı Teknik Kapsam

### Faz 1 (MVP)
- Apple sign-in
- Note CRUD + Inbox
- Folder/tag + global search
- Quick note widget
- Local notifications
- Checklist
- Calendar/Reminder date binding
- Siri/App Intents create note
- Meeting template + participant field + email share

### Faz 2
- Contact linking
- Shopping/project list templates
- Location notes
- macOS sticky notes
- Google sign-in
- Device sync
- iPad advanced multi-window

### Faz 3
- Mail capture
- Outlook integration
- AI summary / task extraction
- Shared/team notes
- Android client release

## 15) İlk Sprint İçin Önerilen İş Kırılımı

- Sprint 1
  - Domain entities + repositories
  - App shell + navigation skeleton
  - Inbox + Note create/edit screen
  - Feature flag infrastructure
- Sprint 2
  - Template engine v1
  - Reminder service v1 + local notifications
  - Widget quick add
  - App Intent create note
- Sprint 3
  - Meeting flow v1 + participant picker
  - Mail share composer
  - Search index (title/body/tag/contact snapshot)
  - Local->sync abstraction (stub backend)

## 16) Kararlar (Netleştirilmiş)

- İlk release: tek kullanıcı.
- Platform önceliği: iPhone + macOS, iPad destekli.
- Web yok; Android paralel geliştirme ama yayın sonraki faz.
- Freemium modelde kısıt: ekip/workspace + ileri entegrasyonlar + pro katman.

