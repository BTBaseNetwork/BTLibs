//
//  BTDBEntity.swift
//  BTBaseSDK
//
//  Created by Alex Chow on 2018/6/6.
//  Copyright © 2018年 btbase. All rights reserved.
//

import Foundation

public protocol BTDBEntityModel {
    static func newDefaultModel() -> BTDBEntityModel
    static func onBuildBTDBEntity(entity: BTDBEntityBuilder)
}

public class BTDBEntity {
    private(set) var properties = [BTDBPropertyBase]()
    private(set) var scheme: String
    
    init(scheme: String) {
        self.scheme = scheme
    }
    
    func addProperty(property: BTDBPropertyBase) {
        properties.append(property)
    }
}

extension BTDBEntity {
    func getProperties<T>() -> [BTDBProperty<T>] {
        return properties as! [BTDBProperty<T>]
    }
    
    func getPrimaryKey<T>() -> [BTDBProperty<T>] {
        let keys = properties.filter { $0.primaryKey }
        return keys as! [BTDBProperty<T>]
    }
    
    func getNotPrimaryKey<T>() -> [BTDBProperty<T>] {
        let keys = properties.filter { !$0.primaryKey }
        return keys as! [BTDBProperty<T>]
    }
    
    var primaryKeys: [BTDBPropertyBase] {
        return properties.filter { $0.primaryKey }
    }
    
    var notPrimaryKeys: [BTDBPropertyBase] {
        return properties.filter { !$0.primaryKey }
    }
}

public class BTDBPropertyBase {
    private(set) var propertyName: String
    private(set) var valueType: Any
    var valueTypeName: String { return "\(valueType)" }
    
    private(set) var columnName: String
    private(set) var primaryKey = false
    private(set) var isNotNull = false
    private(set) var isUnique = false
    private(set) var isAutoIncrement = false
    private(set) var defaultValue: Any?
    private(set) var checkString: String?
    private(set) var length: Int = 0
    internal init(propertyName: String, valueType: Any) {
        self.propertyName = propertyName
        self.valueType = valueType
        columnName = propertyName
    }
    
    @discardableResult
    public func hasPrimaryKey(value: Bool = true) -> BTDBPropertyBase {
        primaryKey = value
        return self
    }
    
    @discardableResult
    public func notNull(value: Bool = true) -> BTDBPropertyBase {
        isNotNull = value
        return self
    }
    
    @discardableResult
    public func autoIncrement(value: Bool = true) -> BTDBPropertyBase {
        isAutoIncrement = value
        return self
    }
    
    @discardableResult
    public func hasDefaultValue(defaultValue: Any?) -> BTDBPropertyBase {
        self.defaultValue = defaultValue
        return self
    }
    
    @discardableResult
    public func unique(value: Bool = true) -> BTDBPropertyBase {
        isUnique = value
        return self
    }
    
    @discardableResult
    public func check(limited: String?) -> BTDBPropertyBase {
        checkString = limited
        return self
    }
    
    @discardableResult
    public func length(valueLength: Int) -> BTDBPropertyBase {
        length = valueLength
        return self
    }
    
    @discardableResult
    public func bindColumn(name: String) -> BTDBPropertyBase {
        columnName = name
        return self
    }
}

public class BTDBProperty<T>: BTDBPropertyBase {
    var accessor: BTDBPropertyAccessor<T>!
    internal init(_ propertyName: String, _ valueType: Any, accessor: BTDBPropertyAccessor<T>) {
        self.accessor = accessor
        super.init(propertyName: propertyName, valueType: valueType)
    }
}

public class BTDBPropertyAccessor<T> {
    public typealias Setter = (_ model: T, _ value: Any?) -> Void
    public typealias Getter = (_ model: T) -> Any?
    internal private(set) var getValue: Getter
    internal private(set) var setValue: Setter
    init(getter: @escaping Getter, setter: @escaping Setter) {
        getValue = getter
        setValue = setter
    }
}

public class BTDBEntityBuilder {
    public init(scheme: String) {
        entity = BTDBEntity(scheme: scheme)
    }
    
    private var entity: BTDBEntity
    
