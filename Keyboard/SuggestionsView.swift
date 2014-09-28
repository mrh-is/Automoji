//
//  SuggestionsView.swift
//  TastyImitationKeyboard
//
//  Created by Michael on 9/27/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

class SuggestionsView: UIView {

    class SuggestionButton: UIButton {

        class var cache: [String: SuggestionButton] {
            struct Static {
                static let instance: [String: SuggestionButton] = [:]
            }
            return Static.instance
        }

        class func cellForSuggestion(suggestion: String) -> SuggestionButton {
            if let cell = cache[suggestion] {
                return cell
            }
            else {
                return SuggestionButton(suggestion: suggestion)
            }
        }

        init(suggestion: String) {
            super.init(frame: CGRectZero)
            self.setTitle(suggestion, forState: .Normal)
            self.titleLabel!.textAlignment = .Center
            self.layer.cornerRadius = 3
            self.backgroundColor = UIColor(white: 0.4, alpha: 0.5)
            self.setTranslatesAutoresizingMaskIntoConstraints(false)
            self.addConstraint(
                NSLayoutConstraint(
                    item: self,
                    attribute: .Height,
                    relatedBy: .Equal,
                    toItem: self,
                    attribute: .Width,
                    multiplier: 1,
                    constant: 0))
        }

        override var highlighted: Bool {
            didSet {
                let alpha: CGFloat = self.highlighted ? 0.7 : 0.5
                self.backgroundColor = UIColor(white: 0.4, alpha: alpha)
                self.setNeedsDisplay()
            }
        }

        required init(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    var searchString: String = "" {
        didSet {
            if countElements(searchString) == 0 {
                searchStringLabel.text = "Search for an emoji by name..."
                searchStringLabel.font = UIFont.italicSystemFontOfSize(UIFont.systemFontSize())
                searchStringLabel.textColor = UIColor.lightGrayColor()
                suggestions = []
            }
            else {
                searchStringLabel.text = searchString
                searchStringLabel.font = UIFont.systemFontOfSize(UIFont.systemFontSize())
                searchStringLabel.textColor = UIColor.blackColor()
                suggestions = emojiSuggester.emojiForString(searchString)
            }
            self.setNeedsLayout()
        }
    }
    private var suggestions: [String] = [] {
        didSet {
            self.suggestionCells = self.suggestions.map({ SuggestionButton.cellForSuggestion($0) })
            self.setNeedsLayout()
        }
    }

    private var emojiSuggester = EmojiSuggester()
    var textProxy: UIKeyInput!

    private var searchStringLabel = UILabel()
    private var suggestionsScrollView = ScrollView()
    private var suggestionCells: [SuggestionButton] = [] {
        didSet {
            var outgoingCells: [SuggestionButton] = []
            var incomingCells: [SuggestionButton] = suggestionCells
            var stayingCells: [SuggestionButton] = []

            for cell in oldValue {
                if let cellIndex = find(incomingCells, cell) {
                    stayingCells.append(cell)
                    incomingCells.removeAtIndex(cellIndex)
                }
                else {
                    outgoingCells.append(cell)
                }
            }

            for cell in outgoingCells {
                cell.removeFromSuperview()
            }

            if countElements(suggestionCells) == 0 {
                return
            }

            for (cellIndex, cell) in enumerate(suggestionCells) {
                suggestionsScrollView.addSubview(cell)
                cell.addTarget(self, action: "insertSelectedEmoji:", forControlEvents: .TouchUpInside)
                suggestionsScrollView.addConstraint(
                    NSLayoutConstraint(
                        item: cell,
                        attribute: .Height,
                        relatedBy: .Equal,
                        toItem: suggestionsScrollView,
                        attribute: .Height,
                        multiplier: 1,
                        constant: -6))
                suggestionsScrollView.addConstraint(
                    NSLayoutConstraint(
                        item: cell,
                        attribute: .Top,
                        relatedBy: .Equal,
                        toItem: suggestionsScrollView,
                        attribute: .Top,
                        multiplier: 1,
                        constant: 3))
                if cellIndex > 0 {
                    suggestionsScrollView.addConstraint(
                        NSLayoutConstraint(
                            item: cell,
                            attribute: .Left,
                            relatedBy: .Equal,
                            toItem: suggestionCells[cellIndex-1],
                            attribute: .Right,
                            multiplier: 1,
                            constant: 3))
                }
            }

            suggestionsScrollView.addConstraint(
                NSLayoutConstraint(
                    item: suggestionCells[0],
                    attribute: .Left,
                    relatedBy: .Equal,
                    toItem: suggestionsScrollView,
                    attribute: .Left,
                    multiplier: 1,
                    constant: 0))
            suggestionsScrollView.addConstraint(
                NSLayoutConstraint(
                    item: suggestionCells.last!,
                    attribute: .Right,
                    relatedBy: .Equal,
                    toItem: suggestionsScrollView,
                    attribute: .Right,
                    multiplier: 1,
                    constant: 3))

        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(searchStringLabel)
        self.addSubview(suggestionsScrollView)
        searchStringLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        suggestionsScrollView.setTranslatesAutoresizingMaskIntoConstraints(false)
        suggestionsScrollView.alwaysBounceHorizontal = true
        self.searchString = ""

        self.addConstraint(
            NSLayoutConstraint(
                item: searchStringLabel,
                attribute: .Left,
                relatedBy: .Equal,
                toItem: self,
                attribute: .Left,
                multiplier: 1,
                constant: 12))
        self.addConstraint(
            NSLayoutConstraint(
                item: searchStringLabel,
                attribute: .CenterY,
                relatedBy: .Equal,
                toItem: self,
                attribute: .CenterY,
                multiplier: 1,
                constant: 0))

        self.addConstraint(
            NSLayoutConstraint(
                item: suggestionsScrollView,
                attribute: .Left,
                relatedBy: .Equal,
                toItem: searchStringLabel,
                attribute: .Right,
                multiplier: 1,
                constant: 12))
        self.addConstraint(
            NSLayoutConstraint(
                item: suggestionsScrollView,
                attribute: .Top,
                relatedBy: .Equal,
                toItem: self,
                attribute: .Top,
                multiplier: 1,
                constant: 0))
        self.addConstraint(
            NSLayoutConstraint(
                item: suggestionsScrollView,
                attribute: .Right,
                relatedBy: .Equal,
                toItem: self,
                attribute: .Right,
                multiplier: 1,
                constant: 0))
        self.addConstraint(
            NSLayoutConstraint(
                item: suggestionsScrollView,
                attribute: .Bottom,
                relatedBy: .Equal,
                toItem: self,
                attribute: .Bottom,
                multiplier: 1,
                constant: 0))
    }

    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }

    func insertSelectedEmoji(emojiButton: SuggestionButton) {
        textProxy.insertText(emojiButton.titleForState(.Normal)!)
        searchString = ""
    }

}

class ScrollView : UIScrollView {

    override func touchesShouldCancelInContentView(view: UIView!) -> Bool {
        if view.isKindOfClass(UIButton.self) {
            return true
        }
        else {
            return super.touchesShouldCancelInContentView(view)
        }
    }

}
