//
//  User+CoreDataProperties.swift
//  XP
//
//  Created by Quinn Darling on 1/11/25.
//
//

import Foundation
import CoreData


extension User {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }

    @NSManaged public var currentLevel: Int32
    @NSManaged public var currentXP: Int32
    @NSManaged public var firstName: String?
    @NSManaged public var id: UUID?
    @NSManaged public var objectivesCompleted: Int32
    @NSManaged public var requiredXPForLevel: Int32
    @NSManaged public var streakEndDate: Date?
    @NSManaged public var streakStartDate: Date?
    @NSManaged public var objectives: NSSet?

}

// MARK: Generated accessors for objectives
extension User {

    @objc(addObjectivesObject:)
    @NSManaged public func addToObjectives(_ value: StoredObjective)

    @objc(removeObjectivesObject:)
    @NSManaged public func removeFromObjectives(_ value: StoredObjective)

    @objc(addObjectives:)
    @NSManaged public func addToObjectives(_ values: NSSet)

    @objc(removeObjectives:)
    @NSManaged public func removeFromObjectives(_ values: NSSet)

}

extension User : Identifiable {

}
