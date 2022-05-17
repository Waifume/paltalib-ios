//
//  PaltaPurchasesTests.swift
//  PaltaLibPayments
//
//  Created by Vyacheslav Beltyukov on 04.05.2022.
//

import Foundation
import XCTest
@testable import PaltaLibPayments

final class PaltaPurchasesTests: XCTestCase {
    var instance: PaltaPurchases!
    var mockPlugins: [PurchasePluginMock] = []
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        mockPlugins = (0...2).map { _ in PurchasePluginMock() }
        instance = PaltaPurchases()
        instance.setup(with: mockPlugins)
    }
    
    func testConfigure() {
        let plugins = (1...3).map { _ in PurchasePluginMock() }
        let instance = PaltaPurchases()
        instance.setup(with: plugins)

        XCTAssert(instance.setupFinished)
        XCTAssertEqual(instance.plugins as? [PurchasePluginMock], plugins)
    }
    
    func testLogin() {
        let userId = UserId.uuid(UUID())
        
        instance.logIn(appUserId: userId)
        
        checkPlugins {
            $0.logInUserId == userId
        }
    }
    
    func testLogOut() {
        instance.logOut()
        
        checkPlugins {
            $0.logOutCalled
        }
    }
    
    func testGetPaidServicesSuccess() {
        let pluginServices = [
            PaidServices(
                services: [
                    PaidService(name: "Service 1", startDate: Date(timeIntervalSince1970: 0), endDate: nil),
                    PaidService(name: "Service 2", startDate: Date(timeIntervalSince1970: 0), endDate: nil),
                    PaidService(name: "Service 3", startDate: Date(timeIntervalSince1970: 0), endDate: nil)
                ]
            ),
            PaidServices(),
            PaidServices(
                services: [
                    PaidService(name: "Service 6", startDate: Date(timeIntervalSince1970: 0), endDate: nil),
                    PaidService(name: "Service 2", startDate: Date(timeIntervalSince1970: 88), endDate: nil),
                    PaidService(name: "Service 5", startDate: Date(timeIntervalSince1970: 0), endDate: nil)
                ]
            )
        ]
        
        assert(mockPlugins.count == pluginServices.count)
        
        let expectedServices = PaidServices(
            services: [
                PaidService(name: "Service 1", startDate: Date(timeIntervalSince1970: 0), endDate: nil),
                PaidService(name: "Service 2", startDate: Date(timeIntervalSince1970: 0), endDate: nil),
                PaidService(name: "Service 3", startDate: Date(timeIntervalSince1970: 0), endDate: nil),
                PaidService(name: "Service 6", startDate: Date(timeIntervalSince1970: 0), endDate: nil),
                PaidService(name: "Service 2", startDate: Date(timeIntervalSince1970: 88), endDate: nil),
                PaidService(name: "Service 5", startDate: Date(timeIntervalSince1970: 0), endDate: nil)
            ]
        )
        
        let completionCalled = expectation(description: "Get paid services completed successfully")
        
        instance.getPaidServices { result in
            guard case .success(let services) = result else {
                return
            }
            
            XCTAssertEqual(services, expectedServices)
            
            completionCalled.fulfill()
        }
        
        checkPlugins {
            $0.getPaidServicesCompletion != nil
        }
        
        DispatchQueue.concurrentPerform(iterations: mockPlugins.count) { iteration in
            mockPlugins[iteration].getPaidServicesCompletion?(.success(pluginServices[iteration]))
        }
        
        wait(for: [completionCalled], timeout: 0.1)
    }
    
    func testGetPaidServicesOneError() {
        let pluginServices = [
            PaidServices(
                services: [
                    PaidService(name: "Service 1", startDate: Date(timeIntervalSince1970: 0), endDate: nil),
                    PaidService(name: "Service 2", startDate: Date(timeIntervalSince1970: 0), endDate: nil),
                    PaidService(name: "Service 3", startDate: Date(timeIntervalSince1970: 0), endDate: nil)
                ]
            ),
            PaidServices()
        ]
        
        let completionCalled = expectation(description: "Get paid services completed with fail 1")
        
        instance.getPaidServices { result in
            guard case .failure = result else {
                return
            }
            
            completionCalled.fulfill()
        }
        
        checkPlugins {
            $0.getPaidServicesCompletion != nil
        }
        
        DispatchQueue.concurrentPerform(iterations: mockPlugins.count) { iteration in
            mockPlugins[iteration].getPaidServicesCompletion?(
                pluginServices.indices.contains(iteration)
                ? .success(pluginServices[iteration])
                : .failure(NSError(domain: "", code: 0))
            )
        }
        
        wait(for: [completionCalled], timeout: 0.1)
    }
    
    func testGetPaidServicesAllErrors() {
        let completionCalled = expectation(description: "Get paid services completed with fail 2")
        
        instance.getPaidServices { result in
            guard case .failure = result else {
                return
            }
            
            completionCalled.fulfill()
        }
        
        checkPlugins {
            $0.getPaidServicesCompletion != nil
        }
        
        DispatchQueue.concurrentPerform(iterations: mockPlugins.count) { iteration in
            mockPlugins[iteration].getPaidServicesCompletion?(.failure(NSError(domain: "", code: 0)))
        }
        
        wait(for: [completionCalled], timeout: 0.1)
    }
    
    func testPromoOfferFirstSuccess() {
        let completionCalled = expectation(description: "Get promo offer completed 1")
        
        instance.getPromotionalOffer(for: ProductDiscountMock(), product: ProductMock()) { result in
            guard case .success = result else {
                return
            }
            
            completionCalled.fulfill()
        }
        
        XCTAssertNotNil(mockPlugins[0].getPromotionalOfferCompletion)
        XCTAssertNil(mockPlugins[1].getPromotionalOfferCompletion)
        XCTAssertNil(mockPlugins[2].getPromotionalOfferCompletion)
        
        mockPlugins[0].getPromotionalOfferCompletion?(.success(PromoOfferMock()))
        
        wait(for: [completionCalled], timeout: 0.1)
    }
    
    func testPromoOfferFirstFail() {
        let completionCalled = expectation(description: "Get promo offer completed 2")
        
        instance.getPromotionalOffer(for: ProductDiscountMock(), product: ProductMock()) { result in
            guard case .failure = result else {
                return
            }
            
            completionCalled.fulfill()
        }
        
        XCTAssertNotNil(mockPlugins[0].getPromotionalOfferCompletion)
        XCTAssertNil(mockPlugins[1].getPromotionalOfferCompletion)
        XCTAssertNil(mockPlugins[2].getPromotionalOfferCompletion)
        
        mockPlugins[0].getPromotionalOfferCompletion?(.failure(NSError(domain: "", code: 0)))
        
        wait(for: [completionCalled], timeout: 0.1)
    }
    
    func testPromoOfferLastSuccess() {
        let completionCalled = expectation(description: "Get promo offer completed 3")
        
        instance.getPromotionalOffer(for: ProductDiscountMock(), product: ProductMock()) { result in
            guard case .success = result else {
                return
            }
            
            completionCalled.fulfill()
        }
        
        XCTAssertNotNil(mockPlugins[0].getPromotionalOfferCompletion)
        mockPlugins[0].getPromotionalOfferCompletion?(.notSupported)
        
        XCTAssertNotNil(mockPlugins[1].getPromotionalOfferCompletion)
        mockPlugins[1].getPromotionalOfferCompletion?(.notSupported)
        
        XCTAssertNotNil(mockPlugins[2].getPromotionalOfferCompletion)
        
        mockPlugins[2].getPromotionalOfferCompletion?(.success(PromoOfferMock()))
        
        wait(for: [completionCalled], timeout: 0.1)
    }
    
    func testPromoOfferNotSupportedEverywhere() {
        let completionCalled = expectation(description: "Get promo offer completed 4")
        
        instance.getPromotionalOffer(for: ProductDiscountMock(), product: ProductMock()) { result in
            guard case .failure = result else {
                return
            }
            
            completionCalled.fulfill()
        }
        
        XCTAssertNotNil(mockPlugins[0].getPromotionalOfferCompletion)
        mockPlugins[0].getPromotionalOfferCompletion?(.notSupported)
        
        XCTAssertNotNil(mockPlugins[1].getPromotionalOfferCompletion)
        mockPlugins[1].getPromotionalOfferCompletion?(.notSupported)
        
        XCTAssertNotNil(mockPlugins[2].getPromotionalOfferCompletion)
        
        mockPlugins[2].getPromotionalOfferCompletion?(.notSupported)
        
        wait(for: [completionCalled], timeout: 0.1)
    }
    
    func testPurchaseFirstSuccess() {
        let completionCalled = expectation(description: "Get purchase completed 1")
        
        instance.purchase(ProductMock(), with: nil) { result in
            guard case .success(let purchase) = result else {
                return
            }
            
            XCTAssertEqual(purchase.transaction, .inApp)
            
            completionCalled.fulfill()
        }
        
        XCTAssertNotNil(mockPlugins[0].purchaseCompletion)
        XCTAssertNil(mockPlugins[1].purchaseCompletion)
        XCTAssertNil(mockPlugins[2].purchaseCompletion)
        
        mockPlugins[0].purchaseCompletion?(
            .success(SuccessfulPurchase(transaction: .inApp, paidServices: PaidServices()))
        )
        
        wait(for: [completionCalled], timeout: 0.1)
    }
    
    func testPurchaseFirstFail() {
        let completionCalled = expectation(description: "Get purchase completed 2")

        instance.purchase(ProductMock(), with: nil) { result in
            guard case .failure = result else {
                return
            }
            
            completionCalled.fulfill()
        }
        
        XCTAssertNotNil(mockPlugins[0].purchaseCompletion)
        XCTAssertNil(mockPlugins[1].purchaseCompletion)
        XCTAssertNil(mockPlugins[2].purchaseCompletion)
        
        mockPlugins[0].purchaseCompletion?(.failure(NSError(domain: "", code: 0)))
        
        wait(for: [completionCalled], timeout: 0.1)
    }
    
    func testPurchaseLastSuccess() {
        let completionCalled = expectation(description: "Get purchase completed 3")
        
        instance.purchase(ProductMock(), with: nil) { result in
            guard case .success(let purchase) = result else {
                return
            }
            
            XCTAssertEqual(purchase.transaction, .web)
            
            completionCalled.fulfill()
        }
        
        XCTAssertNotNil(mockPlugins[0].purchaseCompletion)
        mockPlugins[0].purchaseCompletion?(.notSupported)
        
        XCTAssertNotNil(mockPlugins[1].purchaseCompletion)
        mockPlugins[1].purchaseCompletion?(.notSupported)
        
        XCTAssertNotNil(mockPlugins[2].purchaseCompletion)
        
        mockPlugins[2].purchaseCompletion?(
            .success(SuccessfulPurchase(transaction: .web, paidServices: PaidServices()))
        )
        
        wait(for: [completionCalled], timeout: 0.1)
    }
    
    func testPurchaseNotSupportedEverywhere() {
        let completionCalled = expectation(description: "Get purchase completed 4")
        
        instance.purchase(ProductMock(), with: nil) { result in
            guard case .failure = result else {
                return
            }
            
            completionCalled.fulfill()
        }
        
        XCTAssertNotNil(mockPlugins[0].purchaseCompletion)
        mockPlugins[0].purchaseCompletion?(.notSupported)
        
        XCTAssertNotNil(mockPlugins[1].purchaseCompletion)
        mockPlugins[1].purchaseCompletion?(.notSupported)
        
        XCTAssertNotNil(mockPlugins[2].purchaseCompletion)
        
        mockPlugins[2].purchaseCompletion?(.failure(NSError(domain: "", code: 0)))
        
        wait(for: [completionCalled], timeout: 0.1)
    }
    
    func testRestore() {
        instance.restorePurchases()
        
        checkPlugins {
            $0.restorePurchasesCalled
        }
    }
    
    private func checkPlugins(line: UInt = #line, file: StaticString = #file, _ check: (PurchasePluginMock) -> Bool) {
        XCTAssert(!mockPlugins.isEmpty, file: file, line: line)
        
        let checkResult = mockPlugins.allSatisfy(check)
        XCTAssert(checkResult, file: file, line: line)
    }
}
