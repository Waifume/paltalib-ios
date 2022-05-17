//
//  CustomerInfo+PaidServices.swift
//  PaltaLibPayments
//
//  Created by Vyacheslav Beltyukov on 13/05/2022.
//

import Foundation
import RevenueCat

extension CustomerInfo {
    var paidServices: PaidServices {
        PaidServices(
            services: subscriptionServices + nonSubscriptionServices
        )
    }
    
    private var subscriptionServices: [PaidService] {
        entitlements.all.values.map {
            PaidService(
                name: $0.identifier,
                productIdentifier: $0.productIdentifier,
                paymentType: .subscription,
                transactionType: $0.store.transactionType,
                isTrial: $0.periodType == .trial,
                startDate: $0.latestPurchaseDate ?? Date(timeIntervalSince1970: 0),
                endDate: $0.expirationDate,
                cancellationDate: $0.unsubscribeDetectedAt
            )
        }
    }
    
    private var nonSubscriptionServices: [PaidService] {
        nonSubscriptionTransactions.map {
            PaidService(
                name: $0.productIdentifier,
                productIdentifier: $0.productIdentifier,
                paymentType: .oneOff,
                transactionType: .appStore,
                isTrial: false,
                startDate: $0.purchaseDate,
                endDate: nil,
                cancellationDate: nil
            )
        }
    }
}

private extension Store {
    var transactionType: PaidService.TransactionType {
        switch self {
        case .appStore, .macAppStore:
            return .appStore
        case .playStore:
            return .googlePlay
        case .stripe, .promotional, .unknownStore:
            return .web
        }
    }
}