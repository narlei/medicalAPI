import Vapor

/// Controls basic CRUD operations on `Todo`s.
final class TodoController {
    /// Returns a list of all `Todo`s.
    func index(_ req: Request) throws -> Future<[Todo]> {
        return Todo.query(on: req).all()
    }

    /// Saves a decoded `Todo` to the database.
    func create(_ req: Request) throws -> String {
        var textParam = ""
        let param = try? req.content.decode(DiagnosticParameters.self).map(to: DiagnosticParameters.self, { param in
            textParam = param.text
            return param
        })

        if !textParam.isEmpty {
            return MachineLearning().processText(text: textParam)
        }

        return "{\"error\":\"Incorrect parameter\"}"
    }

    /// Deletes a parameterized `Todo`.
    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(Todo.self).flatMap { todo in
            todo.delete(on: req)
        }.transform(to: .ok)
    }
}

struct DiagnosticParameters: Content {
    var text: String
}

class MachineLearning {
    func processText(text: String) -> String {
        let arrayWeight = ["peso", "quilos", "quilograma", "kg"]
        let currentWeight: Double? = getValueFromSufix(arraySufix: arrayWeight, text: text)

        let arrayHeightMeter = ["metros", "m", "metros"]
        let currentHeightMeter: Double? = getValueFromSufix(arraySufix: arrayHeightMeter, text: text)

        let arrayHeightCm = ["centimetros", "cm"]
        let currentHeightCm: Double? = getValueFromSufix(arraySufix: arrayHeightCm, text: text)

        let arraySymptoms = ["sintomas", "sintoma"]
        let currentSymptoms: String? = getValueFromPrefix(arraySufix: arraySymptoms, text: text)

        let dicReturn = [
            "weight": currentWeight,
            "height": (currentHeightMeter ?? 0 * 100) + (currentHeightCm ?? 0),
            "symptoms": currentSymptoms,
            "full_text": text
        ] as [String: Any?]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dicReturn, options: .prettyPrinted)

            return String(data: jsonData, encoding: .utf8) ?? "{\"error\":\"Incorrect parameter\"}"
        } catch {
            return "{\"error\":\"Incorrect parameter\"}"
        }
    }

    func getValueFromSufix<T>(arraySufix: [String], text: String) -> T? {
        let arrayWords = text.components(separatedBy: " ")
        for i in 0 ..< arrayWords.count {
            let word = arrayWords[i]
            let clearWord = word.folding(options: .diacriticInsensitive, locale: .current).lowercased()
            if arraySufix.contains(clearWord) { // Achou o peso
                let index = i - 1 // Descarta a palavra atual
                for j in (0 ... index).reversed() {
                    let jWord = arrayWords[j]
                    if T.self is Double.Type {
                        if let intWeight = Double(jWord) {
                            return intWeight as? T
                        }
                    }
                    if T.self is String.Type {
                        return jWord as? T
                    }
                }
            }
        }
        return nil
    }

    func getValueFromPrefix<T>(arraySufix: [String], text: String) -> T? {
        let arrayWords = text.components(separatedBy: " ")
        for i in 0 ..< arrayWords.count {
            let word = arrayWords[i]
            let clearWord = word.folding(options: .diacriticInsensitive, locale: .current).lowercased()
            if arraySufix.contains(clearWord) { // Achou o peso
                let index = i + 1 // Descarta a palavra atual
                for j in index ..< arrayWords.count {
                    let jWord = arrayWords[j]
                    if T.self is Double.Type {
                        if let intWeight = Double(jWord) {
                            return intWeight as? T
                        }
                    }
                    if T.self is String.Type {
                        return jWord as? T
                    }
                }
            }
        }
        return nil
    }
}
