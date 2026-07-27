# Zinseszins-Engine & Mathematische Logik: 1% Methode

Dieses Dokument erklärt die mathematische Grundlage und Algorithmen der **ScoreEngine** in der App.

---

## 1. Die Zinseszins-Formel (Das 1%-Prinzip)

Die App basiert auf der Kernphilosophie von James Clear aus *Atomic Habits*: Kleine tägliche Verbesserungen summieren sich über das Jahr zu signifikanten Fortschritten, während Vernachlässigungen das System regressieren lassen.

### Der mathematische Unterschied über ein Jahr
* **Täglicher Erfolg (+1.0%):** 
  $$1.01^{365} \approx 37.78 \quad (3778\% \text{ Leistungsfähigkeit})$$
* **Täglicher Misserfolg (-1.0%):** 
  $$0.99^{365} \approx 0.03 \quad (3\% \text{ Leistungsfähigkeit})$$

### Tägliche Berechnung
Sei $S_{t-1}$ der Capability-Score des Vortages. Der neue Score $S_t$ am Tag $t$ berechnet sich exponentiell:

* **Erfolg (alle Ziele erreicht):** 
  $$S_t = S_{t-1} \times 1.01$$
* **Misserfolg (mindestens ein Ziel verfehlt):** 
  $$S_t = S_{t-1} \times 0.99$$

---

## 2. Der Saison-Reset (Der FIFA-Loop)

Um Langeweile und Stagnation vorzubeugen, führt die App am **31. Dezember um 23:59 Uhr** einen Saison-Reset durch. 

### Das Konzept des "neuen Null"
Der über das Jahr hart erarbeitete Fortschritt wird nicht gelöscht. Stattdessen bildet der Endwert des ablaufenden Jahres die neue Baseline für das nächste Kalenderjahr. Das bedeutet:
* Der Nutzer muss sein Niveau halten.
* Im neuen Jahr startet der **Saisonfortschritt** wieder bei $+0.0\%$.
* Jeder prozentuale Zuwachs im neuen Jahr berechnet sich relativ zum neuen Basiswert.

Sei $B_y$ der Basiswert für das Jahr $y$ und $S_t$ der aktuelle Gesamt-Score. Der **Saisonfortschritt in Prozent** ($P_{\text{Saison}}$) berechnet sich wie folgt:

$$P_{\text{Saison}} = \left( \frac{S_t}{B_y} - 1.0 \right) \times 100$$

### Beispiel-Szenario
1. **Registrierung (Jahr 1):** Start-Score $S_0 = 100.0$. Die Baseline für Jahr 1 ist $B_1 = 100.0$.
2. **Jahresende (Jahr 1):** Nach 365 Tagen fleißigen Trainings steht der Score auf $S_{365} = 142.3$.
3. **Saison-Reset (Silvester):** 
   * Die Baseline für Jahr 2 wird gesetzt: $B_2 = 142.3$.
   * Der angezeigte Saisonfortschritt für das neue Jahr wird zurückgesetzt: 
     $$P_{\text{Saison}} = \left( \frac{142.3}{142.3} - 1.0 \right) \times 100 = 0.0\%$$
4. **Erster Tag (Jahr 2) - Erfolg:** 
   * Der Gesamt-Score wächst auf $S_{366} = 142.3 \times 1.01 = 143.723$.
   * Der neue Saisonfortschritt beträgt:
     $$P_{\text{Saison}} = \left( \frac{143.723}{142.3} - 1.0 \right) \times 100 = +1.0\%$$

---

## 3. Echtzeit-Fortschrittsprojektion für den aktuellen Tag

Um Frustration bei der Dateneingabe zu vermeiden und den Nutzer tagsüber zu motivieren, berechnet die App den täglichen Impact in Echtzeit. Da der Tag noch läuft, interpolieren wir die Veränderung linear anhand der Zielerreichungsquote.

### Berechnung des durchschnittlichen Tagesfortschritts
Der Gesamtfortschritt des Tages $F_{\text{Tag}}$ ist das arithmetische Mittel der Fortschritte der drei Hauptbereiche (Schritte, Training, Bildschirmzeit), jeweils begrenzt auf maximal 1.0 (100%):

$$F_{\text{Tag}} = \frac{\text{Schritte}_{\%Loc} + \text{Training}_{\%Loc} + \text{Bildschirmzeit}_{\%Loc}}{3}$$

Wobei der Bildschirmzeitfortschritt bei Einhaltung des Limits als $1.0$ gewertet wird. Bei Überschreitung degressiert er linear gegen $0.0$:

$$\text{Bildschirmzeit}_{\%Loc} = \max\left(0.0, 1.0 - \frac{\text{Aktuelle Zeit} - \text{Limit}}{\text{Limit}}\right)$$

### Projizierte Score-Auswirkung
Die Auswirkung $I_{\text{Tag}}$ wird linear zwischen dem maximalen Verlust ($-1.0\%$) und dem maximalen Zuwachs ($+1.0\%$) abgebildet:

$$I_{\text{Tag}} = -1.0\% + \left(2.0\% \times F_{\text{Tag}}\right)$$

* **Beispiel 1 (Früh morgens, noch nichts getan):** $F_{\text{Tag}} = 0.0 \implies I_{\text{Tag}} = -1.0\%$ (Drohender Verlust)
* **Beispiel 2 (Teilweise Erfüllung, z.B. Schritte 100%, Training 50%, Bildschirmzeit 90%):**
  * $F_{\text{Tag}} = \frac{1.0 + 0.5 + 0.9}{3} = 0.80$
  * $I_{\text{Tag}} = -1.0\% + \left(2.0\% \times 0.80\right) = +0.6\%$
* **Beispiel 3 (Vollständige Erfüllung):** $F_{\text{Tag}} = 1.0 \implies I_{\text{Tag}} = +1.0\%$
