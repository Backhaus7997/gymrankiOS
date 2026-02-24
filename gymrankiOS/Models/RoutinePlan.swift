import Foundation

enum Weekday: Int, CaseIterable, Identifiable, Codable {
    case monday = 1, tuesday, wednesday, thursday, friday, saturday, sunday
    var id: Int { rawValue }

    var shortLabel: String {
        switch self {
        case .monday: return "L"
        case .tuesday: return "M"
        case .wednesday: return "M"
        case .thursday: return "J"
        case .friday: return "V"
        case .saturday: return "S"
        case .sunday: return "D"
        }
    }

    var fullLabel: String {
        switch self {
        case .monday: return "Lunes"
        case .tuesday: return "Martes"
        case .wednesday: return "Miércoles"
        case .thursday: return "Jueves"
        case .friday: return "Viernes"
        case .saturday: return "Sábado"
        case .sunday: return "Domingo"
        }
    }

    static var today: Weekday {
        let weekday = Calendar.current.component(.weekday, from: Date()) // 1=Dom ... 7=Sáb
        let mondayBased = ((weekday + 5) % 7) + 1 // 1=Lun ... 7=Dom
        return Weekday(rawValue: mondayBased) ?? .monday
    }
}

enum RoutineMuscle: String, CaseIterable, Identifiable, Codable {
    case pecho = "Pecho"
    case espalda = "Espalda"
    case femorales = "Femorales"
    case hombros = "Hombros"
    case biceps = "Bíceps"
    case triceps = "Tríceps"
    case abdomen = "Abdomen"
    case gluteos = "Glúteos"
    case cuadriceps = "Cuadriceps"
    case pantorrillas = "Pantorrillas"
    case trapecios = "Trapecios"
    case antebrazos = "Antebrazos"

    var id: String { rawValue }
}

struct RoutinePlan: Codable, Equatable {
    var byDay: [Weekday: [RoutineMuscle]] = [:]

    func muscles(for day: Weekday) -> [RoutineMuscle] {
        byDay[day] ?? []
    }

    var isEmpty: Bool {
        byDay.values.allSatisfy { $0.isEmpty }
    }
}
