//: Playground - noun: a place where people can play

import Cocoa

//  Examples from this paper: http://okmij.org/ftp/tagless-final/course/lecture.pdf

//
// Section 2.1: "initial" embedding based on algebraic data types
//
indirect enum Exp {
    case Lit(Int)
    case Neg(Exp)
    case Add(Exp, Exp)
}

let ti1: Exp = .Add(.Lit(8), .Neg(.Add (.Lit(1), .Lit(2))))

func eval(_ e: Exp) -> Int {
    switch e {
    case let .Lit(n): return n
    case let .Neg(e): return -eval(e)
    case let .Add(e1, e2): return eval(e1) + eval(e2)
    }
}

let result1 = eval(ti1)

// pretty printing using initial embedding
func view(_ e: Exp) -> String {
    switch e {
    case let .Lit(n): return "\(n)"
    case let .Neg(e): return "(- \(view(e)))"
    case let .Add(e1, e2): return "(\(view(e1)) + \(view(e2)))"
    }
}

let str1 = view(ti1)

protocol ExpSym {
    associatedtype repr
    func lit(_ n: Int) -> repr
    func neg(_ e: repr) -> repr
    func add(_ e1: repr, _ e2: repr) -> repr
}

class IntExpSym: ExpSym {
    typealias repr = Int
    func lit(_ n: Int) -> repr { return n }
    func neg(_ e: repr) -> repr { return -e }
    func add(_ e1: repr, _ e2: repr) -> repr { return e1 + e2 }
}

class StringExpSym: ExpSym {
    typealias repr = String
    func lit(_ n: Int) -> repr { return "\(n)" }
    func neg(_ e: repr) -> repr { return "(- \(e))" }
    func add(_ e1: repr, _ e2: repr) -> repr { return "(\(e1) + \(e2))" }
}

func tf1<E: ExpSym>(_ v: E) -> E.repr {
    return v.add(v.lit(8), v.neg(v.add(v.lit(1), v.lit(2))))
}

let tf2: Int = tf1(IntExpSym())
let ts2: String = tf1(StringExpSym())

//
// Section 2.2: expression problem
//


// Using Swift's protocol extensions doesn't work naturally; we don't have a specific implementation of mul here.

//extension ExpSym {
//    func mul(_ e1: repr, _ e2: repr) -> repr {
//        ...
//    }
//}

// Instead we create a new protocol to add mul
protocol MulSym: ExpSym {
    func mul(_ e1: repr, _ e2: repr) -> repr
}

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

func tfm1<E: MulSym>(_ v: E) -> E.repr {
    return v.add(v.lit(8), v.neg(v.mul(v.lit(1), v.lit(2))))
}

func tfm2<E: MulSym>(_ v: E) -> E.repr {
    return v.mul(v.lit(7), tf1(v))
}

let tfmi1 = tfm1(IntMulSym())
let tfms1 = tfm1(StringMulSym())

//
// Section 2.3: de-serialization
//

// Oddly, for a paper that is about the final embedding, the author chose to describe Tree as an initial embedding.
indirect enum Tree {
    case Leaf(String)
    case Node(String, [Tree])
}

extension Tree: CustomStringConvertible {
    var description: String {
        switch self {
        case let .Leaf(str): return "Leaf '\(str)'"
        case let .Node(str, subtrees):
            let showSubtrees = subtrees.map { $0.description }.joined(separator: ", ")
            return "Node '\(str)' [\(showSubtrees)]"
        }
    }
}

class TreeSym: ExpSym {
    typealias repr = Tree

    func lit(_ n: Int) -> Tree {
        return .Node("Lit", [.Leaf(String(n))])
    }

    func neg(_ e: Tree) -> Tree {
        return .Node("Neg", [e])
    }

    func add(_ e1: Tree, _ e2: Tree) -> Tree {
        return .Node("Add", [e1, e2])
    }
}

