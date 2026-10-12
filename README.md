# TempusFugit

App mobile (Flutter, iOS + Android) per tenere in un posto solo i **coupon fisici e digitali**, ricordare a cosa servono e **avvisare prima della scadenza**. I dati restano sul telefono (SQLite), nessun account.

## Cosa fa (MVP)

- **Inserimento a basso attrito**, tutto sul dispositivo:
  - scansione di barcode / QR dal vivo;
  - foto del coupon o immagine dalla galleria: legge il codice, poi OCR del testo e regole (italiano/inglese) che estraggono negozio, sconto, spesa minima, date di validità e scadenza, codice promo, condizioni;
  - testo incollato dagli appunti (es. un codice promo ricevuto in chat);
  - inserimento manuale con negozio suggerito e scadenze rapide (+7 giorni, +30 giorni, fine mese, fine anno).
  - Ogni strada termina in **una sola schermata di conferma**: i campi letti automaticamente con poca sicurezza sono evidenziati in arancione.
- **Elenco** ordinato per scadenza, con colori d'urgenza (≤3 giorni rosso, ≤7 arancione) e schede Attivi / Scaduti / Usati.
- **Promemoria locali**: 7 giorni prima, 1 giorno prima e la mattina della scadenza (ore 9). Toccando la notifica si apre il coupon.
- **Vista "in cassa"**: codice ridisegnato a tutto schermo, luminosità al massimo, schermo sempre acceso.
- "Associato a": negozio/marchio più un'etichetta libera (es. "regalo di Anna").

## Struttura

```
lib/
  domain/          modello Coupon
  data/            tabella Drift (SQLite) + CouponRepository
  extraction/      RuleExtractor (date/sconti/codici/negozio), ExtractionPipeline (barcode + OCR + regole)
  notifications/   ReminderPlanner (logica pura) + NotificationService (plugin)
  features/        list, form (conferma/modifica), scan, detail (+ vista cassa), add
test/              estrattore, pianificatore, pipeline, repository, flussi UI
```

Scelte da sapere:

- `ReminderPlanner` calcola quali notifiche devono esistere ed è separato dal plugin: così è testabile e rispetta il limite di ~64 notifiche pendenti di iOS tenendo solo le più vicine. Le notifiche vengono ricalcolate a ogni modifica e a ogni ritorno nell'app.
- Il livello **LLM on-device** previsto per i testi ambigui **non è ancora implementato**. Le regole sono la base che funziona su qualsiasi telefono; l'LLM (Apple Foundation Models su iPhone 15 Pro+ con iOS 26, Gemini Nano su alcuni Android, oppure un modello scaricabile) verrà aggiunto sopra, solo per i campi che le regole lasciano vuoti.

## Sviluppo

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # solo se cambi lib/data/database.dart
flutter analyze
flutter test
flutter run
```

Requisiti nativi: Android minSdk dal template Flutter; iOS 15.5 (richiesto da ML Kit). Su iOS le notifiche e la fotocamera chiedono il permesso al primo uso.

## Non ancora fatto

- Condivisione da altre app (share sheet), import PDF e `.pkpass`.
- LLM on-device (vedi sopra).
- Azioni "Usato" / "Posticipa" direttamente dalla notifica; orari e giorni dei promemoria configurabili.
- Export / backup dei dati (oggi disinstallare l'app li cancella).
- Verifica su dispositivi reali: l'OCR su coupon veri (cartacei, stropicciati) va misurata prima di fidarsi delle regole.
