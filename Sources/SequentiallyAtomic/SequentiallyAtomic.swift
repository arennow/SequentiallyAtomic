// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(accessor)
@attached(peer, names: prefixed(_))
public macro SequentiallyAtomic() = #externalMacro(module: "SequentiallyAtomicMacros", type: "SequentiallyAtomicMacro")
