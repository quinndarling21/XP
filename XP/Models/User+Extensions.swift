import Foundation
import CoreData

extension User {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        self.id = UUID()
    }
} 