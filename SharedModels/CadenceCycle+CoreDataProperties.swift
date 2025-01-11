//
//  CadenceCycle+CoreDataProperties.swift
//  XP
//
//  Created by Quinn Darling on 1/11/25.
//
//

import Foundation
import CoreData


extension CadenceCycle {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CadenceCycle> {
        return NSFetchRequest<CadenceCycle>(entityName: "CadenceCycle")
    }

    @NSManaged public var count: Int32
    @NSManaged public var endDate: Date?
    @NSManaged public var frequency: Int32
    @NSManaged public var id: UUID?
    @NSManaged public var isActive: Bool
    @NSManaged public var startDate: Date?
    @NSManaged public var currentStreak: Int32
    @NSManaged public var lastCompletedDate: Date?
    @NSManaged public var activeInPathway: Pathway?
    @NSManaged public var objectives: NSSet?
    @NSManaged public var pathway: Pathway?

}

// MARK: Generated accessors for objectives
extension CadenceCycle {

    @objc(addObjectivesObject:)
    @NSManaged public func addToObjectives(_ value: StoredObjective)

    @objc(removeObjectivesObject:)
    @NSManaged public func removeFromObjectives(_ value: StoredObjective)

    @objc(addObjectives:)
    @NSManaged public func addToObjectives(_ values: NSSet)

    @objc(removeObjectives:)
    @NSManaged public func removeFromObjectives(_ values: NSSet)

}

extension CadenceCycle : Identifiable {

}
