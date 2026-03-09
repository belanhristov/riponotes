# FX Provider Seçenekleri (Maliyet Odaklı) - 9 Mart 2026

## Karar (öneri)
- İlk üretim seçeneği: **Frankfurter API** (ücretsiz/anahtarsız)
- Geliştirme ve test: `InMemoryCurrencyRateProvider`
- Fallback planı: gerekirse ücretli providera geçiş (Open Exchange Rates vb)

## Neden Frankfurter?
- Basit endpoint yapısı
- API key gerektirmeden temel kur dönüşümü
- Travel senaryosu için tek çift (base -> target) ihtiyacını karşılar

## Google olur mu?
- Uygulama backend'i için resmi, genel amaçlı bir Google FX REST API’si net/standart bir ürün olarak görünmüyor.
- Bu yüzden Google’a bağımlı olmayan açık provider yaklaşımı daha güvenli.

## Kullanım kapsamı
- Biz tüm kurları çekmeyeceğiz.
- Sadece aktif trip için `baseCurrency -> targetCurrency` kuru alınacak.

## Kaynaklar
- Frankfurter API: https://frankfurter.dev/
- ECB rates referansı: https://www.ecb.europa.eu/stats/eurofxref/
- Open Exchange Rates pricing: https://openexchangerates.org/pricing
- exchangerate.host pricing: https://exchangerate.host/pricing
