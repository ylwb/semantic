public enum JSON {
	case Number(Double)
	case Boolean(Bool)
	case String(Swift.String)
	case Array([Doubt.JSON])
	case Dictionary([Swift.String:Doubt.JSON])
	case Null

	public var number: Double? {
		if case let .Number(d) = self { return d }
		return nil
	}

	public var boolean: Bool? {
		if case let .Boolean(b) = self { return b }
		return nil
	}

	public var string: Swift.String? {
		if case let .String(s) = self { return s }
		return nil
	}

	public var array: [Doubt.JSON]? {
		if case let .Array(a) = self { return a }
		return nil
	}

	public var dictionary: [Swift.String:Doubt.JSON]? {
		if case let .Dictionary(d) = self { return d }
		return nil
	}

	public var isNull: Bool {
		if case .Null = self { return true }
		return false
	}

	public static let JSON: Prism<AnyObject, Doubt.JSON> = Prism(forward: toJSON, backward: toAnyObject)

	public static let number: Prism<Doubt.JSON, Double> = Prism(forward: { $0.number }, backward: { .Number($0) })
	public static let boolean: Prism<Doubt.JSON, Bool> = Prism(forward: { $0.boolean }, backward: { .Boolean($0) })
	public static let string: Prism<Doubt.JSON, Swift.String> = Prism(forward: { $0.string }, backward: { .String($0) })
	public static let array: Prism<Doubt.JSON, [Doubt.JSON]> = Prism(forward: { $0.array }, backward: { .Array($0) })
	public static let dictionary: Prism<Doubt.JSON, [Swift.String:Doubt.JSON]> = Prism(forward: { $0.dictionary }, backward: { .Dictionary($0) })
}

private func toJSON(object: AnyObject) -> JSON? {
	struct E: ErrorType {}
	func die<T>() throws -> T {
		throw E()
	}
	do {
		switch object {
		case let n as Double:
			return JSON.Number(n)
		case let b as Bool:
			return JSON.Boolean(b)
		case let s as String:
			return JSON.String(s)
		case let a as [AnyObject]:
			return JSON.Array(try a.map { try toJSON($0) ?? die() })
		case let d as [String:AnyObject]:
			return JSON.Dictionary(Dictionary(elements: try d.map { ($0, try toJSON($1) ?? die()) }))
		case is NSNull:
			return JSON.Null
		default:
			return nil
		}
	} catch { return nil }
}

private func toAnyObject(json: JSON) -> AnyObject {
	switch json {
	case let .Number(n):
		return n
	case let .Boolean(b):
		return b
	case let .String(s):
		return s
	case let .Array(a):
		return a.map(toAnyObject)
	case let .Dictionary(d):
		return Dictionary(elements: d.map { ($0, toAnyObject($1)) })
	case .Null:
		return NSNull()
	}
}


import Foundation
