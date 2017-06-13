//
//  StORM.swift
//  StORM
//
//  Created by Jonathan Guthrie on 2016-09-30.
//
//  April 6, 2017: 1.0.3, add support for storing [String] as comma delimited strings


/// Variable defining the global debug state for all classes inheriting from the StORM superclass.
/// When true, certain methods will generate a debug message under certain conditions.
public var StORMdebug = false


/// Base StORM superclass from which all Database-Connector StORM classes inherit.
/// Provides base functionality and rules.
open class StORM {
	
	/// Results container of type StORMResultSet.
	open var results		= StORMResultSet()
	
	/// connection error status of type StORMError.
	open var error			= StORMError()
	
	/// Contain last error message as string.
	open var errorMsg		= ""
	
	/// Returns the class mirror
	/// If mirroredProperties is defined, returns specified properties in this class, including ancestors.
	open var mirror: Mirror {
		get {
			let props = self.mirroredProperties()
			return  props != nil ? Mirror(self, children: props!, ancestorRepresentation: Mirror.AncestorRepresentation.generated) : Mirror(reflecting: self)
		}
	}
	
	/// The properties to include in mirroring operations
	open func mirroredProperties() -> DictionaryLiteral<String, Any>? {
		return nil;
	}
	
	/// Base empty init function.
	public init() {}
	
	/// Provides structure introspection to client methods.
	public func cols(_ offset: Int = 0) -> [(String, Any)] {
		var c = [(String, Any)]()
		var count = 0
		let mirror = self.mirror
		for child in mirror.children {
			guard let key = child.label else {
				continue
			}
			if count >= offset && !key.hasPrefix("internal_") && !key.hasPrefix("_") {
				c.append((key, type(of:child.value)))
				//c[key] = type(of:child.value)
			}
			count += 1
		}
		return c
	}
	
	/// Returns a [(String,Any)] object representation of the current object.
	/// If any object property begins with an underscore, or with "internal_" it is omitted from the response.
	public func asData(_ offset: Int = 0) -> [(String, Any)] {
		var c = [(String, Any)]()
		var count = 0
		let mirror = self.mirror
		for case let (label?, value) in mirror.children {
			if count >= offset && !label.hasPrefix("internal_") && !label.hasPrefix("_") {
				if value is [String:Any] {
					c.append((label, try! (value as! [String:Any]).jsonEncodedString()))
				} else if value is [String] {
					c.append((label, (value as! [String]).joined(separator: ",")))
				} else {
					c.append((label, value))
				}
			}
			count += 1
		}
		return c
	}
	
	/// Returns a [String:Any] object representation of the current object.
	/// If any object property begins with an underscore, or with "internal_" it is omitted from the response.
	public func asDataDict(_ offset: Int = 0) -> [String: Any] {
		var c = [String: Any]()
		var count = 0
		let mirror = self.mirror
		for case let (label?, value) in mirror.children {
			if count >= offset && !label.hasPrefix("internal_") && !label.hasPrefix("_") {
				if value is [String:Any] {
					c[label] = try! (value as! [String:Any]).jsonEncodedString()
				} else if value is [String] {
					c[label] = (value as! [String]).joined(separator: ",")
				} else {
					c[label] = value
				}
			}
			count += 1
		}
		return c
	}
	
	/// Returns a tuple of name & value of the object's key
	/// The key is determined to be it's first property, which is assumed to be the object key.
	public func firstAsKey() -> (String, Any) {
		let mirror = self.mirror
		for case let (label?, value) in mirror.children {
			return (label, value)
		}
		return ("id", "unknown")
	}
	
	/// Returns a boolean that is true if the first property in the class contains a value.
	public func keyIsEmpty() -> Bool {
		let (_, val) = firstAsKey()
		if val is Int {
			if val as! Int == 0 {
				return true
			} else {
				return false
			}
		} else {
			if (val as! String).isEmpty {
				return true
			} else {
				return false
			}
		}
	}
	
	/// The create method is designed to be overridden
	/// If not set in the chile class it will return an error of the enum value .notImplemented
	open func create() throws {
		throw StORMError.notImplemented
	}
	
}