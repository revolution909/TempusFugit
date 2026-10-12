# TempusFugit

App mobile (Flutter, iOS + Android) per tenere in un posto solo i **coupon fisici e digitali**, ricordare a cosa servono e **avvisare prima della scadenza**. I dati restano sul telefono (SQLite), nessun account.

## Cosa fa (MVP)

- **Inserimento a basso attrito**, tutto sul dispositivo:
  - scansione di barcode / QR dal vivo;
  - foto del coupon o immagine dalla galleria: legge il codice, poi OCR del testo e regole (italiano/inglese) che estraggono negozio, sconto, spesa minima, date di validità e scadenza, codice promo, condizioni;
  - testo incollato dagli appunti (es. un codice promo ricevuto in chat);
  - inserimento manuale con negozio suggerito e scadenze rapide (+7 giorni, +30 giorni, fine mese, fine anno).
  - Ogni strada termina in **una sola schermata di conferma**: i campi letti automaticamente con poca sicurezza sono evidenziati (icona + testo, non solo colore).
- **Elenco** raggruppato per urgenza (Scadono presto · Questa settimana · Questo mese · Più avanti · Senza scadenza), con ricerca per negozio o titolo e filtri Attivi / Scaduti / Usati. Scorri a destra per «Usato», a sinistra per «Elimina»: nessuna conferma, ma un **Annulla** di 6 secondi. Con TalkBack/VoiceOver le stesse azioni sono nel menu azioni della riga e nella pressione lunga.
- **Promemoria locali**: 7 giorni prima, 1 giorno prima e la mattina della scadenza (ore 9). Toccando la notifica si apre il coupon.
- **Vista "in cassa"**: codice ridisegnato a tutto schermo, luminosità al massimo, schermo sempre acceso.
- "Associato a": negozio/marchio più un'etichetta libera (es. "regalo di Anna").
- **Lettura intelligente (opzionale)**: un modello AI **sul telefono** compila in background i campi che le regole non riconoscono. Il form si apre subito con le regole; l'AI arriva dopo, scrive solo nei campi ancora vuoti e mai in quelli che hai già toccato, e li segna con l'icona ✨ ("Suggerito dall'AI: controlla"). Disattivata di default (Impostazioni).

## Interfaccia e accessibilità

- **Material 3** con un colore di marca fisso (verde acqua, `ColorScheme.fromSeed`), tema chiaro e scuro automatici. L'urgenza usa sempre **colore + icona + testo** (mai solo il colore); le coppie di colori sono verificate WCAG AA (≥ 4,5:1) da `test/ui_contrast_test.dart`.
- Componenti dell'SDK per quasi tutto; due sole librerie in più: [`flutter_slidable`](https://pub.dev/packages/flutter_slidable) (swipe sulle righe) e [`animations`](https://pub.dev/packages/animations) (transizione riga → dettaglio, ufficiale Flutter). Scartate di proposito: `dynamic_color` (colore fisso voluto), `google_fonts` (scarica da internet), `flutter_animate` (non più mantenuta), `skeletonizer` (i dati sono locali).
- Il form protegge dalla perdita di dati (conferma se esci con modifiche), lo scanner legge solo dentro il riquadro e mostra lo stato della torcia, la vista in cassa resta bianca per i lettori.
- `test/ui_accessibility_test.dart` applica le linee guida di Flutter (target ≥ 48 dp, etichette, contrasto) a ogni schermata in chiaro e scuro, e controlla che a testo ingrandito (×2) su 360×640 non ci siano overflow. Gli screenshot si generano con `SCREENSHOT_DIR=cartella flutter test test/screenshots/screens_test.dart`.

## Struttura

```
lib/
  domain/          modello Coupon
  data/            tabella Drift (SQLite) + CouponRepository
  extraction/      RuleExtractor (date/sconti/codici/negozio), ExtractionPipeline (barcode + OCR + regole)
  llm/             prompt + parser validato, merge regole/AI, interfaccia LlmExtractor,
                   EdgeAiExtractor (unico file che usa flutter_edge_ai)
  notifications/   ReminderPlanner (logica pura) + NotificationService (plugin)
  ui/              tema, token (spaziature, raggi, durate), colori d'urgenza, widget comuni
  features/        list, form (conferma/modifica), scan, detail (+ vista cassa), add, settings
test/              estrattore, pianificatore, pipeline, repository, flussi UI, LLM (con LLM finto),
                   contrasto, accessibilità, screenshot
```

Scelte da sapere:

