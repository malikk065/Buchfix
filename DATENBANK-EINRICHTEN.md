# Datenbank einrichten

Danach liegt deine Buchhaltung nicht mehr nur auf dem iPhone, sondern
zusätzlich auf einem Server. Geht das Handy verloren, meldest du dich auf
einem neuen Gerät an und alles ist wieder da.

Rechne mit 20 Minuten. Du brauchst einen Computer, am Handy ist das
Einrichten zu fummelig.

---

## 1. Konto anlegen

Geh auf **supabase.com** und registriere dich. Der kostenlose Tarif reicht
für deine Buchhaltung locker — er ist auf 500 MB Datenbank und 1 GB
Dateien ausgelegt, und ein Belegfoto wiegt bei uns etwa 100 KB.

Ein Hinweis, den du kennen solltest: Im kostenlosen Tarif wird ein Projekt
pausiert, wenn es eine Woche lang nicht benutzt wird. Es lässt sich mit
einem Klick wieder aufwecken, aber wenn dich das stört, kostet der nächste
Tarif rund 25 US-Dollar im Monat.

## 2. Projekt erstellen

**New Project** → Name „buchfix" → **Region: Frankfurt (eu-central-1)**.

Die Region ist wichtig. Deine Buchhaltung enthält Namen und Anschriften
deiner Kunden, also personenbezogene Daten. In Frankfurt bleiben sie in
der EU, und du sparst dir die Diskussion über Datenübermittlung in die
USA.

Ein Datenbank-Passwort wird verlangt — speichere es in deinem
Passwortmanager. Du brauchst es selten, aber es gibt keinen zweiten Weg
dran.

## 3. Tabellen anlegen

Links im Menü **SQL Editor** → **New query**.

Öffne die Datei `supabase/migrations/0001_app_schema.sql`, kopier den
gesamten Inhalt ins Fenster und klick **Run**.

Unten sollte „Success" stehen. Damit existieren alle Tabellen, die
Sicherheitsregeln und der Speicher für Belegfotos.

## 4. Zugangsdaten eintragen

**Project Settings → API**. Dort stehen zwei Werte:

- **Project URL** — sieht aus wie `https://abcdefgh.supabase.co`
- **anon public** — ein langer Schlüssel

Trag beide in die Datei `www/config.js` ein:

```js
window.BUCHFIX_CONFIG = {
  SUPABASE_URL: "https://abcdefgh.supabase.co",
  SUPABASE_ANON_KEY: "eyJhbGci..."
};
```

Der `anon`-Schlüssel darf öffentlich sein — er allein gibt niemandem
Zugriff auf Daten, das regeln die Sicherheitsregeln in der Datenbank.

**Den `service_role`-Schlüssel trägst du hier niemals ein.** Der hebt alle
Sicherheitsregeln auf. Wer ihn hat, liest jede Zeile jedes Nutzers.

## 5. E-Mail-Bestätigung

**Authentication → Providers → Email.** Zwei Möglichkeiten:

- **Confirm email aus:** Du kannst dich sofort anmelden. Für dich allein
  völlig in Ordnung.
- **Confirm email an:** Du bekommst erst eine Bestätigungsmail. Nötig,
  sobald andere Leute Konten anlegen können.

Der eingebaute Mailversand von Supabase ist auf wenige Mails pro Stunde
begrenzt. Für dich reicht das; für echte Kunden bräuchtest du einen
eigenen Mailversand.

## 6. Hochladen und anmelden

Lad die geänderten Dateien wieder auf deinen Webspace. In der App findest
du unter **Mehr → Konto und Datenbank** die Anmeldung. Konto anlegen,
anmelden — der erste Abgleich lädt alles hoch, was schon auf dem Gerät
liegt.

Oben in der Kopfzeile siehst du einen kleinen Punkt:
grün heißt abgeglichen, gelb heißt gerade dabei, rot heißt Fehler.

---

## Wie der Abgleich arbeitet

Die App speichert **immer zuerst auf dem Gerät**. Du kannst im Keller ohne
Empfang Belege erfassen; sobald wieder Netz da ist, geht alles von selbst
raus. Der Abgleich läuft beim Start, beim Zurückkehren in die App und
einige Sekunden nach jeder Änderung.

Änderst du denselben Datensatz auf zwei Geräten gleichzeitig, gewinnt die
zuletzt gespeicherte Fassung. Für einen Ein-Personen-Betrieb ist das die
richtige Abwägung — ein Konfliktdialog wäre bei jeder Kleinigkeit im Weg.
Wenn mal jemand mit dir zusammen arbeitet, müsste man das anders lösen.

Belegfotos landen in einem privaten Speicher, nicht in der Tabelle. Auf
einem zweiten Gerät werden sie bei Bedarf nachgeladen — dafür brauchst du
dort Netz.

## Was die Sicherheitsregeln leisten

Jede Zeile trägt deine Nutzer-ID, und die Datenbank prüft bei **jedem**
Zugriff, ob sie zum angemeldeten Konto passt. Das passiert im Server, nicht
in der App. Selbst wenn jemand die App auseinandernimmt und eigene Anfragen
schickt, bekommt er nur seine eigenen Zeilen.

## Trotzdem weiter sichern

Die Datenbank schützt dich vor Geräteverlust — nicht vor eigenen Fehlern.
Löschst du versehentlich zwanzig Buchungen, sind sie auch auf dem Server
weg.

Zieh dir deshalb weiter regelmäßig eine Sicherung über
**Einstellungen → Sicherung exportieren**. Die Erinnerung in der App
verschwindet, sobald die Datenbank läuft — das ist Absicht, aber einmal im
Quartal eine Datei in iCloud Drive kostet dich zwei Minuten.
