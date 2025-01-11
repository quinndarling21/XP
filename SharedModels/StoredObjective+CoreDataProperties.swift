//
//  StoredObjective+CoreDataProperties.swift
//  XP
//
//  Created by Quinn Darling on 1/11/25.
//
//

import Foundation
import CoreData


extension StoredObjective {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StoredObjective> {
        return NSFetchRequest<StoredObjective>(entityName: "StoredObjective")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var order: Int32
    @NSManaged public var xpValue: Int32
    @NSManaged public var cadenceCycle: CadenceCycle?
    @NSManaged public var pathway: Pathway?
    @NSManaged public var user: User?

}

extension StoredObjective : Identifiable {

}
