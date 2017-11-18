//
//  Localizable.swift
//  OML10n
//
//  Created by Alex Alexandrovych on 04/05/2017.
//  Copyright © 2017 OnMap LTD. All rights reserved.
//

import Foundation

/**
 Returns localized text for given key or key if text doesn't exists or is empty
 */
func localized(_ key: String) -> String {
    let localizedString = Bundle.main.localizedString(forKey: key, value: key, table: nil)
    guard localizedString != key && !localizedString.isEmpty else {
        print("There is no localized text for key: \(key)")
        return key
    }
    return Bundle.main.localizedString(forKey: key, value: key, table: nil)
}

/**
 Returns localized text for given key in plural form with given count as args
 */
func localized(_ key: String, args: [CVarArg]) -> String {
    let format = localized(key)
    return withVaList(args) { arguments -> String in
        return NSString(format: format, locale: Localization.currentLocale, arguments: arguments) as String
    }
}
