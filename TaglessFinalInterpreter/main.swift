//
//  main.swift
//  TaglessFinalInterpreter
//
//  Examples from this paper: http://okmij.org/ftp/tagless-final/course/lecture.pdf
//
//  Created by Andy Chou on 3/29/17.
//  Copyright © 2017 Andy Chou. All rights reserved.
//

import Foundation

// Page 3
indirect enum Exp {
    case Lit(Int)
    case Neg(Exp)
    case Add(Exp, Exp)
}

let ti1: Exp = .Add(.Lit(8), .Neg(.Add (.Lit(1), .Lit(2))))

