import Foundation

/// Ein Daten-Snapshot der täglichen automatischen Metriken aus HealthKit und Screen Time.
public struct DailyMetricSnapshot: Codable, Identifiable, Hashable {
    public let id: UUID
    public let date: Date
    public let stepsCount: Int
    public let stepsTarget: Int
    public let workoutMinutes: Int
    public let workoutTarget: Int
    public let screentimeSeconds: Int
    public let screentimeLimitSeconds: Int
    
    public init(
        id: UUID = UUID(),
        date: Date,
        stepsCount: Int,
        stepsTarget: Int = 10000,
        workoutMinutes: Int,
        workoutTarget: Int = 30,
        screentimeSeconds: Int,
        screentimeLimitSeconds: Int = 7200
    ) {
        self.id = id
        self.date = date
        self.stepsCount = stepsCount
        self.stepsTarget = stepsTarget
        self.workoutMinutes = workoutMinutes
        self.workoutTarget = workoutTarget
        self.screentimeSeconds = screentimeSeconds
        self.screentimeLimitSeconds = screentimeLimitSeconds
    }
    
    /// Gibt an, ob alle täglichen automatischen Ziele erreicht wurden.
    public var allTargetsMet: Bool {
        let stepsAchieved = stepsCount >= stepsTarget
        let workoutAchieved = workoutMinutes >= workoutTarget
        let screentimeAchieved = screentimeSeconds <= screentimeLimitSeconds
        return stepsAchieved && workoutAchieved && screentimeAchieved
    }
    
    /// Berechnet die durchschnittliche Zielerreichung als Wert zwischen 0.0 und 1.0.
    public var averageTargetProgress: Double {
        let stepsProgress = min(Double(stepsCount) / Double(stepsTarget), 1.0)
        let workoutProgress = min(Double(workoutMinutes) / Double(workoutTarget), 1.0)
        let screentimeProgress = screentimeSeconds <= screentimeLimitSeconds ? 1.0 : max(0.0, 1.0 - (Double(screentimeSeconds - screentimeLimitSeconds) / Double(screentimeLimitSeconds)))
        
        return (stepsProgress + workoutProgress + screentimeProgress) / 3.0
    }
}

/// Repräsentiert einen berechneten Punkt im historischen Verlauf des Scores.
public struct HistoricalScorePoint: Identifiable, Codable, Hashable {
    public let id: UUID
    public let date: Date
    public let scoreBefore: Double
    public let scoreAfter: Double
    public let changePercent: Double
    public let isSuccess: Bool
    
    public init(
        id: UUID = UUID(),
        date: Date,
        scoreBefore: Double,
        scoreAfter: Double,
        changePercent: Double,
        isSuccess: Bool
    ) {
        self.id = id
        self.date = date
        self.scoreBefore = scoreBefore
        self.scoreAfter = scoreAfter
        self.changePercent = changePercent
        self.isSuccess = isSuccess
    }
}

