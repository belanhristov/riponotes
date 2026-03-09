# Ripo Notes - Travel Pro Modülü (Taslak)

## Amaç
Seyahat planını tek bir “Trip Workspace” içinde yönetmek:
- Uçuş + otel + tarih bilgileri
- Hava durumu kontrolü
- Seyahat öncesi checklist
- Valiz hazırlama checklist
- Para birimi bazlı harcama öngörüsü

## Önerilen Veri Modeli

- `Trip`
  - `id`, `ownerUserId`, `title`, `origin`, `destination`, `startDate`, `endDate`, `baseCurrency`, `targetCurrency`
- `TripSegment`
  - `id`, `tripId`, `type` (flight, hotel, transport, activity), `startAt`, `endAt`, `providerName`, `confirmationCode`, `notes`
- `TripChecklistItem`
  - `id`, `tripId`, `category` (documents, booking, health, finance, misc), `text`, `isDone`, `isCritical`, `dueAt`
- `PackingItem`
  - `id`, `tripId`, `category` (clothes, tech, medicine, documents, custom), `text`, `quantity`, `isDone`, `isCritical`
- `TripWeatherSnapshot`
  - `id`, `tripId`, `date`, `condition`, `minTemp`, `maxTemp`, `updatedAt`
- `TripBudgetEstimate`
  - `id`, `tripId`, `estimatedTotal`, `currency`, `dailyEstimate`, `fxRateUsed`, `confidence`

## Entegrasyon Gereksinimi (Para Birimi Öngörüsü için)

Temel ihtiyaçlar:
1. `FX Exchange Rate API`
- Güncel kur: `baseCurrency -> targetCurrency`
- Opsiyonel tarihsel kur (planlanan tarih için)

2. `Travel Cost Estimation Source`
- Ülke/şehir bazlı ortalama günlük gider katsayıları
- Başlangıçta statik katsayı tablosu ile başlanabilir, sonra API'ye geçilir

3. `Budget Estimator Service`
- Girdi: gün sayısı, kişi sayısı, konaklama tipi, günlük harcama profili
- Çıktı: tahmini toplam harcama + belirsizlik aralığı

## V1 Entegrasyon Stratejisi (Pragmatik)

- Faz 1: Manual flight/hotel giriş + checklist + valiz listesi + manuel bütçe
- Faz 2: Weather API + FX API bağla
- Faz 3: AI destekli “trip prep suggestions” + otomatik maliyet önerisi

## Önerilen Ek Özellikler (Travel Pro genişleme)

- Pasaport/vize son tarih uyarısı
- Uçuş check-in zamanı otomatik hatırlatma
- Offline trip card (internet yokken kritik bilgiler)
- Acil durum kartı (sigorta, konsolosluk, acil kişi)
- Harcama takibi (estimate vs actual)
- Trip sonrası “travel journal” otomatik şablonu

## Test Önerisi

- macOS: Trip oluşturma, checklist tikleme, budget hesaplama akışı
- iPhone: bildirim, widget quick checklist, trip lockscreen info
- iPad: plan + checklist yan yana çalışma
