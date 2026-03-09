# Ripo Domain Contract v1

Bu sözleşme platform bağımsızdır ve Apple (SwiftUI) + Android (Kotlin) istemcilerinin aynı backend/sync modeliyle çalışması için referanstır.

## Core Entities
- `User`
- `Note`
- `Reminder`
- `RipoList`
- `ListItem`
- `ContactLink`
- `LocationLink`
- `CalendarLink`
- `Attachment`
- `TemplateDefinition`
- `Trip`
- `TripSegment`
- `TripChecklistItem`
- `PackingItem`
- `TripBudgetEstimate`

## Required Note Fields
- `id: UUID`
- `ownerUserId: UUID`
- `title: String`
- `plainTextBody: String`
- `status: active|archived|deleted`
- `source: manual|widget|siri|mail|shared`
- `syncState: synced|pending|failed`
- `version: Int`
- `createdAt: ISO-8601`
- `updatedAt: ISO-8601`

## Reminder Types
- `reminder`
- `alarm`
- `push`

## Sync Job Types
- `create`
- `update`
- `delete`

## Compatibility Rule
Yeni client, bilmediği alanları yok saymalıdır (`forward-compatible parsing`).

## Attachment (Image-first v1)
- `Attachment`
- `ownerType: note|template`
- `ownerId: UUID`
- `type: image|audio|file|mail`
- `localPath: String`
- `remoteURL: String?`
- `metadataJSON: String`

## Journal Security (v1)
- App lock states: `isLockEnabled`, `isUnlocked`
- Unlock methods: passcode, biometric
- Locked session journal create/read should be blocked
- Journal content encryption/decryption service:
  - Encrypt before persistence (when lock enabled)
  - Decrypt on read (only when unlocked session)
