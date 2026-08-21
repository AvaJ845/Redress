import Foundation
import SwiftData
import os

extension ModelContext {
    /// SwiftData save failures were previously 100% silent everywhere in the
    /// app (`try? context.save()`). This at least logs so a failure is
    /// diagnosable — a full user-facing error surface is a larger follow-up.
    func saveOrLog(file: String = #fileID, line: Int = #line) {
        do {
            try save()
        } catch {
            Logger(subsystem: "AvaResearchLLC.Redress", category: "persistence")
                .error("context.save() failed at \(file):\(line): \(error.localizedDescription)")
        }
    }
}
