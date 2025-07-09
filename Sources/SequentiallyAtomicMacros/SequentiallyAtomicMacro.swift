import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct SequentiallyAtomicMacro: AccessorMacro, PeerMacro {
	public static func expansion(
		of node: AttributeSyntax,
		providingAccessorsOf declaration: some DeclSyntaxProtocol,
		in context: some MacroExpansionContext
	) throws -> [AccessorDeclSyntax] {
		guard let varDecl = declaration.as(VariableDeclSyntax.self),
			  let binding = varDecl.bindings.first,
			  let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier else {
			throw MacroError.invalidDeclaration
		}
		
		let storageName = "_\(identifier.text)"
		
		let initAccessor = AccessorDeclSyntax(
			"""
			@storageRestrictions(initializes: \(raw: storageName))
			init(initialValue) { self.\(raw: storageName) = Atomic(initialValue) }
			"""
		)
		
		let getAccessor = AccessorDeclSyntax(
			"""
			get { self.\(raw: storageName).load(ordering: .sequentiallyConsistent) }
			"""
		)
		
		let setAccessor = AccessorDeclSyntax(
			"""
			set { self.\(raw: storageName).store(newValue, ordering: .sequentiallyConsistent) }
			"""
		)
		
		return [initAccessor, getAccessor, setAccessor]
	}
	
	public static func expansion(
		of node: AttributeSyntax,
		providingPeersOf declaration: some DeclSyntaxProtocol,
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		guard let varDecl = declaration.as(VariableDeclSyntax.self),
			  let binding = varDecl.bindings.first,
			  let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier,
			  let type = binding.typeAnnotation?.type else {
			throw MacroError.invalidDeclaration
		}
		
		let storageName = "_\(identifier.text)"
		
		let storageProperty = try VariableDeclSyntax(
			"""
			private let \(raw: storageName): Atomic<\(type)>
			"""
		)
		
		return [DeclSyntax(storageProperty)]
	}
}

enum MacroError: Error {
	case invalidDeclaration
}
