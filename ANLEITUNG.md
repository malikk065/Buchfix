# BuchFix als .ipa aufs iPhone

## Kurz vorweg

Ich kann die .ipa nicht selbst bauen. Für iOS-Apps braucht es Apples
Toolchain, und die läuft ausschließlich auf macOS — hier steht ein Linux-
Rechner ohne Xcode.

Was hier drin ist: das **komplette, fertige Xcode-Projekt** plus ein
Bauplan, mit dem **GitHub den Mac stellt und die .ipa für dich baut**.
Du brauchst dafür weder einen Mac noch 99 € im Jahr. Nach dem ersten
Durchlauf hast du eine echte `BuchFix.ipa` zum Herunterladen.

---

## Schritt 1: .ipa bauen lassen (etwa 10 Minuten)

1. Leg dir ein Konto auf github.com an, falls du keins hast.
2. Neues Repository anlegen, zum Beispiel `buchfix`. **Public** wählen —
   dann sind die Mac-Bauminuten kostenlos. Bei einem privaten Repo zählen
   sie zehnfach gegen dein Freikontingent.
3. Den Inhalt dieses Ordners hochladen. Am einfachsten über
   „Add file → Upload files" direkt im Browser: alle Dateien und die
   Ordner `www/`, `ios/` und `.github/` mit hochziehen.
4. Im Tab **Actions** den Ablauf „iPhone-App bauen (.ipa)" öffnen und auf
   **Run workflow** tippen.
5. Warte, bis der grüne Haken kommt. Unten unter **Artifacts** liegt
   `BuchFix-ipa` zum Herunterladen. Entpacken — darin ist die `BuchFix.ipa`.

Der Build läuft ohne Signatur. Die .ipa ist gültig, aber noch nicht auf
dein Gerät zugelassen. Das passiert im nächsten Schritt.

---

## Schritt 2: .ipa aufs iPhone bringen

Apple lässt Sideloading zu, aber jede App muss signiert sein. Du hast drei
Möglichkeiten.

### A) SideStore oder AltStore — kostenlos

Du signierst mit deiner normalen Apple-ID. Kein Developer-Account nötig.

- Du brauchst einmalig einen PC oder Mac, um AltStore/SideStore
  einzurichten.
- Danach installierst du die .ipa direkt vom iPhone aus.
- **Die Signatur hält 7 Tage.** AltStore erneuert sie automatisch, solange
  dein Rechner läuft und im selben WLAN ist. Bist du länger als eine Woche
  weg, musst du von Hand erneuern.
- Höchstens 3 sideloadete Apps gleichzeitig bei kostenloser Apple-ID.

Läuft die Signatur ab, startet die App nicht mehr — **deine Daten bleiben
aber erhalten** und sind nach dem Erneuern wieder da. Trotzdem: Für
Buchhaltung, die du im Alltag brauchst, ist das ein Risiko. Sichere
regelmäßig über Einstellungen → Sicherung exportieren.

### B) Apple Developer Account — 99 € im Jahr

Dieselbe .ipa, aber die Signatur hält ein Jahr statt sieben Tage, und das
3-App-Limit fällt weg. Ohne App-Store-Prüfung, ohne Wartezeit. Wenn du die
App täglich nutzt, ist das die entspannteste Lösung.

Damit kannst du sie später auch über TestFlight an andere verteilen oder
richtig im App Store veröffentlichen.

### C) TrollStore — nur auf alten iOS-Versionen

Signiert dauerhaft, ganz ohne Erneuerung. Funktioniert aber nur bis
iOS 17.0. Auf einem aktuellen iPhone geht das nicht mehr.

---

## Und die Variante ohne all das

Der Ordner `www/` ist gleichzeitig eine fertige Web-App. Auf deinen
Webspace laden, in **Safari** öffnen, Teilen → „Zum Home-Bildschirm".

Du bekommst dasselbe Icon, denselben Vollbildmodus, Offline-Betrieb und
dieselben PDFs — ohne Signatur, ohne Ablaufdatum, ohne Kosten. Der einzige
echte Unterschied zur .ipa sind Push-Benachrichtigungen bei geschlossener
App.

Wenn du nicht sicher bist: **fang damit an.** Die .ipa kannst du jederzeit
später bauen, die Daten sind dieselben.

---

## Was im Projekt schon eingerichtet ist

- App-ID `de.buchfix.app`, Anzeigename BuchFix, nur Hochformat
- App-Icon und Startbildschirm in hell und dunkel
- Kamera-Berechtigung mit deutschem Begründungstext — ohne den stürzt die
  App beim ersten Belegfoto ab
- Dateifreigabe, damit Sicherungen in der Dateien-App auftauchen
- Verschlüsselungserklärung (`ITSAppUsesNonExemptEncryption = false`), die
  Apple sonst bei jeder Einreichung nachfordert

## Wenn du etwas änderst

Nach jeder Änderung an den Web-Dateien in `www/`:

```bash
npm install
npx cap sync ios
```

Dann wieder pushen — GitHub baut automatisch eine neue .ipa.

Die Versionsnummer für ein Update setzt du in Xcode oder direkt in
`ios/App/App.xcodeproj/project.pbxproj` unter `MARKETING_VERSION`.

---

## Die 7 Tage — was wirklich passiert

Es gibt zwei verschiedene 7-Tage-Regeln. Sie werden oft verwechselt.

**1. Die Signatur der .ipa läuft nach 7 Tagen ab.**
Die App startet dann nicht mehr. **Deine Daten bleiben erhalten.** Sobald
du die Signatur erneuerst — AltStore macht das automatisch — ist alles
wieder da. Nichts löscht sich von selbst.

Gefährlich wird es nur, wenn du die App *löschst und neu installierst*,
statt zu erneuern. Dann sind die Daten weg.

**2. Safari löscht Website-Daten nach 7 Tagen ohne Nutzung.**
Das betrifft nur normale Safari-Tabs. **Apps auf dem Home-Bildschirm sind
davon ausgenommen** — die zählen für Apple nicht als Safari und haben
ihren eigenen Zähler.

Deshalb: die Web-Variante immer über „Zum Home-Bildschirm" nutzen, nie
als Lesezeichen im Tab liegen lassen.

**Was trotzdem passieren kann:** Wird der Speicher auf dem iPhone knapp,
räumt iOS auf. Die App fordert deshalb beim Start dauerhaften Speicher an
und erinnert dich ans Sichern, wenn 14 Tage nichts passiert ist. Unter
Einstellungen siehst du, ob der Schutz aktiv ist.

## Wichtig zu deinen Daten

Sie liegen ausschließlich auf dem Gerät. Kein Server, kein Konto, keine
Wiederherstellung durch mich oder sonst wen.

Erneuern der Signatur ist sicher. Neuinstallieren löscht alles. Zieh dir
vorher immer eine Sicherung — über Einstellungen → Sicherung exportieren
landet sie direkt im Teilen-Menü und von dort in iCloud Drive.

Belege musst du nach GoBD acht Jahre aufbewahren. Ein Telefon allein
reicht dafür nicht — leg die Exporte an einem zweiten Ort ab.
