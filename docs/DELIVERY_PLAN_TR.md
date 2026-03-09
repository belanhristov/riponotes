# Ripo Notes - Delivery Plan (Canlı Plan)

Bu dosya aktif yürütme sırasıdır. Her yeni özellik önerisi önce `FEATURE_INBOX_TR.md` içine alınır, sonra bu planda önceliklendirilir.

## Çalışma Kuralı

- Kural 1: Önce çekirdek akışlar (Note create/edit, Inbox, local persistence).
- Kural 2: Apple-first UX girişleri (Widget, App Intent) erken gelir.
- Kural 3: Sync ve platformlar arası uyumluluk domain seviyesinde korunur.
- Kural 4: Faz dışı özellikler feature flag arkasında başlatılır.

## Sıralı Yol Haritası

1. Foundation ve Core Domain (Devam ediyor)
- Swift package modülleri
- Platform bağımsız model/protokoller
- Use-case çekirdeği (quick note, convert)

2. iOS/macOS App Shell
- SwiftUI app target
- iPhone tab + macOS sidebar navigation
- Auth gate placeholder

3. Note Editor v1
- Inbox listesi
- Note create/edit ekranı
- 2 dokunuşta not ekleme akışı

4. Local Persistence v1
- InMemory -> SwiftData repository geçişi
- Soft delete
- Basit arama (title/body/tag)

5. Quick Capture
- Widget quick note
- App Intent create note

6. Reminder/Calendar v1
- Reminder/Alarm schedule
- EventKit date binding

7. Meeting Flow v1
- Meeting template
- Katılımcı alanı
- Mail share composer

8. Sync Adapter v1
- Queue -> backend adapter iskeleti
- Retry/failed state yönetimi

## Karar Kriteri (Yeni özellik geldiğinde)

- Kullanıcı etkisi (yüksek/orta/düşük)
- Teknik bağımlılık (engelleyici var mı)
- Apple-first öncelik uyumu
- Android’e taşınabilirlik etkisi
- Geliştirme maliyeti (S/M/L)

