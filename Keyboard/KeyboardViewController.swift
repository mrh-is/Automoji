//
//  KeyboardViewController.swift
//  Keyboard
//
//  Created by Alexei Baboulevitch on 6/9/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

class KeyboardViewController: UIInputViewController {
    
    let backspaceDelay: NSTimeInterval = 0.5
    let backspaceRepeat: NSTimeInterval = 0.05
    
    var keyboard: Keyboard
    var forwardingView: ForwardingView
    var layout: KeyboardLayout
    var heightConstraint: NSLayoutConstraint?

    var suggestionsView: SuggestionsView
    
    var currentMode: Int {
        didSet {
            setMode(currentMode)
        }
    }
    
    var backspaceActive: Bool {
        get {
            return (backspaceDelayTimer != nil) || (backspaceRepeatTimer != nil)
        }
    }
    var backspaceDelayTimer: NSTimer?
    var backspaceRepeatTimer: NSTimer?
    
    // TODO: why does the app crash if this isn't here?
    convenience override init() {
        self.init(nibName: nil, bundle: nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        self.keyboard = defaultKeyboard()
        self.forwardingView = ForwardingView(frame: CGRectZero)
        self.forwardingView.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.layout = KeyboardLayout(model: self.keyboard, superview: self.forwardingView)
        self.currentMode = 0

        self.suggestionsView = SuggestionsView(frame: CGRectZero)
        self.suggestionsView.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.suggestionsView.searchString = ""

        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        self.suggestionsView.textProxy = (self.textDocumentProxy as UITextDocumentProxy as UIKeyInput)

        self.view.addSubview(self.forwardingView)
        self.view.addSubview(self.suggestionsView)

        self.view.addConstraint(
            NSLayoutConstraint(
            item: self.suggestionsView,
            attribute: NSLayoutAttribute.Height,
            relatedBy: NSLayoutRelation.Equal,
            toItem: self.view,
            attribute: NSLayoutAttribute.Height,
            multiplier: 1/5,
            constant: 0))
        self.view.addConstraint(
            NSLayoutConstraint(
                item: self.suggestionsView,
                attribute: NSLayoutAttribute.Left,
                relatedBy: NSLayoutRelation.Equal,
                toItem: self.view,
                attribute: NSLayoutAttribute.Left,
                multiplier: 1,
                constant: 0))
        self.view.addConstraint(
            NSLayoutConstraint(
                item: self.suggestionsView,
                attribute: NSLayoutAttribute.Right,
                relatedBy: NSLayoutRelation.Equal,
                toItem: self.view,
                attribute: NSLayoutAttribute.Right,
                multiplier: 1,
                constant: 0))
        self.view.addConstraint(
            NSLayoutConstraint(
                item: self.suggestionsView,
                attribute: NSLayoutAttribute.Top,
                relatedBy: NSLayoutRelation.Equal,
                toItem: self.view,
                attribute: NSLayoutAttribute.Top,
                multiplier: 1,
                constant: 0))

        self.view.addConstraint(
            NSLayoutConstraint(
                item: self.suggestionsView,
                attribute: NSLayoutAttribute.Bottom,
                relatedBy: NSLayoutRelation.Equal,
                toItem: self.forwardingView,
                attribute: NSLayoutAttribute.Top,
                multiplier: 1,
                constant: 0))

        self.view.addConstraint(
            NSLayoutConstraint(
                item: self.forwardingView,
                attribute: NSLayoutAttribute.Left,
                relatedBy: NSLayoutRelation.Equal,
                toItem: self.view,
                attribute: NSLayoutAttribute.Left,
                multiplier: 1,
                constant: 0))
        self.view.addConstraint(
            NSLayoutConstraint(
                item: self.forwardingView,
                attribute: NSLayoutAttribute.Right,
                relatedBy: NSLayoutRelation.Equal,
                toItem: self.view,
                attribute: NSLayoutAttribute.Right,
                multiplier: 1,
                constant: 0))
        self.view.addConstraint(
            NSLayoutConstraint(
                item: self.forwardingView,
                attribute: NSLayoutAttribute.Bottom,
                relatedBy: NSLayoutRelation.Equal,
                toItem: self.view,
                attribute: NSLayoutAttribute.Bottom,
                multiplier: 1,
                constant: 0))

        // TODO: figure out where to move this
        self.layout.initialize()
        self.setupKeys()
        
        // TODO: read up on swift setter behavior on init
        self.setMode(0)
    }
    
    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        var heightConstraint = NSLayoutConstraint(
                item: self.view,
                attribute: NSLayoutAttribute.Height,
                relatedBy: NSLayoutRelation.Equal,
                toItem: nil,
                attribute: NSLayoutAttribute.NotAnAttribute,
                multiplier: 0.0,
                constant: 400)
        heightConstraint.priority = 999
        self.view.addConstraint(heightConstraint)
    }

