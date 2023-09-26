// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

// MARK: - INT

public extension Int {
  /// Returns larger numbers in K(thousands) and M(millions) friendly format.
  /// Example : 123 456 -> 123K, 3000 -> 3k, 3400 -> 3.4K
  var kFormattedNumber: String {
       let numberFormatter = NumberFormatter()
       numberFormatter.numberStyle = .decimal

       if self >= 1000 && self < 10000 {
           let formattedNumber = Double(self) / 1000.0
           numberFormatter.maximumFractionDigits = 1
           return "\(numberFormatter.string(from: NSNumber(value: formattedNumber)) ?? "")K"
       }

       if self >= 10000 && self < 1000000 {
           let formattedNumber = Double(self) / 1000.0
           return "\(numberFormatter.string(from: NSNumber(value: formattedNumber)) ?? "")K"
       }

       if self >= 1000000 && self < 10000000 {
           let formattedNumber = Double(self) / 1000000.0
           numberFormatter.maximumFractionDigits = 1
           return "\(numberFormatter.string(from: NSNumber(value: formattedNumber)) ?? "")M"
       }

       if self >= 10000000 {
           let formattedNumber = Double(self) / 1000000.0
           return "\(numberFormatter.string(from: NSNumber(value: formattedNumber)) ?? "")M"
       }

       return "\(numberFormatter.string(from: NSNumber(value: self)) ?? "")"
   }
    
   var noneFormattedString: String? {
        let numberFormatter = NumberFormatter()
          numberFormatter.numberStyle = NumberFormatter.Style.none
        numberFormatter.locale = NSLocale.current
        return numberFormatter.string(from: self as NSNumber)
   }
}

public extension NSDecimalNumber {

  /// Returns a currency formatted string where the currency's symbol is in front.
  /// For example $19.99.
  func frontSymbolCurrencyFormatted(with locale: Locale) -> String? {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = locale
    // Hide currency symbol, we append it manually in front of the String.
    formatter.currencySymbol = ""
    formatter.currencyCode = ""

    let currencySymbol = locale.currencySymbol ?? ""

    // Making currency codes empty adds extra space at the end, trimming it here.
    guard
      let formatted = formatter.string(from: self)?
        .trimmingCharacters(in: .whitespacesAndNewlines)
    else { return nil }

    return currencySymbol + formatted
  }
}
