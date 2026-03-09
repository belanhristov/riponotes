# Ripo Notes - Feature Inbox

Bu dosya senin aklına gelen tüm yeni özelliklerin giriş noktası.
Ben her maddeyi buraya alıp `triage` alanını dolduracağım ve uygun sprint/faz kuyruğuna taşıyacağım.

## Nasıl yazalım?

Aşağıdaki formatla tek satır veya kısa blok halinde yazman yeterli:
- Özellik adı
- Kısa açıklama
- Beklenen kullanıcı faydası
- Varsa platform notu (iOS/macOS/Android)

## Durum Kodları

- `new`: yeni eklendi
- `triaged`: analiz edildi, faz/sprint atandı
- `scheduled`: aktif plana alındı
- `done`: tamamlandı
- `parked`: sonraya bırakıldı

## Inbox Items

| ID | Özellik | Durum | Etki | Maliyet | Faz | Not |
|---|---|---|---|---|---|---|
| F-001 | Brain Dump mode | triaged | yüksek | S | Faz 1 | Quick note girişiyle birlikte temel destek var, UI polish bekliyor. |
| F-002 | Convert button (note -> list/reminder/contact/location) | triaged | yüksek | M | Faz 1-2 | Reminder kısmı çekirdekte başladı, UI ve diğer dönüşümler eksik. |
| F-003 | Follow-up mode | new | orta | M | Faz 2 | Kişi ataması + notification kuralı ile bağlanacak. |
| F-004 | Where I need this (location-triggered notes) | new | yüksek | M | Faz 2 | LocationLink ve geofence reminder ile kurulacak. |
| F-005 | Mail to Note capture | new | yüksek | L | Faz 3 | Apple Mail/Outlook entegrasyonlarının temel değeri. |
| F-006 | Apple Calendar + Outlook Calendar bağlama | triaged | yüksek | M | Faz 2-3 | Faz 2: Apple EventKit ile iki yönlü bağ. Faz 3: Outlook Calendar (Graph API) feature flag ile. |
| F-007 | Şifreli günlük (journal) modu | in_progress | yüksek | M | Faz 2 | Journal workspace + app lock/passcode + encryption service + Keychain/LocalAuthentication adaptörleri eklendi; production wiring ve UI polish sırada. |
| F-008 | AI ile otomatik günlük modları üretimi | triaged | orta | L | Faz 3 | Kullanıcı tonuna göre günlük prompt/mod önerileri; AI provider feature flag arkasında. |
| F-009 | Hava durumu bağlama | in_progress | orta | M | Faz 2 | Weather snapshot modeli + provider protokolü + in-memory provider eklendi; gerçek weather API adaptörü ve UI gösterimi sırada. |
| F-010 | Gelişmiş lokasyon bağlama | triaged | yüksek | M | Faz 2 | Not bazlı lokasyon ekleme var; çoklu lokasyon ve yer bazlı görünüm genişletilecek. |
| F-011 | Hava durumuna göre mod/öneri | in_progress | yüksek | L | Faz 3 | ContextSuggestionService çekirdeği eklendi (güneşli+sahile yakın senaryosu dahil); kişiselleştirme ve AI katmanı sırada. |
| F-012 | Not ve Journal için ayrı Template Studio | in_progress | yüksek | M | Faz 2 | Domain + template engine + AppKit TemplateStudio view/viewmodel + canlı önizleme + şablon düzenleme kaydetme eklendi; gelişmiş medya/AI öneri entegrasyonu sırada. |
| F-013 | Zengin düzenleme barı (editor toolbar) | in_progress | yüksek | L | Faz 2-3 | Komut çekirdeği + AppKit toolbar view/viewmodel eklendi; gelişmiş stil seçenekleri ve full editor entegrasyonu sırada. |
| F-014 | Şablon/Not/Journal içine resim ekleme | in_progress | yüksek | M | Faz 2 | Attachment modeli + servis + testler + Template Studio ve Note Editor’da görsel ekle/çıkar UI akışı eklendi; journal editor ve medya preview polish sırada. |
| F-015 | AI önerilen moddan tek adım yazmaya başlama | triaged | orta | M | Faz 3 | AI mod önerisi seçildiğinde doğrudan editöre düşen hazır başlangıç metni/şablon. |
| F-016 | Bağlama göre otomatik şablon üretimi | triaged | yüksek | L | Faz 3 | Hava + konum + mod sinyaline göre (örn. sahile yakın/güneşli) otomatik template önerimi/oluşturma. |
| F-017 | Travel Planner (Trip workspace) | in_progress | yüksek | L | Faz 3 | Trip domain + service + AppKit TravelWorkspace view/viewmodel + test eklendi; gerçek app target wiring ve data persistence polish sırada. |
| F-018 | Uçak + otel itinerary girişi | in_progress | yüksek | M | Faz 3 | Flight/hotel segment service + AppKit UI girişi eklendi; rezervasyon importu ve provider entegrasyonu sırada. |
| F-019 | Seyahat tarihine göre hava kontrolü | triaged | yüksek | M | Faz 3 | Trip tarihine göre hedef lokasyon hava özeti ve uyarılar. |
| F-020 | Seyahat öncesi checklist | in_progress | yüksek | S | Faz 3 | Checklist item modeli + toggle + Travel workspace UI akışı eklendi; reminder bağlama sırada. |
| F-021 | Valiz hazırlama + kritik hatırlatmalar | in_progress | yüksek | M | Faz 3 | Packing item modeli + toggle + Travel workspace UI akışı eklendi; kritik reminder otomasyonu sırada. |
| F-022 | Para birimine göre harcama öngörüsü | in_progress | yüksek | L | Faz 3 | Currency rate provider + budget estimate çekirdeği eklendi; gerçek FX API adaptörü ve tahmin UI'si sırada. |
| F-023 | Packr-benzeri akıllı valiz şablonları | triaged | yüksek | M | Faz 3 | Destinasyon/süre/hava durumuna göre otomatik packing önerileri + kategorik valiz şablonları. |
| F-024 | Elk-benzeri sade hedef ülke kur görünümü | in_progress | yüksek | M | Faz 3 | Frankfurter provider + tek kur kartı + live/cached gösterimi + last-known-rate fallback eklendi; UX polish sırada. |
| F-025 | Kişisel harcama profili (öğün/içecek/ulaşım) | in_progress | yüksek | M | Faz 3 | Expense profile modeli + budget estimate from profile + Travel workspace UI formu eklendi; gerçek kur API bağlama ve UX polish sırada. |
| F-028 | Rezervasyon import (TripIt tarzı) | triaged | yüksek | L | Faz 3 | Email forward ile uçuş/otel import v1, sonra inbox sync entegrasyonu. |
| F-029 | Ulaşım karşılaştırma (Rome2Rio tarzı) | triaged | yüksek | L | Faz 3 | Uçak/tren/otobüs/ferry seçeneklerini süre/fiyat bazlı kıyaslama. |
| F-030 | Fiyat izleme ve düşüş alarmı (Hopper tarzı) | triaged | yüksek | L | Faz 3 | Flight/hotel için watchlist ve fiyat düşüş bildirimleri. |
| F-031 | Akıllı packing öneri motoru (PackPoint+) | in_progress | yüksek | M | Faz 3 | SmartPackingService (hava+aktivite+gün+laundry+traveler) + Travel workspace Smart Packing aksiyonu + test eklendi. |
| F-032 | Şehir bazlı hazır itinerary şablonları (Visit A City+) | triaged | orta | M | Faz 3 | Popüler destinasyonlar için optimize günlük plan başlangıçları. |
| F-033 | Harcama takip (estimate vs actual) + split | triaged | yüksek | M | Faz 3 | Kişi/grup harcama takibi ve borç paylaşımı. |
| F-034 | Offline trip card | triaged | yüksek | M | Faz 3 | İnternet yokken kritik trip bilgilerine erişim. |
| F-026 | Apple + Google social login (ilk sürüm) | in_progress | yüksek | M | Faz 1-2 | İlk sürüm auth yöntemi Apple/Google ile sınırlandı; session yönetimi ve auth gate wiring sürüyor. |
| F-027 | Email/password + şifremi unuttum | parked | orta | M | Faz 3+ | Sadece plan olarak tutulacak; ilk sürümde kapalı (feature flag). |
