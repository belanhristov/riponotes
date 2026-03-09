# Ripo Notes - Mac Test Planı

## Kısa cevap
Evet, başlangıçta Mac üzerinden çok verimli test edebilirsin. Hızlı iterasyon için önce macOS + simulator; son aşamada iPhone/iPad gerçek cihaz doğrulaması.

## Önerilen sıra

1. Çekirdek testler (her commit)
- Komut: `swift test`
- Amaç: domain/use-case/data doğrulama

2. macOS UI smoke test
- Xcode'da macOS target ile çalıştır
- Akış: Inbox -> Note Editor -> Template Studio -> Journal Workspace

3. iPhone Simulator testi
- App Intents, navigation, editor toolbar davranışı

4. Gerçek iPhone testi
- Bildirim, LocalAuthentication (Face ID/Touch ID), keychain davranışı

5. iPad testi
- Split view ve çoklu pencere akışları

## Ne zaman gerçek cihaz şart?
- Biometric auth
- Push/local notification edge-case'leri
- Widget performansı ve lockscreen davranışı
- Camera/photo picker gibi donanım bağımlıları

## Şu an repoda hazır olan komut
- `swift test`
