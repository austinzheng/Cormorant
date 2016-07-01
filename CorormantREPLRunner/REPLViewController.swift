//
//  ViewController.swift
//  CorormantREPLRunner
//
//  Created by Austin Zheng on 6/30/16.
//  Copyright © 2016 Austin Zheng. All rights reserved.
//

import Cocoa
import Cormorant

class REPLViewController : NSViewController {

  @IBOutlet private var inputTextView: NSTextView!
  @IBOutlet private var outputTextView: NSTextView!

  private var stringBuffer = ""
  private let interpreter = Cormorant.Interpreter()

  override func viewDidLoad() {
    super.viewDidLoad()

    configureTextViews()
  }

  private func configureTextViews() {
    inputTextView.delegate = self

    // Set fonts
    inputTextView.font = NSFont(name: "Monaco", size: 12)
    outputTextView.font = NSFont(name: "Monaco", size: 12)
  }

  override func viewDidAppear() {
    super.viewDidAppear()

    view.window?.title = "Cormorant REPL"
    view.window?.makeFirstResponder(inputTextView)
  }

  // Run a single iteration of the REPL.
  private func runREPL(with input: String) {
    stringBuffer.append("\(interpreter.currentNamespaceName)-> \(input)\n")

    let result = interpreter.evaluate(form: input)
    switch result {
    case let .Success(v):
      switch interpreter.describe(form: v) {
      case let .Just(s):
        stringBuffer.append(s)
      case let .Error(err):
        stringBuffer.append(err.description)
      }

    case let .ReadFailure(f):
      stringBuffer.append(f.description)
    case let .EvalFailure(f):
      stringBuffer.append(f.description)
    }
    stringBuffer.append("\n")

    outputTextView.string = stringBuffer
  }
}

extension REPLViewController : NSTextViewDelegate {
  func textView(_ textView: NSTextView,
                shouldChangeTextIn affectedCharRange: NSRange,
                replacementString: String?) -> Bool
  {
    guard textView === inputTextView else {
      fatalError("Precondition failed")
    }
    guard
      let string = replacementString where string.unicodeScalars.count == 1,
      let first = string.unicodeScalars.first where NSCharacterSet.newlines().contains(first) else
    {
      return true
    }
    guard let text = textView.string else {
      return false
    }
    runREPL(with: text)
    // Reset text view
    textView.string = ""
    return false
  }
}

