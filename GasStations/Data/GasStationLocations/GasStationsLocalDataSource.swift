import Foundation
import Combine

protocol GasStationsLocalDataSourceType {
    func getCCAA() -> AnyPublisher<[CCAA], Error>
    func save(ccaaList: [CCAA]) -> AnyPublisher<[CCAA], Error>
    func deleteAllCCAAs() -> AnyPublisher<Int, Error>
    
    func getProvinces(idCCAA: String?) -> AnyPublisher<[Province], Error>
    func save(provincesList: [Province]) -> AnyPublisher<[Province], Error>    
    func deleteAllProvinces() -> AnyPublisher<Int, Error>
    
    
    //GAS STATION
    func getGasStations(idProvince: String?, idProduct: String?) -> AnyPublisher<[GasStation], Error>
    func save(gasPrices: GasPrices, idProvince: String, idProduct: String) -> AnyPublisher<[GasStation], Error>
    func deleteAllGasStations() -> AnyPublisher<Int, Error>
    
    func deleteAllGasPrices() -> AnyPublisher<Int, Error>
    
    //PRODUCTS
    func getProducts() -> AnyPublisher<[Product], Error>
    func save(productList: [Product]) -> AnyPublisher<[Product], Error>
    func deleteAllProducts() -> AnyPublisher<Int, Error>
    
}

struct GasStationsLocalDataSource {
    private let persistenceController: PersistenceControllerType
    
    init(persistenceController: PersistenceControllerType = PersistenceController.shared) {
        self.persistenceController = persistenceController
    }
}

extension GasStationsLocalDataSource: GasStationsLocalDataSourceType {
    
    func getCCAA() -> AnyPublisher<[CCAA], Error> {
        print("GasStationsLocalDataSource going to GET all CCAAs from local data source")
        return persistenceController.getCCAA()
    }
    
    func save(ccaaList: [CCAA]) -> AnyPublisher<[CCAA], Error> {
        print("GasStationsLocalDataSource going to SAVE \(ccaaList.count) CCAAs")
        return persistenceController.save(ccaaList: ccaaList)
    }
    
    func deleteAllCCAAs() -> AnyPublisher<Int, Error> {
        print("GasStationsLocalDataSource going to DELETE ALL CCAAs")
        return persistenceController.deleteAllCCAAs()
    }
    
    func getProvinces(idCCAA: String?) -> AnyPublisher<[Province], Error> {
        print("GasStationsLocalDataSource going to GET PROVINCES from local data source")
        return persistenceController.getProvinces(idCCAA: idCCAA)
    }
    
    func save(provincesList: [Province]) -> AnyPublisher<[Province], Error> {
        print("GasStationsLocalDataSource going to persist \(provincesList.count) elements")
        return persistenceController.save(provincesList: provincesList)
    }
    
    func deleteAllProvinces() -> AnyPublisher<Int, Error> {
        print("GasStationsLocalDataSource going to DELETE ALL PROVINCES")
        return persistenceController.deleteAllProvinces()
    }
    
    
    //LOCAL DATA SOURCE
    func getProducts() -> AnyPublisher<[Product], Error> {
        print("GasStationsLocalDataSource going to GET all PRODUCTS from local data source")
        return persistenceController.getProducts()
    }
    
    func save(productList: [Product]) -> AnyPublisher<[Product], Error> {
        print("GasStationsLocalDataSource going to SAVE \(productList.count) PRODUCTS LIST")
        return persistenceController.save(productList: productList)
    }
    
    func deleteAllProducts() -> AnyPublisher<Int, Error> {
        print("GasStationsLocalDataSource going to DELETE ALL PRODCUTS")
        return persistenceController.deleteAllProducts()
    }
    
    func getGasStations(idProvince: String?, idProduct: String?) -> AnyPublisher<[GasStation], Error> {
        print("GasStationsLocalDataSource going to GET GAS STATIONS from local data source")
        return persistenceController.getGasStations(idProvince: idProvince, idProduct: idProduct)
    }
    
    func save(gasPrices: GasPrices, idProvince: String, idProduct: String) -> AnyPublisher<[GasStation], Error> {
        print("GasStationsLocalDataSource going to SAVE \(gasPrices.elements.count)")
        return persistenceController.save(idProvince: idProvince, idProduct: idProduct, gasPrices: gasPrices)
    }
    
    func deleteAllGasStations() -> AnyPublisher<Int, Error> {
        print("GasStationsLocalDataSource going to DELETE ALL GAS STATIONS")
        return persistenceController.deleteAllGasStations()
    }
    
    func deleteAllGasPrices() -> AnyPublisher<Int, Error> {
        print("GasStationsLocalDataSource going to DELETE ALL GAS PRICES")
        return persistenceController.deleteAllGasPrices()
    }
    
}