/// Die mathematische Zinseszins-Engine der "1% Methode".
///
/// Berechnet die tägliche Steigerung (+1.0%) oder Minderung (-1.0%) und verwaltet
/// die jährlichen Saisongrenzen (FIFA-Loop Reset).
public actor ScoreEngine {
    
    public let successMultiplier: Double // z.B. 1.01 (+1%)
    public let failureMultiplier: Double // z.B. 0.99 (-1%)
    
    /// Initialisiert die ScoreEngine mit anpassbaren Steigerungs- und Minderungssätzen.
    /// - Parameters:
    ///   - successIncrement: Die Steigerungsrate bei Erfolg (Standard: 0.01 = 1%).
    ///   - failureDecrement: Die Minderungsrate bei Misserfolg (Standard: 0.01 = 1%).
    public init(successIncrement: Double = 0.01, failureDecrement: Double = 0.01) {
        self.successMultiplier = 1.0 + successIncrement
        self.failureMultiplier = 1.0 - failureDecrement
    }
    
    /// Berechnet die gesamte Trajektorie des Capability-Scores basierend auf historischen Snapshots.
    ///
    /// Diese Funktion verarbeitet die Daten chronologisch und führt am 31. Dezember jedes Jahres
    /// einen Saison-Reset durch. Der Endwert des Jahres wird das "neue Null" (der Basiswert)
    /// für das Folgejahr.
    ///
    /// - Parameters:
    ///   - startingScore: Der absolute Start-Score des Nutzers bei Registrierung (Standard: 100.0).
    ///   - dailyMetrics: Eine Liste der täglichen Snapshots (unsortiert möglich).
    /// - Returns:
    ///   - finalScore: Der aktuelle Gesamt-Score des Benutzers.
    ///   - history: Chronologische Liste aller berechneten Fortschrittspunkte.
    ///   - seasonBaselines: Verzeichnis der Saison-Start-Scores indiziert nach Kalenderjahr.
    public func calculateTrajectory(
        startingScore: Double = 100.0,
        dailyMetrics: [DailyMetricSnapshot]
    ) async -> (finalScore: Double, history: [HistoricalScorePoint], seasonBaselines: [Int: Double]) {
        guard !dailyMetrics.isEmpty else {
            return (startingScore, [], [:])
        }
        
        // Chronologische Sortierung
        let sortedMetrics = dailyMetrics.sorted(by: { $0.date < $1.date })
        
        var currentScore = startingScore
        var historyPoints: [HistoricalScorePoint] = []
        var seasonBaselines: [Int: Double] = [:]
        
        let calendar = Calendar(identifier: .gregorian)
        
        for metric in sortedMetrics {
            let components = calendar.dateComponents([.year, .month, .day], from: metric.date)
            guard let year = components.year, let month = components.month, let day = components.day else {
                continue
            }
            
            // Wenn für das aktuelle Kalenderjahr noch kein Basis-Score festgelegt wurde,
            // setzen wir den aktuellen Gesamt-Score als Saison-Basiswert fest.
            if seasonBaselines[year] == nil {
                seasonBaselines[year] = currentScore
            }
            
            let isSuccess = metric.allTargetsMet
            let multiplier = isSuccess ? successMultiplier : failureMultiplier
            
            let scoreBefore = currentScore
            currentScore = currentScore * multiplier
            
            // Berechne die relative prozentuale Abweichung für diesen Tag
            let changePercent = ((currentScore / scoreBefore) - 1.0) * 100.0
            
            let point = HistoricalScorePoint(
                date: metric.date,
                scoreBefore: scoreBefore,
                scoreAfter: currentScore,
                changePercent: changePercent,
                isSuccess: isSuccess
            )
            historyPoints.append(point)
            
            // FIFA-Loop: Am 31. Dezember wird das Ergebnis des Jahres als Baseline für das Folgejahr festgelegt.
            if month == 12 && day == 31 {
                seasonBaselines[year + 1] = currentScore
            }
        }
        
        return (currentScore, historyPoints, seasonBaselines)
    }
    
    /// Berechnet den kumulativen Saisonfortschritt im aktuellen Kalenderjahr in Prozent.
    ///
    /// - Parameters:
    ///   - currentScore: Der aktuelle Gesamt-Score.
    ///   - seasonBaseline: Der Startwert der laufenden Saison.
    /// - Returns: Der relative Zuwachs/Verlust innerhalb dieser Saison in Prozent (z.B. +42.3%).
    public nonisolated func calculateSeasonProgress(currentScore: Double, seasonBaseline: Double) -> Double {
        guard seasonBaseline > 0 else { return 0.0 }
        return ((currentScore / seasonBaseline) - 1.0) * 100.0
    }
    
    /// Berechnet die projizierte Score-Änderung für den heutigen Tag in Echtzeit.
    ///
    /// Diese Funktion interpoliert die Auswirkung linear basierend auf der durchschnittlichen Zielerreichung.
    /// Wenn alle Ziele zu 100% erfüllt sind, ergibt sich ein Zuwachs von genau +1.0%.
    /// Wenn noch kein Ziel begonnen wurde, beträgt der drohende Verlust -1.0%.
    ///
    /// - Parameter todayMetric: Die aktuellen Metrikwerte für heute.
    /// - Returns: Die projizierte Veränderung in Prozent (z.B. +0.80% oder -1.00%).
    public nonisolated func projectDailyImpact(for todayMetric: DailyMetricSnapshot) -> Double {
        let progress = todayMetric.averageTargetProgress // Wert zwischen 0.0 und 1.0
        // Lineare Abbildung von [0.0, 1.0] auf [-1.0%, +1.0%]
        let minImpact = -1.0
        let maxImpact = 1.0
        return minImpact + (maxImpact - minImpact) * progress
    }
}
