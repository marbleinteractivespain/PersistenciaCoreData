import Foundation
import CoreData
import Combine

protocol PersistenceControllerType {
    func getCCAA() -> AnyPublisher<[CCAA], Error>
    func save(ccaaList: [CCAA]) -> AnyPublisher<[CCAA], Error>
    func deleteAllCCAAs() -> AnyPublisher<Int, Error>
    
    func getProvinces(idCCAA: String?) -> AnyPublisher<[Province], Error>
    func save(provincesList: [Province]) -> AnyPublisher<[Province], Error>
    func deleteAllProvinces() -> AnyPublisher<Int, Error>
    
    //GAS STATION
    func getGasStations(idProvince: String?, idProduct: String?) -> AnyPublisher<[GasStation], Error>
    func save(idProvince: String?, idProduct: String?, gasPrices: GasPrices) -> AnyPublisher<[GasStation], Error>
    func deleteAllGasStations() -> AnyPublisher<Int, Error>
    
    //GAS PRICES
    func deleteAllGasPrices() -> AnyPublisher<Int, Error>
    
    //PRODUCTS
    func getProducts() -> AnyPublisher<[Product], Error>
    func save(productList: [Product]) -> AnyPublisher<[Product], Error>
    func deleteAllProducts() -> AnyPublisher<Int, Error>
    
    
}

struct PersistenceController {
    static let shared = PersistenceController()
    
    private let container: NSPersistentContainer
    
    var mainMOC: NSManagedObjectContext {
        let context = container.viewContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    // Helper background MOC, not used anywhere in this code!!
    //    var backgroundContext: NSManagedObjectContext {
    //        let newbackgroundContext = container.newBackgroundContext()
    //        newbackgroundContext.automaticallyMergesChangesFromParent = true
    //        newbackgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    //        return newbackgroundContext
    //    }
    
    init() {
        container = NSPersistentContainer(name: "Gasolineras")
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("There was an error initializing CoreData: \(error)")
            }
        }
    }
}

/// ----->                       ------>
///     ----------------->
///

extension PersistenceController: PersistenceControllerType {
    