- `ReminderPlanner` calcola quali notifiche devono esistere ed è separato dal plugin: così è testabile e rispetta il limite di ~64 notifiche pendenti di iOS tenendo solo le più vicine. Le notifiche vengono ricalcolate a ogni modifica e a ogni ritorno nell'app.
- **LLM on-device**: l'app funziona sempre con le sole regole; l'AI è un livello in più. Quale modello gira dipende dal telefono:
  - **modello del sistema** (nessun download): Gemini Nano su Pixel 8/9/10 e pochi altri, Apple Foundation Models su iPhone 15 Pro+ con iOS 26;
  - **modello scaricabile** (`litert-community/Qwen3-0.6B`, circa 300–600 MB, solo su richiesta e meglio con il Wi-Fi): per tutti gli altri telefoni, **Pixel 6a incluso** (Gemini Nano di sistema non è disponibile prima del Pixel 8).
  - Il testo dei coupon non lascia mai il telefono; l'unico traffico è il download del modello da Hugging Face.
  - L'output del modello viene sempre **validato** (date plausibili, percentuali 1–100, importi sensati) e nomi e codici devono comparire nel testo originale, altrimenti vengono scartati. Un codice a barre scansionato non viene mai sostituito.
  - Tutto il codice che tocca `flutter_edge_ai` è in `lib/llm/edge_ai_extractor.dart`, dietro l'interfaccia `LlmExtractor`: il pacchetto è nuovissimo e le sue API possono cambiare. Le versioni sono fissate esattamente in `pubspec.yaml`.

## Sviluppo

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # solo se cambi lib/data/database.dart
flutter analyze
flutter test
flutter run
```

Requisiti nativi:

- **Android 11+ (minSdk 30) e solo arm64**, richiesti dal motore LiteRT-LM del modello scaricabile. Gli emulatori x86 non sono supportati.
- **iOS 15.5** (ML Kit) con pod collegati staticamente (`ios/Podfile`).
- Su iOS le notifiche e la fotocamera chiedono il permesso al primo uso.

## Provare l'app sul telefono (APK di prova)

Ogni push esegue la CI (`.github/workflows/ci.yml`): analyze, test e build di un **APK debug arm64**.

1. Su GitHub: **Actions** → ultimo run verde → sezione *Artifacts* → `tempusfugit-debug-arm64` (zip, conservato 14 giorni). Serve essere loggati in GitHub.
2. Decomprimi, copia `app-debug.apk` sul telefono e aprilo (Android chiede di consentire l'installazione da quella app). È firmato con la chiave di debug: va bene per provare, non per pubblicare.
3. L'APK debug è più lento e più grande di una release: i tempi dell'AI e dell'OCR possono essere migliori in una build `--release`.

Checklist di prova (segna cosa non va, anche i dettagli):

- [ ] **Permessi**: fotocamera al primo scan; notifiche (Android 13+ le chiede).
- [ ] **Scansione**: barcode e QR veri, con poca luce e con la torcia; codice letto fuori dal riquadro ignorato.
- [ ] **Foto/OCR**: ~30 coupon veri (cartacei stropicciati, schermate di app, email). Quanti campi sono giusti senza correzioni?
- [ ] **AI** (Impostazioni → attiva → scarica modello, meglio col Wi-Fi): stesso insieme di coupon, regole sole contro regole+AI; tempo per coupon, calore/batteria, modello ancora attivo dopo il riavvio, nessun dato inventato.
- [ ] **Promemoria**: crea un coupon che scade domani e uno tra 7 giorni; arrivano alle 9:00? Toccando la notifica si apre il coupon?
- [ ] **Elenco**: swipe «Usato» / «Elimina» + Annulla, ricerca, filtri.
- [ ] **Vista in cassa**: il lettore della cassa legge il codice ridisegnato (luminosità al massimo).
- [ ] **Accessibilità**: TalkBack acceso (le azioni delle righe sono nel menu azioni), testo di sistema al massimo, tema scuro.

## Non ancora fatto

- Condivisione da altre app (share sheet), import PDF e `.pkpass`.
- Verifica reale dell'LLM su un telefono: qualità, tempi, memoria e batteria non sono stati misurati (vedi sotto).
- Azioni "Usato" / "Posticipa" direttamente dalla notifica; orari e giorni dei promemoria configurabili.
- Export / backup dei dati (oggi disinstallare l'app li cancella).
- Verifica su un telefono vero di UI e accessibilità: gli screenshot e le linee guida automatiche girano nel simulatore di test, non su TalkBack/VoiceOver; resa del colore, ombre e fluidità delle animazioni vanno viste a mano. Mancano anche icona e splash screen dell'app.
- Verifica su dispositivi reali: l'OCR su coupon veri (cartacei, stropicciati) va misurata prima di fidarsi delle regole.

### Da provare sul telefono (l'LLM non è stato eseguito in sviluppo)

I test coprono prompt, validazione, merge e comportamento del form con un LLM finto. Non è stato eseguito alcun modello reale. Su un Pixel 6a o simile: Impostazioni → attiva → "Scarica modello" → fotografa o incolla ~30 coupon veri e confronta regole-sole e regole+AI. Da controllare: tempo per coupon, memoria, batteria, che il modello resti attivo dopo il riavvio dell'app, e che l'AI non inventi dati. Se non migliora in modo misurabile, lasciarla spenta.