    @discardableResult
    public func hasProperty<T>(_ name: String, _ type: Any, setter: @escaping BTDBPropertyAccessor<T>.Setter) -> BTDBProperty<T> {
        let defaultGetter: BTDBPropertyAccessor<T>.Getter = { model in
            let modelMirror = Mirror(reflecting: model)
            let modelP = modelMirror.children.first(where: { (label, _) -> Bool in
                label! == name
            })!
            return modelP.value
        }
        
        /* TODO: after swift upgrade reflecting features*/
        
        let defaultSetter: BTDBPropertyAccessor<T>.Setter = { model, value in
            setter(model, value)
        }
        
        let accessor = BTDBPropertyAccessor<T>.init(getter: defaultGetter, setter: defaultSetter)
        
        let pt = BTDBProperty<T>(name, type, accessor: accessor)
        entity.addProperty(property: pt)
        return pt
    }
    
    public func build<T>(_ type: T.Type) -> BTDBEntity where T: BTDBEntityModel {
        T.onBuildBTDBEntity(entity: self)
        return entity
    }
}

public class PropertySetter<T, V> {
    public typealias Setter = (_ model: T, _ value: V) -> Void
}

extension BTDBEntityBuilder {
    
    @discardableResult
    public func hasIntProperty<T>(_ name: String, setter: @escaping PropertySetter<T, Int?>.Setter) -> BTDBProperty<T> {
        return hasProperty(name, Int.self, setter: { model, value in
            setter(model, value as? Int)
        })
    }
    
    @discardableResult
    public func hasStringProperty<T>(_ name: String, setter: @escaping PropertySetter<T, String?>.Setter) -> BTDBProperty<T> {
        return hasProperty(name, String.self, setter: { model, value in
            setter(model, value as? String)
        })
    }
    
    @discardableResult
    public func hasInt32Property<T>(_ name: String, setter: @escaping PropertySetter<T, Int32?>.Setter) -> BTDBProperty<T> {
        return hasProperty(name, Int32.self, setter: { model, value in
            setter(model, value as? Int32)
        })
    }
    
    @discardableResult
    public func hasInt64Property<T>(_ name: String, setter: @escaping PropertySetter<T, Int64?>.Setter) -> BTDBProperty<T> {
        return hasProperty(name, Int64.self, setter: { model, value in
            setter(model, value as? Int64)
        })
    }
    
    @discardableResult
    public func hasDoubleProperty<T>(_ name: String, setter: @escaping PropertySetter<T, Double?>.Setter) -> BTDBProperty<T> {
        return hasProperty(name, Double.self, setter: { model, value in
            setter(model, value as? Double)
        })
    }
    
    @discardableResult
    public func hasFloatProperty<T>(_ name: String, setter: @escaping PropertySetter<T, Float?>.Setter) -> BTDBProperty<T> {
        return hasProperty(name, Float.self, setter: { model, value in
            setter(model, value as? Float)
        })
    }
    
    @discardableResult
    public func hasBoolProperty<T>(_ name: String, setter: @escaping PropertySetter<T, Bool?>.Setter) -> BTDBProperty<T> {
        return hasProperty(name, Bool.self, setter: { model, value in
            setter(model, value as? Bool)
        })
    }
    
    @discardableResult
    public func hasDateProperty<T>(_ name: String, setter: @escaping PropertySetter<T, Date?>.Setter) -> BTDBProperty<T> {
        return hasProperty(name, Date.self, setter: { model, value in
            setter(model, value as? Date)
        })
    }
    
    @discardableResult
    public func hasUintProperty<T>(_ name: String, setter: @escaping PropertySetter<T, uint?>.Setter) -> BTDBProperty<T> {
        return hasProperty(name, uint.self, setter: { model, value in
            setter(model, value as? uint)
        })
    }
    
    @discardableResult
    public func hasUInt64Property<T>(_ name: String, setter: @escaping PropertySetter<T, UInt64?>.Setter) -> BTDBProperty<T> {
        return hasProperty(name, UInt64.self, setter: { model, value in
            setter(model, value as? UInt64)
        })
    }
    
    @discardableResult
    public func hasUIntProperty<T>(_ name: String, setter: @escaping PropertySetter<T, UInt?>.Setter) -> BTDBProperty<T> {
        return hasProperty(name, UInt.self, setter: { model, value in
            setter(model, value as? UInt)
        })
    }
    
    @discardableResult
    public func hasFloat32Property<T>(_ name: String, setter: @escaping PropertySetter<T, Float32?>.Setter) -> BTDBProperty<T> {
        return hasProperty(name, Float32.self, setter: { model, value in
            setter(model, value as? Float32)
        })
    }
}
