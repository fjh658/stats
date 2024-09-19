//
//  extensions.swift
//  Kit
//
//  Created by Serhiy Mytrovtsiy on 10/04/2020.
//  Using Swift 5.0.
//  Running on macOS 10.15.
//
//  Copyright © 2020 Serhiy Mytrovtsiy. All rights reserved.
//

import Cocoa

extension String: @retroactive Error {}
extension String: @retroactive LocalizedError {
    public var errorDescription: String? { return self }
    
    public var digits: String {
        return components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    }
    
    public func widthOfString(usingFont font: NSFont) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: fontAttributes)
        return size.width
    }
    
    public func condenseWhitespace() -> String {
        let components = self.components(separatedBy: .whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.joined(separator: " ")
    }
    
    public func findAndCrop(pattern: String) -> (cropped: String, remain: String) {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSRange(self.startIndex..., in: self)
            
            if let match = regex.firstMatch(in: self, options: [], range: range) {
                if let range = Range(match.range, in: self) {
                    let cropped = String(self[range]).trimmingCharacters(in: .whitespaces)
                    let remaining = self.replacingOccurrences(of: cropped, with: "", options: .regularExpression).trimmingCharacters(in: .whitespaces)
                    return (cropped, remaining)
                }
            }
        } catch {
            print("Error creating regex: \(error.localizedDescription)")
        }
        
        return ("", self)
    }
    
    public func find(pattern: String) -> String {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let stringRange = NSRange(location: 0, length: self.utf16.count)
            
            if let searchRange = regex.firstMatch(in: self, options: [], range: stringRange) {
                let start = self.index(self.startIndex, offsetBy: searchRange.range.lowerBound)
                let end = self.index(self.startIndex, offsetBy: searchRange.range.upperBound)
                let value  = String(self[start..<end]).trimmingCharacters(in: .whitespaces)
                return value.trimmingCharacters(in: .whitespaces)
            }
        } catch {}
        
        return ""
    }
    
    public var trimmed: String {
        var buf = [UInt8]()
        var trimming = true
        for c in self.utf8 {
            if trimming && c < 33 { continue }
            trimming = false
            buf.append(c)
        }
        
        while let last = buf.last, last < 33 {
            buf.removeLast()
        }
        
        buf.append(0)
        return String(cString: buf)
    }
    
    public func matches(_ regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
    }
    
    public func removedRegexMatches(pattern: String, replaceWith: String = "") -> String {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
            let range = NSRange(location: 0, length: self.count)
            return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: replaceWith)
        } catch {
            return self
        }
    }
    
    func removingWhitespaces() -> String {
        return components(separatedBy: .whitespaces).joined()
    }
}

public extension DispatchSource.MemoryPressureEvent {
    func pressureColor() -> NSColor {
        switch self {
        case .normal:
            return NSColor.systemGreen
        case .warning:
            return NSColor.systemYellow
        case .critical:
            return NSColor.systemRed
        default:
            return .controlAccentColor
        }
    }
}

public extension Double {
    func roundTo(decimalPlaces: Int) -> String {
        return NSString(format: "%.\(decimalPlaces)f" as NSString, self) as String
    }
    
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
    
    func usageColor(zones: colorZones = (0.6, 0.8), reversed: Bool = false) -> NSColor {
        let firstColor: NSColor = NSColor.systemBlue
        let secondColor: NSColor = NSColor.orange
        let thirdColor: NSColor = NSColor.red
        
        if reversed {
            switch self {
            case 0...zones.orange:
                return thirdColor
            case zones.orange...zones.red:
                return secondColor
            default:
                return firstColor
            }
        } else {
            switch self {
            case 0...zones.orange:
                return firstColor
            case zones.orange...zones.red:
                return secondColor
            default:
                return thirdColor
            }
        }
    }
    
