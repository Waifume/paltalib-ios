//
//  EventQueueAssembly+Config.swift
//  PaltaLibAnalytics
//
//  Created by Vyacheslav Beltyukov on 18/05/2022.
//

import Foundation

extension EventQueueAssembly {
    func apply(_ target: ConfigTarget) {
        eventQueueCore.config = .init(
            maxBatchSize: target.settings.eventUploadMaxBatchSize,
            uploadInterval: TimeInterval(target.settings.eventUploadPeriodSeconds),
            uploadThreshold: target.settings.eventUploadThreshold,
            maxEvents: target.settings.eventMaxCount,
            maxConcurrentOperations: 5
        )

        liveEventQueueCore.config = .init(
            maxBatchSize: target.settings.eventUploadMaxBatchSize,
            uploadInterval: 0,
            uploadThreshold: 0,
            maxEvents: target.settings.eventMaxCount,
            maxConcurrentOperations: .max
        )

        eventQueue.trackingSessionEvents = target.settings.trackingSessionEvents
        eventQueue.liveEventTypes = target.settings.realtimeEventTypes
        eventQueue.excludedEvents = target.settings.excludedEventTypes
        
        eventSender.baseURL = target.url

        sessionManager.maxSessionAge = target.settings.minTimeBetweenSessionsMillis
    }
}