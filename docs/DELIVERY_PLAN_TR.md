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

9. Journal ve Context Layer (Faz 2)
- Şifreli günlük modu (biometric/passcode)
- Gelişmiş lokasyon bağlama
- Hava durumu bağlama (konum izinli)

10. Calendar Integrations (Faz 2-3)
- Apple Calendar çift yönlü bağ (EventKit)
- Outlook Calendar bağlama (feature flag + Graph API)

11. AI Suggestion Layer (Faz 3)
- AI günlük modları üretimi
- Hava + lokasyona göre öneri motoru
- Güvenlik/izin kuralları ve kullanıcı opt-in

12. Template Studio + Rich Editor (Faz 2-3)
- Not ve Journal için ayrı şablon yönetimi
- Mevcut şablondan şablon türetme
- Şablon/Not/Journal için resim ekleme
- Üstte çok fonksiyonlu düzenleme barı (girinti, boyut, çizgi, biçim)

13. Context-Aware AI Templates (Faz 3)
- AI önerilen moddan tek adım yazma akışı
- Hava + konum + kullanıcı moduna göre otomatik şablon üretimi

14. Travel Pro Module (Faz 3)
- Trip workspace (uçuş, otel, tarih, rota)
- Seyahat checklist + valiz checklist
- Hedef lokasyona göre hava özeti
- Para birimi bazlı harcama öngörüsü (FX entegrasyonu)

15. Auth Strategy (Faz 1-2)
- İlk sürüm: Apple Sign-In + Google Sign-In
- Auth gate + session restore + sign-out
- Email/password ve “şifremi unuttum” sadece plan (kapalı flag)

16. Travel Pro Benchmark Wave (Faz 3)
- Reservation import (TripIt-style)
- Transport comparator (Rome2Rio-style)
- Price watch/drop alerts (Hopper-style)
- Smart packing engine (PackPoint-style)
- Offline trip card + estimate vs actual spend

## Karar Kriteri (Yeni özellik geldiğinde)

- Kullanıcı etkisi (yüksek/orta/düşük)
- Teknik bağımlılık (engelleyici var mı)
- Apple-first öncelik uyumu
- Android’e taşınabilirlik etkisi
- Geliştirme maliyeti (S/M/L)
