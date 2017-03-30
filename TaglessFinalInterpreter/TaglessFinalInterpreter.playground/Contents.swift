//: Playground - noun: a place where people can play

import Cocoa

//  Examples from this paper: http://okmij.org/ftp/tagless-final/course/lecture.pdf

// Page 3
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

