import Foundation
import CoreLocation

struct GasStation: Decodable {
    let address: String
    let place: String
    let timetable: String
    let price: Double
    let date: Date
    
    enum CodingKeys: String, CodingKey {
        case address = "Dirección"
        case timetable = "Horario"
        case latitude = "Latitud"
        case longitude = "Longitud (WGS84)"
        case price = "PrecioProducto"
        case place = "Localidad"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        address = try values.decode(String.self, forKey: .address)
        place = try values.decode(String.self, forKey: .place)
        timetable = try values.decode(String.self, forKey: .timetable)
        let priceString = try values.decode(String.self, forKey: .price).replacingOccurrences(of: ",", with: ".")
        price = Double(priceString)!
        date = Date()
        
    }
}

extension GasStation: Identifiable {
    var id: UUID {
        return UUID()
    }
}

extension GasStation{
    init(cdGasStation: CDGASSTATION) {
        self.address = cdGasStation.address ?? "ADDRESS"
        self.place = cdGasStation.place ?? "PLACE"
        self.price = cdGasStation.price
        self.timetable = cdGasStation.timetable ?? "TIMETABLE"
        self.date = cdGasStation.containsPrices?.date ?? Date()
    }
}
