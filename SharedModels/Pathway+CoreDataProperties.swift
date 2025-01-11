//
//  Pathway+CoreDataProperties.swift
//  XP
//
//  Created by Quinn Darling on 1/11/25.
//
//

import Foundation
import CoreData


extension Pathway {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Pathway> {
        return NSFetchRequest<Pathway>(entityName: "Pathway")
    }

    @NSManaged public var colorIndex: Int32
    @NSManaged public var currentLevel: Int32
    @NSManaged public var currentXP: Int32
    @NSManaged public var descriptionText: String?
    @NSManaged public var emoji: String?
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var objectivesCompleted: Int32
    @NSManaged public var requiredXPForLevel: Int32
    @NSManaged public var activeCadenceCycle: CadenceCycle?
    @NSManaged public var cadenceCycles: NSSet?
    @NSManaged public var objectives: NSSet?

}

// MARK: Generated accessors for cadenceCycles
extension Pathway {

    @objc(addCadenceCyclesObject:)
    @NSManaged public func addToCadenceCycles(_ value: CadenceCycle)

    @objc(removeCadenceCyclesObject:)
    @NSManaged public func removeFromCadenceCycles(_ value: CadenceCycle)

    @objc(addCadenceCycles:)
    @NSManaged public func addToCadenceCycles(_ values: NSSet)

    @objc(removeCadenceCycles:)
    @NSManaged public func removeFromCadenceCycles(_ values: NSSet)

}

// MARK: Generated accessors for objectives
extension Pathway {

    @objc(addObjectivesObject:)
    @NSManaged public func addToObjectives(_ value: StoredObjective)

    @objc(removeObjectivesObject:)
    @NSManaged public func removeFromObjectives(_ value: StoredObjective)

    @objc(addObjectives:)
    @NSManaged public func addToObjectives(_ values: NSSet)

    @objc(removeObjectives:)
    @NSManaged public func removeFromObjectives(_ values: NSSet)

}

extension Pathway : Identifiable {

}
