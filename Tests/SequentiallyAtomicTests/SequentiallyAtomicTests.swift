import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(SequentiallyAtomicMacros)
import SequentiallyAtomicMacros

let testMacros: [String: Macro.Type] = [
    "SequentiallyAtomic": SequentiallyAtomicMacro.self,
]
#endif

final class SequentiallyAtomicTests: XCTestCase {
    func testMacro() throws {
        #if canImport(SequentiallyAtomicMacros)
        assertMacroExpansion(
            """
            class Foo {
                @SequentiallyAtomic var bar: Int
            }
            """,
            expandedSource: """
            class Foo {
                var bar: Int {
                    @storageRestrictions(initializes: _bar)
                    init(initialValue) {
                        self._bar = Atomic(initialValue)
                    }
                    get {
                        self._bar.load(ordering: .sequentiallyConsistent)
                    }
                    set {
                        self._bar.store(newValue, ordering: .sequentiallyConsistent)
                    }
                }

                private let _bar: Atomic<Int>
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
