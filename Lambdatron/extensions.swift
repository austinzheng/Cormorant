//
//  extensions.swift
//  Lambdatron
//
//  Created by Austin Zheng on 11/2/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

extension Array {
  init(_ someArray: [T], appendedItem: T) {
    var myArray = someArray
    myArray += [appendedItem]
    self = myArray
  }

  init(_ someItem: T, appendedArray: [T]) {
    var myArray = [someItem]
    myArray += appendedArray
    self = myArray
  }
}