    func batteryColor(color: Bool = false, lowPowerMode: Bool? = nil) -> NSColor {
        if let mode = lowPowerMode, mode {
            return NSColor.systemOrange
        }
        
        switch self {
        case 0.2...0.4:
            if !color {
                return NSColor.textColor
            }
            return NSColor.systemOrange
        case 0.4...1:
            if self == 1 {
                return NSColor.textColor
            }
            if !color {
                return NSColor.textColor
            }
            return NSColor.systemGreen
        default:
            return NSColor.systemRed
        }
    }
    
    func secondsToHoursMinutesSeconds() -> (Int, Int) {
        let mins = (self.truncatingRemainder(dividingBy: 3600)) / 60
        return (Int(self / 3600), Int(mins))
    }
    
    func printSecondsToHoursMinutesSeconds(short: Bool = false) -> String {
        let (h, m) = self.secondsToHoursMinutesSeconds()
        
        if self == 0 || h < 0 || m < 0 {
            return "n/a"
        }
        
        let minutes = m > 9 ? "\(m)" : "0\(m)"
        
        if short {
            return "\(h):\(minutes)"
        }
        
        if h == 0 {
            return "\(minutes)min"
        } else if m == 0 {
            return "\(h)h"
        }
        
        return "\(h)h \(minutes)min"
    }
}

public extension NSView {
    var isDarkMode: Bool {
        switch effectiveAppearance.name {
        case .darkAqua, .vibrantDark, .accessibilityHighContrastDarkAqua, .accessibilityHighContrastVibrantDark:
            return true
        default:
            return false
        }
    }
    
    func toggleSettingRow(title: String, action: Selector, state: Bool) -> NSView {
        let view: NSStackView = NSStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: Constants.Settings.row).isActive = true
        view.orientation = .horizontal
        view.alignment = .centerY
        view.distribution = .fill
        view.spacing = 0
        
        let titleField: NSTextField = LabelField(frame: NSRect(x: 0, y: 0, width: 0, height: 0), title)
        titleField.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        titleField.textColor = .textColor
        
        let state: NSControl.StateValue = state ? .on : .off
        var toggle: NSControl = NSControl()
        if #available(OSX 10.15, *) {
            let switchButton = NSSwitch()
            switchButton.state = state
            switchButton.action = action
            switchButton.target = self
            