let tf1_tree = tf1(TreeSym())
tf1_tree.description

func fromTree<E: ExpSym>(_ tree: Tree) -> (_ e: E) -> E.repr? {
    return { e in
        switch tree {
        case let .Node("Lit", subtree) where subtree.count == 1:
            if case let .Leaf(str) = subtree[0], let n = Int(str) {
                return e.lit(n)
            }
            return nil
        case let .Node("Neg", subtree) where subtree.count == 1:
            if let subexpr = fromTree(subtree[0])(e) {
                return e.neg(subexpr)
            }
            return nil
        case let .Node("Add", subtree) where subtree.count == 2:
            if let a = fromTree(subtree[0])(e), let b = fromTree(subtree[1])(e) {
                return e.add(a, b)
            }
            return nil
        default:
            return nil
        }
    }
}

// The following line shows that a polymorphic function can't be returned from a function. The returned function must have a concrete type inferred.
// let tree_fn = fromTree(tf1_tree)

let tf1_string = fromTree(tf1_tree)(StringExpSym())

let tf1_eval = fromTree(tf1_tree)(IntExpSym())

class DuplicateSym<E1, E2>: ExpSym where E1: ExpSym, E2: ExpSym {
    typealias R1 = E1.repr
    typealias R2 = E2.repr
    typealias repr = (R1, R2)
    let e1: E1
    let e2: E2

    init(_ e1: E1, _ e2: E2) {
        self.e1 = e1
        self.e2 = e2
    }

    func lit(_ n: Int) -> (R1, R2) {
        return (e1.lit(n), e2.lit(n))
    }

    func neg(_ e: (R1, R2)) -> (R1, R2) {
        return (e1.neg(e.0), e2.neg(e.1))
    }

    func add(_ e1: (R1, R2), _ e2: (R1, R2)) -> (R1, R2) {
        return (self.e1.add(e1.0, e2.0), self.e2.add(e1.1, e2.1))
    }
}

func >>=<E1: ExpSym, E2: ExpSym>(e1: E1, e2: E2) -> DuplicateSym<E1,E2> {
    return DuplicateSym(e1, e2)
}

let multiSym = IntExpSym() >>= StringExpSym() >>= TreeSym()
if let (val, (str, tree)) = fromTree(tf1_tree)(multiSym) {
    print("val: \(val)")
    print("str: \(str)")
    print("tree: \(tree)")
}


// Adding mult to deserialization

class TreeMulSym: TreeSym, MulSym {
    func mul(_ e1: Tree, _ e2: Tree) -> Tree {
        return .Node("Mul", [e1, e2])
    }
}

func fromMulTree<E: MulSym>(_ tree: Tree) -> (_ e: E) -> E.repr? {
    return { e in
        if case let .Node("Mul", subtree) = tree, subtree.count == 2 {
            if let a = fromTree(subtree[0])(e), let b = fromTree(subtree[1])(e) {
                return e.mul(a, b)
            }
        }
        return fromTree(tree)(e)
    }
}

class DuplicateMulSym<E1, E2>: DuplicateSym<E1,E2>, MulSym where E1: MulSym, E2: MulSym {
    func mul(_ e1: (R1, R2), _ e2: (R1, R2)) -> (R1, R2) {
        return (self.e1.mul(e1.0, e2.0), self.e2.mul(e1.1, e2.1))
    }
}

func tm1<E: MulSym>(_ e: E) -> E.repr {
    return e.mul(e.add(e.lit(42), e.neg(e.lit(10))), e.lit(7))
}

let tmtree = tm1(TreeMulSym())
let multiMulSym = DuplicateMulSym(IntMulSym(), DuplicateMulSym(StringMulSym(), TreeMulSym()))
if let (val, (str, tree)) = fromMulTree(tmtree)(multiMulSym) {
    print("val: \(val)")
    print("str: \(str)")
    print("tree: \(tree)")
}

