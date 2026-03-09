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
