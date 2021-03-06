//
//  BTDBDbSet.swift
//  BTBaseSDK
//
//  Created by Alex Chow on 2018/6/6.
//  Copyright © 2018年 btbase. All rights reserved.
//

import Foundation
public class BTDBTableSet<M> where M: BTDBEntityModel {
    private(set) var dbContext: BTDBContext
    private(set) var entity: BTDBEntity
    
    public var tableName: String {
        return self.entity.scheme
    }
    
    init(dbContext: BTDBContext, scheme: String) {
        self.dbContext = dbContext
        self.entity = BTDBEntityBuilder(scheme: scheme).build(M.self)
    }
    
    public func createTable() {}
    public func tableExists() -> Bool { return false }
    
    public func dropTable() {}
    
    public func add(model: M) -> M { return model }
    
    public func query(sql: String, parameters: [Any]?) -> [M] { return [] }
    
    public func update(model: M, upsert: Bool) -> M { return model }
    public func executeUpdateSql(sql: String, parameters: [Any]?) {}
    
    public func delete(model: M) -> Bool { return false }
    public func executeDeleteSql(sql: String, parameters: [Any]?) {}
}
