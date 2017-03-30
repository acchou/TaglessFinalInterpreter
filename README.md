# Tagless Final Interpreter

This project uses Swift as a metalanguage to explore Tagless Final
Interpreters (TFI) and Object Algebras.

Tagless final interpreters are a way of embedding and interpreter within
another programming language, called the metalanguage. This can be useful for
creating a Domain-Specific Languages (DSL) for expressing programs that are at
a higher level of abstraction more suited to a particular knowledge domain.

Usually DSLs are implemented in languages like Haskell or OCaml which provide
Hindley-Milner style type inference and sum types (variants). TFI provides a
way of implementing a DSL using only generics, and is closely related to
[Object Algebras][]. Object Algebras can be implemented in mainstream
programming languages like Java and C#, though there is more to TFI than the
core object algebra.

This repository is a playground for playing with the examples from this course
lecture on tagless final interpreters:
http://okmij.org/ftp/tagless-final/course/lecture.pdf.

## Object Algebras

Are Swift's generics powerful enough to express Object Algebras? To answer
this question let's back up and take a look at the sum type, which is the
standard way of defining data variants in ML-derived languages like Haskell
and OCaml. In Swift, `indirect enum` plays the role of recursive sum type, and
fairly powerful pattern matching can be performed on enum values, even deeply
nested. So, for example, here's a simple DSL with integer literals, negation,
and addition:

```swift
indirect enum Exp {
    case Lit(Int)
    case Neg(Exp)
    case Add(Exp, Exp)
}

func eval(_ e: Exp) -> Int {
    switch e {
    case let .Lit(n): return n
    case let .Neg(e): return -eval(e)
    case let .Add(e1, e2): return eval(e1) + eval(e2)
    }
}

let ti1: Exp = .Add(.Lit(8), .Neg(.Add (.Lit(1), .Lit(2))))
eval(ti1)  // -> 5
```

Alternatively, we can define an object algebra signature as a protocol with an
associated type and "expression constructors" which are just functions that
return a value of the associated type:

```swift
protocol ExpSym {
    associatedtype repr
    func lit(_ n: Int) -> repr
    func neg(_ e: repr) -> repr
    func add(_ e1: repr, _ e2: repr) -> repr
}
```

An object algebra is just a class that implements the object algebra signature
protocol:

```swift
class IntExpSym: ExpSym {
    typealias repr = Int
    func lit(_ n: Int) -> repr { return n }
    func neg(_ e: repr) -> repr { return -e }
    func add(_ e1: repr, _ e2: repr) -> repr { return e1 + e2 }
}
```

We can then use `IntExpSym` directly to create values, but that would defeat
one of the main points of using object algebras, which is to solve the
[Expression Problem][]. Instead, let's write generic functions that take an
argument that is constrained by the `ExpSym` protocol:

```swift
func tf1<E: ExpSym>(_ v: E) -> E.repr {
    return v.add(v.lit(8), v.neg(v.add(v.lit(1), v.lit(2))))
}

let tf2: Int = tf1(IntExpSym())  // -> 5
```

In the expression problem there are two dimensions of extensibility: adding
new data types and adding new operations. Let's take a look at how object
algebras can be used to provide these two types of extensibility in Swift
without changing prior existing code.

To add a new operation, we can create a new class that implements te `ExpSym`
protocol:

```swift
class StringExpSym: ExpSym {
    typealias repr = String
    func lit(_ n: Int) -> repr { return "\(n)" }
    func neg(_ e: repr) -> repr { return "(- \(e))" }
    func add(_ e1: repr, _ e2: repr) -> repr { return "(\(e1) + \(e2))" }
}

let ts2: String = tf1(StringExpSym())  // -> "(8 + (- (1 + 2)))"
```

We didn't need to modify `ExpSym` or `IntExpSym` to do this, so it's fully
backward compatible. It's also statically typesafe.

To add a new expression type, we can create a new protocol:

```swift
protocol MulSym: ExpSym {
    func mul(_ e1: repr, _ e2: repr) -> repr
}
```

To implement the operations on this new protocol, we inherit from the class
implementing the original object algebra and add protocol conformance for the
new expression type:

```swift
class IntMulSym: IntExpSym, MulSym {
    func mul(_ e1: Int, _ e2: Int) -> Int {
        return e1 * e2
    }
}

class StringMulSym: StringExpSym, MulSym {
    func mul(_ e1: String, _ e2: String) -> String {
        return "(\(e1) * \(e2))"
    }
}
```

Now we can write:

```swift
func tfm1<E: MulSym>(_ v: E) -> E.repr {
    return v.add(v.lit(8), v.neg(v.mul(v.lit(1), v.lit(2))))
}

tfm1(StringMulSym())  // -> "(8 + (- (1 * 2)))"
```

Again, we didn't need to modify any existing code to implementing this
addition of a new data type, and it's statically typesafe.

What about protocol extensions? Protocol extensions require a default function
implementation, consider:

```swift
extension ExpSym {
    func mul(_ e1: repr, _ e2: repr) -> repr {
        // ??
    }
}
```

We could do several things in the body here. We could make it a fatal error to
call the default implementation, but this turns bugs into runtime errors
instead of being statically checked by the compiler. We could use other
functions from `ExpSym` to implement it, but that doesn't always work because
the new value may not be expressible in terms of the others. In short, there's
nothing wrong with using protocol extensions along with object algebra
signatures, but they are solving different problems. Protocol extensions are
useful for adding new functionality to existing protocols, but they cannot add
new "expression variants" without resorting to dynamic checks.

The object algebra pattern can be used to create new protocols that have
additional expressions, which extend the original protocol in ways that
protocol extensions cannot.

[Object Algebras]: https://www.cs.utexas.edu/~wcook/Drafts/2012/ecoop2012.pdf
[Expression Problem]: http://i.cs.hku.hk/~bruno/oa/