            toggle = switchButton
        } else {
            let button: NSButton = NSButton()
            button.setButtonType(.switch)
            button.state = state
            button.title = ""
            button.action = action
            button.isBordered = false
            button.isTransparent = false
            button.target = self
            button.wantsLayer = true
            
            toggle = button
        }
        
        view.addArrangedSubview(titleField)
        view.addArrangedSubview(NSView())
        view.addArrangedSubview(toggle)
        
        return view
    }
    
    func selectSettingsRow(title: String, action: Selector, items: [KeyValue_p], selected: String) -> NSView {
        let view = NSStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: Constants.Settings.row).isActive = true
        view.orientation = .horizontal
        view.alignment = .centerY
        view.distribution = .fill
        view.spacing = 0
        
        let titleField: NSTextField = LabelField(frame: NSRect(x: 0, y: 0, width: 0, height: 0), title)
        titleField.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        titleField.textColor = .textColor
        
        let select: NSPopUpButton = selectView(action: action, items: items, selected: selected)
        select.sizeToFit()
        
        view.addArrangedSubview(titleField)
        view.addArrangedSubview(NSView())
        view.addArrangedSubview(select)
        
        return view
    }
    
    func selectView(action: Selector, items: [KeyValue_p], selected: String) -> NSPopUpButton {
        let select: NSPopUpButton = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 50, height: 28))
        select.target = self
        select.action = action
        
        let menu = NSMenu()
        items.forEach { (item) in
            if item.key.contains("separator") {
                menu.addItem(NSMenuItem.separator())
            } else {
                let interfaceMenu = NSMenuItem(title: localizedString(item.value), action: nil, keyEquivalent: "")
                interfaceMenu.representedObject = item.key
                menu.addItem(interfaceMenu)
                if selected == item.key {
                    interfaceMenu.state = .on
                }
            }
        }
        select.menu = menu
        
        return select
    }
    
    func switchView(action: Selector, state: Bool) -> NSSwitch {
        let s = NSSwitch()
        s.heightAnchor.constraint(equalToConstant: 25).isActive = true
        s.controlSize = .mini
        s.state = state ? .on : .off
        s.action = action
        s.target = self
        return s
    }
    
    func buttonIconView(_ action: Selector, icon: NSImage) -> NSButton {
        let button = NSButton()
        button.heightAnchor.constraint(equalToConstant: 22).isActive = true
        button.bezelStyle = .regularSquare
        button.translatesAutoresizingMaskIntoConstraints = false
        button.imageScaling = .scaleNone
        button.image = icon
        button.contentTintColor = .labelColor
        button.isBordered = false
        button.action = action
        button.target = self
        button.focusRingType = .none
        return button
    }
    
    func textView(_ value: String) -> NSTextField {
        let field: NSTextField = TextView()
        field.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        field.stringValue = value
        field.isSelectable = true
        return field
    }
    
    func sliderView(action: Selector, value: Int, initialValue: String, min: Double = 1, max: Double = 100, valueWidth: CGFloat = 40) -> NSView {
        let view: NSStackView = NSStackView()
        view.orientation = .horizontal
        view.widthAnchor.constraint(equalToConstant: 195).isActive = true
        
        let valueField: NSTextField = LabelField(initialValue)
        valueField.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        valueField.textColor = .textColor
        valueField.alignment = .center
        valueField.widthAnchor.constraint(equalToConstant: valueWidth).isActive = true
        
        let slider = NSSlider()
        slider.controlSize = .small
        slider.minValue = min
        slider.maxValue = max
        slider.intValue = Int32(value)
        slider.target = self
        slider.isContinuous = true
        slider.action = action
        slider.sizeToFit()
        
        view.addArrangedSubview(slider)
        view.addArrangedSubview(valueField)
        
        return view
    }
}

public class NSButtonWithPadding: NSButton {
    public var horizontalPadding: CGFloat = 0
    public var verticalPadding: CGFloat = 0
    
    public override var intrinsicContentSize: NSSize {
        var size = super.intrinsicContentSize
        size.width += self.horizontalPadding
        size.height += self.verticalPadding
        return size
    }
}

