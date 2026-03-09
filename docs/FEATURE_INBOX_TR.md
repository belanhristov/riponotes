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

