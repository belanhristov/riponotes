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
| F-007 | Şifreli günlük (journal) modu | triaged | yüksek | M | Faz 2 | Journal alanı ayrı klasör + app lock (biometric/passcode) + local encryption anahtarı. |
| F-008 | AI ile otomatik günlük modları üretimi | triaged | orta | L | Faz 3 | Kullanıcı tonuna göre günlük prompt/mod önerileri; AI provider feature flag arkasında. |
| F-009 | Hava durumu bağlama | triaged | orta | M | Faz 2 | Konuma bağlı anlık hava verisi çekimi ve note/journal bağlamında gösterim. |
| F-010 | Gelişmiş lokasyon bağlama | triaged | yüksek | M | Faz 2 | Not bazlı lokasyon ekleme var; çoklu lokasyon ve yer bazlı görünüm genişletilecek. |
| F-011 | Hava durumuna göre mod/öneri | triaged | yüksek | L | Faz 3 | Örnek: hava güneşliyse ve sahile yakınsa 5 dk yürüyüş önerisi; öneri motoru + izin yönetimi gerekir. |
