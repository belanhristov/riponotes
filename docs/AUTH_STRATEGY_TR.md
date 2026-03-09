# Ripo.life - Auth Strategy

## Karar
İlk sürümde sadece:
- Sign in with Apple
- Google Sign-In

Email/password ve "şifremi unuttum" akışı ilk sürümde **yok**.

## Neden bu karar?
- Apple-first ürün için friction düşük giriş
- Daha hızlı ve güvenli MVP çıkışı
- Password reset, mail deliverability, abuse/rate-limit gibi operasyon yükünü ilk fazda azaltır

## Uygulama davranışı (V1)
- Açılışta Auth Gate göster
- Kullanıcı bir kez giriş yaptıktan sonra session restore
- Settings içinde sign-out
- Hesap silme/gizlilik metinleri hazır olmalı

## V2+ Plan (şimdilik kapalı)
- Email/password register-login
- "Şifremi unuttum" (email reset link)
- Bu akışlar feature flag arkasında açılacak

## Teknik not
- Domain katmanı provider bağımsız kalmalı
- `AuthProvider` zaten `apple|google` destekli
- Gelecekte email eklenirse model genişletilir, mevcut kullanıcılar etkilenmez
