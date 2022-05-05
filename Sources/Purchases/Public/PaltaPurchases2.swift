//
//  PaltaPurchases2.swift
//  PaltaLibCore
//
//  Created by Vyacheslav Beltyukov on 04.05.2022.
//

import Foundation

public final class PaltaPurchases2 {
    public static let instance = PaltaPurchases2()

    var setupFinished = false
    var plugins: [PurchasePlugin] = []

    public func setup(with plugins: [PurchasePlugin]) {
        guard !setupFinished else {
            assertionFailure("Attempt to setup PaltaPurchases twice")
            return
        }

        setupFinished = true
        self.plugins = plugins
    }

    private func checkSetupFinished() {
        if !setupFinished {
            assertionFailure("Setup palta purchases with plugins first!")
        }
    }
}