    override func updateViewConstraints() {
        // suppresses constraint unsatisfiability on initial zero rect; mostly an issue of log spam
        // TODO: there's probably a more sensible/correct way to do this
        if CGRectIsEmpty(self.view.bounds) {
            NSLayoutConstraint.deactivateConstraints(self.layout.allConstraintObjects)
        }
        else {
            NSLayoutConstraint.activateConstraints(self.layout.allConstraintObjects)
        }
        
        super.updateViewConstraints()
    }
    
    func setupKeys() {
        for page in keyboard.pages {
            for rowKeys in page.rows { // TODO: quick hack
                for key in rowKeys {
                    var keyView = self.layout.viewForKey(key)! // TODO: check
                    
                    let showOptions: UIControlEvents = .TouchDown | .TouchDragInside | .TouchDragEnter
                    let hideOptions: UIControlEvents = .TouchUpInside | .TouchUpOutside | .TouchDragOutside
                    
                    switch key.type {
                    case Key.KeyType.KeyboardChange:
                        keyView.addTarget(self, action: "advanceToNextInputMode", forControlEvents: .TouchUpInside)
                    case Key.KeyType.Backspace:
                        let cancelEvents: UIControlEvents = UIControlEvents.TouchUpInside|UIControlEvents.TouchUpInside|UIControlEvents.TouchDragExit|UIControlEvents.TouchUpOutside|UIControlEvents.TouchCancel|UIControlEvents.TouchDragOutside
                        
                        keyView.addTarget(self, action: "backspaceDown:", forControlEvents: .TouchDown)
                        keyView.addTarget(self, action: "backspaceUp:", forControlEvents: cancelEvents)
                    case Key.KeyType.ModeChange:
                        keyView.addTarget(self, action: Selector("modeChangeTapped"), forControlEvents: .TouchUpInside)
                    default:
                        break
                    }
                    
                    if key.outputText != nil {
                        keyView.addTarget(self, action: "keyPressed:", forControlEvents: .TouchUpInside)
                    }
                    
                    if key.type == Key.KeyType.Character || key.type == Key.KeyType.Period {
                        keyView.addTarget(keyView, action: Selector("showPopup"), forControlEvents: showOptions)
                        keyView.addTarget(keyView, action: Selector("hidePopup"), forControlEvents: hideOptions)
                    }
                }
            }
        }
    }

    func keyPressed(sender: KeyboardKey) {
        UIDevice.currentDevice().playInputClick()

        if let text = self.layout.keyForView(sender)?.outputText {
//            (self.textDocumentProxy as UITextDocumentProxy as UIKeyInput).insertText(text)
            suggestionsView.searchString += text
        }
    }


    func cancelBackspaceTimers() {
        self.backspaceDelayTimer?.invalidate()
        self.backspaceRepeatTimer?.invalidate()
        self.backspaceDelayTimer = nil
        self.backspaceRepeatTimer = nil
    }
    
    func backspaceDown(sender: KeyboardKey) {
        self.cancelBackspaceTimers()
        
        // first delete
        UIDevice.currentDevice().playInputClick()
        if countElements(suggestionsView.searchString) > 0 {
            suggestionsView.searchString = suggestionsView.searchString.substringToIndex(advance(suggestionsView.searchString.endIndex, -1))
        }
        else {
            suggestionsView.textProxy.deleteBackward()
        }

        // trigger for subsequent deletes
        self.backspaceDelayTimer = NSTimer.scheduledTimerWithTimeInterval(backspaceDelay - backspaceRepeat, target: self, selector: Selector("backspaceDelayCallback"), userInfo: nil, repeats: false)
    }
    
    func backspaceUp(sender: KeyboardKey) {
        self.cancelBackspaceTimers()
    }
    
    func backspaceDelayCallback() {
        self.backspaceDelayTimer = nil
        self.backspaceRepeatTimer = NSTimer.scheduledTimerWithTimeInterval(backspaceRepeat, target: self, selector: Selector("backspaceRepeatCallback"), userInfo: nil, repeats: true)
    }
    
    func backspaceRepeatCallback() {
        if countElements(suggestionsView.searchString) > 0 {
            suggestionsView.searchString = suggestionsView.searchString.substringToIndex(advance(suggestionsView.searchString.endIndex, -1))
        }
        else {
            suggestionsView.textProxy.deleteBackward()
        }
    }
    
    func updateKeyCaps(lowercase: Bool) {
        for (model, key) in self.layout.modelToView {
            key.text = (lowercase ? model.lowercaseKeyCap : model.keyCap)
        }
    }
    
    func modeChangeTapped() {
        self.currentMode = ((self.currentMode + 1) % 3)
    }
    
    func setMode(mode: Int) {
        for (pageIndex, page) in enumerate(self.keyboard.pages) {
            for (rowIndex, row) in enumerate(page.rows) {
                for (keyIndex, key) in enumerate(row) {
                    if self.layout.modelToView[key] != nil {
                        var keyView = self.layout.modelToView[key]
                        keyView?.hidden = (pageIndex != mode)
                    }
                }
            }
        }
    }
}