    func getCCAA() -> AnyPublisher<[CCAA], Error> {
        return Future<[CCAA], Error>() { promise in
            container.performBackgroundTask { context in
                let fetchRequest = CDCCAA.fetchRequest()
                fetchRequest.predicate = nil
                
                var result: [CDCCAA]?
                do {
                    result = try context.fetch(fetchRequest)
                } catch {
                    promise(Result.failure(error))
                }
                
                if let result = result {
                    let convertedResult = result.map { CCAA(cdCCAA: $0) }
                    promise(Result.success(convertedResult))
                } else {
                    promise(Result.success([]))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func save(ccaaList: [CCAA]) -> AnyPublisher<[CCAA], Error> {
        return Future<[CCAA], Error>() { promise in
            container.performBackgroundTask { context in
                ccaaList.forEach { currentCCAA in
                    let newCCAAEntry = CDCCAA(context: context)
                    newCCAAEntry.ccaaName = currentCCAA.ccaaName
                    newCCAAEntry.idCCAA = currentCCAA.idCCAA
                }
                
                do {
                    try context.save()
                    promise(.success(ccaaList))
                } catch {
                    print("There was an error saving \(ccaaList.count) CCAAs in batch: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deleteCCAAs(with ccaaNames: [String]) -> AnyPublisher<Int, Error> {
        return Future<Int, Error>() { promise in
            container.performBackgroundTask { context in
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CDCCAA.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "self.ccaaName in %@", ccaaNames)
                
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                deleteRequest.resultType = .resultTypeObjectIDs
                
                var deleteResult: NSBatchDeleteResult?
                do {
                    deleteResult = try context.execute(deleteRequest) as? NSBatchDeleteResult
                } catch {
                    print("There was an error deleting all CCAAs in batch: \(error)")
                    promise(.failure(error))
                }
                
                if let deleteResult = deleteResult?.result as? [NSManagedObjectID] {
                    promise(.success(deleteResult.count))
                } else {
                    promise(.failure(APIError.invalidData))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deleteAllCCAAs() -> AnyPublisher<Int, Error> {
        return Future<Int, Error>() { promise in
            container.performBackgroundTask { context in
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CDCCAA.fetchRequest()
                fetchRequest.predicate = nil
                
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                deleteRequest.resultType = .resultTypeObjectIDs
                
                var deleteResult: NSBatchDeleteResult?
                do {
                    deleteResult = try context.execute(deleteRequest) as? NSBatchDeleteResult
                } catch {
                    print("There was an error deleting all CCAAs in batch: \(error)")
                    promise(.failure(error))
                }
                
                if let deleteResult = deleteResult?.result as? [NSManagedObjectID] {
                    promise(.success(deleteResult.count))
                } else {
                    promise(.failure(APIError.invalidData))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getProvinces(idCCAA: String?) -> AnyPublisher<[Province], Error> {
            return Future<[Province], Error>() { promise in
                container.performBackgroundTask { context in
                    let fetchRequest = CDProvince.fetchRequest()
                    if let idCCAA = idCCAA {
                        fetchRequest.predicate = NSPredicate(format: "self.belongs.idCCAA like %@", idCCAA)
                    } else {
                        fetchRequest.predicate = nil
                    }
                    
                    var result: [CDProvince]?
                    do {
                        result = try context.fetch(fetchRequest)
                    } catch {
                        promise(Result.failure(error))
                    }
                    
                    if let result = result {
                        let convertedResult = result.map { Province(cdProvince: $0) }
                        promise(.success(convertedResult))
                    } else {
                        promise(.success([]))
                    }
                }
            }
            .eraseToAnyPublisher()
    }
    
    func save(provincesList: [Province]) -> AnyPublisher<[Province], Error> {
        Future { promise in
            container.performBackgroundTask { context in
                
                var indexedEntries: [String: [CDProvince]] = [:]
                
                provincesList.forEach { currentProvince in
                    
                    let newEntry = CDProvince(context: context)
                    newEntry.provinceName = currentProvince.provinceName
                    newEntry.idProvince = currentProvince.idProvince
                    
                    if let existingProvinces = indexedEntries[currentProvince.idCCAA] {
                        indexedEntries[currentProvince.idCCAA] = existingProvinces + [newEntry]
                    } else {
                        indexedEntries[currentProvince.idCCAA] = [newEntry]
                    }
                }
                
                indexedEntries.forEach { (key: String, value: [CDProvince]) in
                    self.addProvinces(value, idCCAA: key, context: context)
                }
                
                do {
                    try context.save()
                    promise(.success(provincesList))
                } catch {
                    print("Something went wrong: \(error)")
                    promise(.failure(error))
                    context.rollback()
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func addProvinces(_ provinces: [CDProvince],
                              idCCAA: String,
                              context: NSManagedObjectContext) {
        let fetchRequest = CDCCAA.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "self.idCCAA like %@", idCCAA)
        
        var result: [CDCCAA]?
        do {
            result = try context.fetch(fetchRequest)
        } catch {
            print("There was an error adding provinces list to existing CCAA")
        }
        
        if let result = result?.first {
            result.addToContains(NSSet.init(array: provinces))
            print("We just added \(provinces.count) CDProvinces to \(result.ccaaName ?? "NO CCAA name")")
        }
    }
    
    func deleteAllProvinces() -> AnyPublisher<Int, Error> {
        return Future<Int, Error>() { promise in
            container.performBackgroundTask { context in
                
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CDProvince.fetchRequest()
                fetchRequest.predicate = nil
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                deleteRequest.resultType = .resultTypeObjectIDs
                
                var deleteResult: NSBatchDeleteResult?
                do {
                    deleteResult = try context.execute(deleteRequest) as? NSBatchDeleteResult
                } catch {
                    print("There was an error deleting all CCAAs in batch: \(error)")
                    promise(.failure(error))
                }
                
                if let deleteResult = deleteResult?.result as? [NSManagedObjectID] {
                    promise(.success(deleteResult.count))
                } else {
                    promise(.failure(APIError.invalidData))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    
    //MARK: PRODUCTS
    func getProducts() -> AnyPublisher<[Product], Error> {
        return Future<[Product], Error>() { promise in
            container.performBackgroundTask { context in
                let fetchRequest = CDPRODUCT.fetchRequest()
                fetchRequest.predicate = nil
                
                var result: [CDPRODUCT]?
                do {
                    result = try context.fetch(fetchRequest)
                } catch {
                    promise(Result.failure(error))
                }
                
                if let result = result {
                    let convertedResult = result.map { Product(cdProducts: $0) }
                    
                    promise(Result.success(convertedResult))
                } else {
                    promise(Result.success([]))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func save(productList: [Product]) -> AnyPublisher<[Product], Error> {
        return Future<[Product], Error>() { promise in
            container.performBackgroundTask { context in
                productList.forEach { currentPRODUCT in
                    let newPRODUCTEntry = CDPRODUCT(context: context)
                    newPRODUCTEntry.productName = currentPRODUCT.productName
                    newPRODUCTEntry.idProduct = currentPRODUCT.idProduct
                    newPRODUCTEntry.shortProductName = currentPRODUCT.shortProductName
                }
                
                do {
                    try context.save()
                    promise(.success(productList))
                } catch {
                    print("There was an error saving \(productList.count) PRODUCT in batch: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deleteAllProducts() -> AnyPublisher<Int, Error> {
        return Future<Int, Error>() { promise in
            container.performBackgroundTask { context in
                
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CDPRODUCT.fetchRequest()
                fetchRequest.predicate = nil
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                deleteRequest.resultType = .resultTypeObjectIDs
                
                var deleteResult: NSBatchDeleteResult?
                do {
                    deleteResult = try context.execute(deleteRequest) as? NSBatchDeleteResult
                } catch {
                    print("There was an error deleting all PRODUCTS in batch: \(error)")
                    promise(.failure(error))
                }
                
                if let deleteResult = deleteResult?.result as? [NSManagedObjectID] {
                    promise(.success(deleteResult.count))
                } else {
                    promise(.failure(APIError.invalidData))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    
    //MARK: GAS STATIONS
    func getGasStations(idProvince: String?, idProduct: String?) -> AnyPublisher<[GasStation], Error> {
        return Future<[GasStation], Error>() { promise in
            container.performBackgroundTask { context in
                let fetchRequest = CDGASSTATION.fetchRequest()
                fetchRequest.predicate = nil
                
                if let idProvince = idProvince, let idProduct = idProduct {
                    fetchRequest.predicate = NSPredicate(format: "self.belongsProv.idProvince like %@ and self.containsProd.idProduct like %@", idProvince, idProduct)

                }else{
                    fetchRequest.predicate = nil
                }
                
                var result: [CDGASSTATION]?
                
                do{
                    result = try context.fetch(fetchRequest)
                }catch{
                    promise(Result.failure(error))
                }
                
                if let result = result {
                    let convertedResult = result.map{ GasStation(cdGasStation: $0) }
                    promise(.success(convertedResult))
                }else{
                    promise(.success([]))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func save(idProvince: String?, idProduct: String?, gasPrices: GasPrices) -> AnyPublisher<[GasStation], Error> {
        Future<[GasStation], Error> { promise in
            container.performBackgroundTask { context in
                
                let price = CDPRICES(context: context)
                let dateFormat = DateFormatter()
                dateFormat.dateFormat = "dd/MM/yyyy HH:mm:ss"
                price.date = dateFormat.date(from:gasPrices.date)
                
                let fetchRequestProvince = CDProvince.fetchRequest()
                if let idProvince = idProvince {
                    fetchRequestProvince.predicate = NSPredicate(format: "self.idProvince like %@", idProvince)
                } else {
                    fetchRequestProvince.predicate = nil
                }
                
                var resultRequestProvinces: [CDProvince]?
                do {
                    resultRequestProvinces = try context.fetch(fetchRequestProvince)
                } catch {
                    print("There was an error finding Provinces")
                }
                
                let fetchRequestProduct = CDPRODUCT.fetchRequest()
                if let idProduct = idProduct {
                    fetchRequestProduct.predicate = NSPredicate(format: "self.idProduct like %@", idProduct)
                } else {
                    fetchRequestProduct.predicate = nil
                }
                
                var resultRequestProducts: [CDPRODUCT]?
                do {
                    resultRequestProducts = try context.fetch(fetchRequestProduct)
                } catch {
                    print("There was an error finding Products")
                }
                
                gasPrices.elements.forEach { currentGASSTATION in
                    
                    let newGASSTATIONEntry = CDGASSTATION(context: context)
                    
                    newGASSTATIONEntry.address = currentGASSTATION.address
                    newGASSTATIONEntry.place = currentGASSTATION.place
                    newGASSTATIONEntry.price = currentGASSTATION.price
                    newGASSTATIONEntry.timetable = currentGASSTATION.timetable
                    
                    //Provinces
                    if let resultRequestProvinces = resultRequestProvinces{
                        newGASSTATIONEntry.belongsProv = resultRequestProvinces.first
                    }
                    //Products
                    if let resultRequestProducts = resultRequestProducts{
                        newGASSTATIONEntry.containsProd = resultRequestProducts.first
                    }
                    //Prices
                    newGASSTATIONEntry.containsPrices = price
    
            }
            do {
                try context.save()
                promise(.success(gasPrices.elements))
            } catch {
                print("Something went wrong: \(error)")
                promise(.failure(error))
                context.rollback()
            }
        }
    }
    .eraseToAnyPublisher()
    }

    func deleteAllGasStations() -> AnyPublisher<Int, Error> {
        return Future<Int, Error>() { promise in
            container.performBackgroundTask { context in
                
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CDGASSTATION.fetchRequest()
                fetchRequest.predicate = nil
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                deleteRequest.resultType = .resultTypeObjectIDs
                
                var deleteResult: NSBatchDeleteResult?
                do {
                    deleteResult = try context.execute(deleteRequest) as? NSBatchDeleteResult
                } catch {
                    print("There was an error deleting all GAS STATIONS in batch: \(error)")
                    promise(.failure(error))
                }
                
                if let deleteResult = deleteResult?.result as? [NSManagedObjectID] {
                    promise(.success(deleteResult.count))
                } else {
                    promise(.failure(APIError.invalidData))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deleteAllGasPrices() -> AnyPublisher<Int, Error> {
        return Future<Int, Error>() { promise in
            container.performBackgroundTask { context in
                
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CDPRICES.fetchRequest()
                fetchRequest.predicate = nil
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                deleteRequest.resultType = .resultTypeObjectIDs
                
                var deleteResult: NSBatchDeleteResult?
                do {
                    deleteResult = try context.execute(deleteRequest) as? NSBatchDeleteResult
                } catch {
                    print("There was an error deleting all GAS PRICES in batch: \(error)")
                    promise(.failure(error))
                }
                
                if let deleteResult = deleteResult?.result as? [NSManagedObjectID] {
                    promise(.success(deleteResult.count))
                } else {
                    promise(.failure(APIError.invalidData))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
