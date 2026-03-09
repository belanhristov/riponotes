# Ripo Notes

Apple-first ürün hedefi korunarak, Android'e taşınabilir bir çekirdek mimari hazırlanmıştır.

## Bu repoda şu an ne var?

- `RipoDomain`: platform bağımsız entity + protocol sözleşmeleri
- `RipoUseCases`: quick note ve note->reminder dönüşüm use-case'leri
- `RipoData`: local-first in-memory repository/scheduler/sync queue örneği
- `docs/contracts`: Android ve backend ile paylaşılacak domain contract referansı

## Neden bu yaklaşım?

- SwiftUI istemcisi Apple tarafında en iyi native deneyimi verir.
- Android için ayrı native istemci (Kotlin/Compose) yazılır.
- İki istemci aynı **domain contract + sync protokolünü** kullanır.
- Böylece UX native kalır, veri katmanı ortak kalır.

## Hızlı başlangıç

```bash
swift test
```

## Sonraki adım (önerilen)

1. Xcode iOS/macOS app target oluştur ve bu paketi dependency olarak ekle.
2. Inbox + NoteEditor SwiftUI ekranlarını `QuickNoteEngine` ile bağla.
3. `InMemory` yerine SwiftData tabanlı repository yaz.
4. SyncEngine için gerçek backend adapter (Supabase/Firebase) ekle.
5. Android tarafı için aynı contract'tan Kotlin data model üretimini başlat.