public class TextView: NSTextField {
    public override init(frame: NSRect = .zero) {
        super.init(frame: frame)
        
        self.isEditable = false
        self.isSelectable = false
        self.isBezeled = false
        self.wantsLayer = true
        self.textColor = .labelColor
        self.backgroundColor = .clear
        self.canDrawSubviewsIntoLayer = true
        self.alignment = .natural
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public extension OperatingSystemVersion {
    func getFullVersion(separator: String = ".") -> String {
        return "\(majorVersion)\(separator)\(minorVersion)\(separator)\(patchVersion)"
    }
}

extension URL {
    func checkFileExist() -> Bool {
        return FileManager.default.fileExists(atPath: self.path)
    }
}

public extension NSColor {
    func grayscaled() -> NSColor {
        guard let space = CGColorSpace(name: CGColorSpace.extendedGray),
              let cg = self.cgColor.converted(to: space, intent: .perceptual, options: nil),
              let color = NSColor.init(cgColor: cg) else {
            return self
        }
        return color
    }
}

public class FlippedStackView: NSStackView {
    public override var isFlipped: Bool { return true }
}

public class ScrollableStackView: NSView {
    public var stackView: NSStackView = FlippedStackView()
    
    private let clipView: NSClipView = NSClipView()
    private let scrollView: NSScrollView = NSScrollView()
    
    public var scrollWidth: CGFloat? {
        self.scrollView.verticalScroller?.frame.size.width
    }
    
    public init(frame: NSRect = NSRect.zero, orientation: NSUserInterfaceLayoutOrientation = .vertical) {
        super.init(frame: frame)
        
        self.clipView.drawsBackground = false
        
        self.stackView.orientation = orientation
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        if orientation == .vertical {
            self.scrollView.hasVerticalScroller = true
            self.scrollView.hasHorizontalScroller = false
            self.scrollView.autohidesScrollers = true
            self.scrollView.horizontalScrollElasticity = .none
        } else {
            self.scrollView.hasVerticalScroller = false
            self.scrollView.hasHorizontalScroller = true
            self.scrollView.autohidesScrollers = true
            self.scrollView.verticalScrollElasticity = .none
        }
        self.scrollView.drawsBackground = false
        self.scrollView.contentView = self.clipView
        self.scrollView.documentView = self.stackView
        
        self.addSubview(self.scrollView)
        
        NSLayoutConstraint.activate([
            self.scrollView.leftAnchor.constraint(equalTo: self.leftAnchor),
            self.scrollView.rightAnchor.constraint(equalTo: self.rightAnchor),
            self.scrollView.topAnchor.constraint(equalTo: self.topAnchor),
            self.scrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            
            self.stackView.leftAnchor.constraint(equalTo: self.clipView.leftAnchor),
            self.stackView.topAnchor.constraint(equalTo: self.clipView.topAnchor)
        ])
        
        if orientation == .vertical {
            self.stackView.rightAnchor.constraint(equalTo: self.clipView.rightAnchor).isActive = true
        } else {
            self.stackView.bottomAnchor.constraint(equalTo: self.clipView.bottomAnchor).isActive = true
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// https://stackoverflow.com/a/54492165
extension NSTextView {
    override open func performKeyEquivalent(with event: NSEvent) -> Bool {
        let commandKey = NSEvent.ModifierFlags.command.rawValue
        let commandShiftKey = NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue
        if event.type == NSEvent.EventType.keyDown {
            if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == commandKey {
                switch event.charactersIgnoringModifiers! {
                case "x":
                    if NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: self) { return true }
                case "c":
                    if NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: self) { return true }
                case "v":
                    if NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: self) { return true }
                case "z":
                    if NSApp.sendAction(Selector(("undo:")), to: nil, from: self) { return true }
                case "a":
                    if NSApp.sendAction(#selector(NSResponder.selectAll(_:)), to: nil, from: self) { return true }
                default:
                    break
                }
            } else if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == commandShiftKey {
                if event.charactersIgnoringModifiers == "Z" {
                    if NSApp.sendAction(Selector(("redo:")), to: nil, from: self) { return true }
                }
            }
        }
        return super.performKeyEquivalent(with: event)
    }
}

public extension Data {
    var socketAddress: sockaddr {
        return withUnsafeBytes { $0.load(as: sockaddr.self) }
    }
}

public extension Date {
    func convertToTimeZone(_ timeZone: TimeZone) -> Date {
        return addingTimeInterval(TimeInterval(timeZone.secondsFromGMT(for: self) - TimeZone.current.secondsFromGMT(for: self)))
    }
    
    func currentTimeSeconds() -> Int {
        return Int(self.timeIntervalSince1970)
    }
}

public extension TimeZone {
    init(fromUTC: String) {
        if fromUTC == "local" {
            self = TimeZone.current
            return
        }
        
        let arr = fromUTC.split(separator: ":")
        guard !arr.isEmpty else {
            self = TimeZone.current
            return
        }
        
        var secondsFromGMT = 0
        if arr.indices.contains(0), let h = Int(arr[0]) {
            secondsFromGMT += h*3600
        }
        if arr.indices.contains(1), let m = Int(arr[1]) {
            if secondsFromGMT < 0 {
                secondsFromGMT -= m*60
            } else {
                secondsFromGMT += m*60
            }
        }
        
        if let tz = TimeZone(secondsFromGMT: secondsFromGMT) {
            self = tz
        } else {
            self = TimeZone.current
        }
    }
}

extension CGFloat {
    func roundedUpToNearestTen() -> CGFloat {
        return ceil(self / 10) * 10
    }
}
