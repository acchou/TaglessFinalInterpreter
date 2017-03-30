//: Playground - noun: a place where people can play

import Cocoa

//  Examples from this paper: http://okmij.org/ftp/tagless-final/course/lecture.pdf

//
// Page 3: "initial" embedding based on algebraic data types
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

//
// Page 4: pretty printing using initial embedding
//
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
// Page 7: expression problem
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

