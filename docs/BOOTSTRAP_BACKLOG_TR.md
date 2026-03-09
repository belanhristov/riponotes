# Ripo Notes - Bootstrap Backlog (İlk Uygulama Başlatma)

Durum etiketleri: `todo`, `in_progress`, `done`

## Epic 1: App Foundation

### Task 1.1 - Proje iskeleti
- Durum: `in_progress`
- Hedef: iOS + macOS ortak SwiftUI app shell.
- Kabul kriteri:
  - App açılışta Auth Gate ve Main Shell arasında geçiş yapar.
  - iPhone TabView, macOS/iPad Sidebar tabanlı yapı çalışır.

### Task 1.2 - Feature flag altyapısı
- Durum: `done`
- Hedef: tüm faz dışı özellikleri config ile kapatmak.
- Kabul kriteri:
  - En az 6 flag runtime okunur.
  - Flag kapalıyken ilgili UI entry noktası görünmez.

## Epic 2: Notes Core

### Task 2.1 - Domain model + local persistence
- Durum: `done`
- Hedef: User, Note, NoteBlock, Tag, Reminder modelleri persist edilir.
- Kabul kriteri:
  - Note CRUD çalışır.
  - Soft delete ile not geri çağrılabilir.

### Task 2.2 - Inbox + Note editor
- Durum: `in_progress`
- Hedef: Brain Dump hızında not üretimi.
- Kabul kriteri:
  - Uygulama açıldıktan sonra 2 dokunuşta not kaydı.
  - Default hedef Inbox.

### Task 2.3 - Search v1
- Durum: `in_progress`
- Hedef: title/body/tag tabanlı global arama.
- Kabul kriteri:
  - 1k notta kabul edilebilir hızda filtreleme.

## Epic 3: Quick Capture

### Task 3.1 - Widget quick add
- Durum: `in_progress`
- Hedef: WidgetKit üzerinden hızlı not.
- Kabul kriteri:
  - Widget aksiyonu local not oluşturur.
  - Oluşan not Inbox'ta görünür.

### Task 3.2 - App Intents create note
- Durum: `in_progress`
- Hedef: Siri/App Shortcuts ile not oluşturma.
- Kabul kriteri:
  - `CreateNoteIntent` text alır ve not yaratır.

## Epic 4: Reminder & Calendar

### Task 4.1 - Reminder service v1
- Durum: `in_progress`
- Hedef: reminder/alarm tipi local schedule.
- Kabul kriteri:
  - Tek seferlik + tekrar eden kural desteklenir.
  - Not detayından düzenleme/iptal yapılır.

### Task 4.2 - EventKit bağlama v1
- Durum: `todo`
- Hedef: nota tarih alanı ve takvim ilişkisi.
- Kabul kriteri:
  - Not içi tarih seçilip EventKit entry üretilebilir.

## Epic 5: Meeting Flow

### Task 5.1 - Meeting template + participants
- Durum: `in_progress`
- Hedef: toplantı notu hızlı başlatma.
- Kabul kriteri:
  - Template ile prefilled alanlar gelir.
  - Katılımcı picker ile kişi eklenir.

### Task 5.2 - Mail share
- Durum: `todo`
- Hedef: toplantı özetini mail olarak paylaşma.
- Kabul kriteri:
  - Apple Mail compose ekranı açılır.
  - Özet + aksiyon maddeleri body'ye düşer.

## Epic 6: Sync Abstraction

### Task 6.1 - Sync protocol + queue
- Durum: `in_progress`
- Hedef: backend bağımsız sync altyapısı.
- Kabul kriteri:
  - Create/update/delete değişiklikleri queue'ya yazılır.
  - Retry + failed durumları izlenir.
