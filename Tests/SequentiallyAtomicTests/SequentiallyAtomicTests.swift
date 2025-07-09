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
    func testBasics() throws {
        assertMacroExpansion(
            """
            class Foo {
                @SequentiallyAtomic var barInt: Int
                @SequentiallyAtomic var barBool: Bool
            }
            """,
            expandedSource: """
            class Foo {
                var barInt: Int {
                    @storageRestrictions(initializes: _barInt)
                    init(initialValue) {
                        self._barInt = Atomic(initialValue)
                    }
                    get {
                        self._barInt.load(ordering: .sequentiallyConsistent)
                    }
                    set {
                        self._barInt.store(newValue, ordering: .sequentiallyConsistent)
                    }
                }

                private let _barInt: Atomic<Int>
                var barBool: Bool {
                    @storageRestrictions(initializes: _barBool)
                    init(initialValue) {
                        self._barBool = Atomic(initialValue)
                    }
                    get {
                        self._barBool.load(ordering: .sequentiallyConsistent)
                    }
                    set {
                        self._barBool.store(newValue, ordering: .sequentiallyConsistent)
                    }
                }

                private let _barBool: Atomic<Bool>
            }
            """,
            macros: testMacros
        )
    }
}
