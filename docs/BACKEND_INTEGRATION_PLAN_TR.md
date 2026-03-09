# Ripo Notes - Backend Integration Planı

## Amaç
Local-first çalışan uygulamayı, sync + paylaşım + push için backend'e bağlamak.

## Aşamalı plan

1. Sync API sözleşmesi (v1)
- `notes`, `templates`, `attachments`, `reminders`, `calendarLinks`
- Alanlar: `id`, `version`, `updatedAt`, `syncState`

2. Auth katmanı
- Apple Sign-In token doğrulama
- Sonraki faz: Google Sign-In

3. Sync queue adaptörü
- Mevcut `SyncEngine` protokolüne gerçek HTTP adapter
- Retry/backoff + failed queue

4. Attachment upload
- Yerel path -> object storage URL
- Metadata + mime type

5. Push ve paylaşım
- Shared note eventleri
- Takip bildirimleri

## Teknoloji seçimi notu
- Supabase: hızlı başlama, SQL güçlü
- Firebase: auth/realtime kolay

## Öneri
Önce mock backend (local JSON/HTTP stub) ile `SyncEngine` adapteri çıkar, sonra gerçek provider bağla.
