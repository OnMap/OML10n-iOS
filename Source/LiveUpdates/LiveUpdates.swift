//
//  LiveUpdates.swift
//  OML10n
//
//  Created by Alex Alexandrovych on 16/08/2017.
//  Copyright © 2017 OnMap LTD. All rights reserved.
//

import UIKit
import RxSwift
import RealmSwift
import RxRealm
import NSObject_Rx

private var runtimeLocalizationKey: UInt8 = 0

private extension UIViewController {

    var liveUpdates: LiveUpdates? {
        get {
            return objc_getAssociatedObject(self, &runtimeLocalizationKey) as? LiveUpdates
        }
        set {
            objc_setAssociatedObject(self, &runtimeLocalizationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

public class LiveUpdates {

    /**
     Created for keeping references to all objects, that should be updated on-the-fly
     */
    private var localizedObjects: [String: AnyObject] = [:]

    private weak var viewController: UIViewController!

    // MARK: Public API

    public static func listenUpdates(for viewController: UIViewController) {
        viewController.liveUpdates = LiveUpdates(viewController: viewController)
    }

    public static func stopListenUpdates(for viewController: UIViewController) {
        viewController.liveUpdates?.stopListenUpdates()
    }

    // MARK: - Private

    /**
     Appends all localized objects to the dictionary and configures live updating
     */
    private init(viewController: UIViewController) {
        self.viewController = viewController

        // Populate objects that shoud be updated live
        localizedObjects = getLocalizedViews(from: viewController.view)

        // Adding NavigationItem, BarButtonItems and TabBarItem because they are not in view hierarchy
        let navigationItem = viewController.navigationItem
        if let key = navigationItem.localizationKey {
            localizedObjects[key] = navigationItem
            let properties: [NavigationItemLocalizedProperty] = [.title, .prompt, .backButtonTitle]
            properties.forEach {
                localizedObjects[key + navigationItem.separator + $0.description] = navigationItem
            }
        }

        let barButtonItems = [navigationItem.leftBarButtonItems ?? [], navigationItem.rightBarButtonItems ?? []]
        barButtonItems.forEach { buttons in
            buttons.forEach { button in
                if let key = button.localizationKey {
                    localizedObjects[key] = button
                }
            }
        }

        let tabBarItem = viewController.tabBarItem
        if let item = tabBarItem, let key = item.localizationKey {
            localizedObjects[key] = tabBarItem
            let properties: [TabBarItemLocalizedProperty] = [.title, .badgeValue]
            properties.forEach {
                localizedObjects[key + item.separator + $0.description] = tabBarItem
            }
        }

        // Start observing changes
        configureObservingChanges()
    }

    private func stopListenUpdates() {
        viewController.rx.disposeBag = DisposeBag()
    }

    /**
     Observes changes in Realm for given languge and updates views
     */
    private func configureObservingChanges() {
        let language = Localization.currentLanguage
        do {
            let realm = try Realm(configuration: Realm.configuration(language: language))
            let localizedElements = realm.objects(LocalizedElement.self)
            Observable.arrayWithChangeset(from: localizedElements)
                .subscribe(onNext: { [weak self] array, changes in
                    self?.updateViews(from: array, with: changes)
                })
                .disposed(by: viewController.rx.disposeBag)
        } catch {
            print(error.localizedDescription)
        }
    }

    /**
     Recursively returns all localizable subviews from a given view
     */
    private func getLocalizedViews(from view: UIView) -> [String: UIView] {
        var views: [String: UIView] = [:]

        // We need to check if the view is UITextField or UITextView or UISearchBar or UISegmentedControl,
        // because it contains more subviews that we don't need to work with
        if view.subviews.isEmpty ||
            view is UITextField ||
            view is UITextView ||
            view is UISearchBar ||
            view is UISegmentedControl {

            switch view {
            case let button as UIButton:
                if let key = button.localizationKey {
                    views[key] = button
                    let properties: [ButtonLocalizedProperty] = [.normal, .selected, .highlighted, .disabled]
                    properties.forEach {
                        views[key + button.separator + $0.description] = view
                    }
                }
            case let label as UILabel:
                if let key = label.localizationKey {
                    views[key] = label
                }
            case let textField as UITextField:
                if let key = textField.localizationKey {
                    let properties: [TextFieldLocalizedProperty] = [.text, .placeholder]
                    properties.forEach {
                        views[key + textField.separator + $0.description] = view
                    }
                }
            case let textView as UITextView:
                if let key = textView.localizationKey {
                    views[key] = textView
                }
            case let searchBar as UISearchBar:
                if let key = searchBar.localizationKey {
                    let properties: [SearchBarLocalizedProperty] = [.text, .placeholder, .prompt]
                    properties.forEach {
                        views[key + searchBar.separator + $0.description] = view
                    }
                }
            case let segmentedControl as UISegmentedControl:
                if let key = segmentedControl.localizationKey {
                    (0..<segmentedControl.numberOfSegments).forEach { index in
                        views[key + segmentedControl.separator + String(index)] = segmentedControl
                    }
                }
            default:
                break
            }
            return views
        }

        view.subviews.forEach { subview in
            for (key, value) in getLocalizedViews(from: subview) {
                views[key] = value
            }
        }

        return views
    }

    private func updateViews(from array: [LocalizedElement], with changes: RealmChangeset?) {
        if let changes = changes {
            // Updates
            [changes.inserted, changes.updated].forEach { changes in
                changes.forEach { index in
                    updateLocalizedObject(with: array[index])
                }
            }
            changes.deleted.forEach { _ in
                print("LocalizedElement was deleted")
            }
        } else {
            // Initial
            array.forEach { localizedElement in
                updateLocalizedObject(with: localizedElement)
            }
        }
    }

    private func updateLocalizedObject(with localizedElement: LocalizedElement) {
        let text = localizedElement.text
        let key = localizedElement.key

        guard let object = localizedObjects[key] else { return }

        let separator = (object as? Localizable)?.separator ?? "."
        let property = key.components(separatedBy: separator).last ?? ""

        switch object {
        case let button as UIButton:
            let state: UIControlState

            switch property {
            case ButtonLocalizedProperty.normal.description:
                state = .normal
            case ButtonLocalizedProperty.highlighted.description:
                state = .highlighted
            case ButtonLocalizedProperty.selected.description:
                state = .selected
            case ButtonLocalizedProperty.disabled.description:
                state = .disabled
            default:
                state = .normal
            }

            if let mutableAttributedText = button.attributedTitle(for: state)?.mutableCopy() as? NSMutableAttributedString {
                mutableAttributedText.mutableString.setString(text)
                let attributedText = mutableAttributedText as NSAttributedString
                button.setAttributedTitle(attributedText, for: state)
            } else {
                button.setTitle(text, for: state)
            }
        case let label as UILabel:
            if let mutableAttributedText = label.attributedText?.mutableCopy() as? NSMutableAttributedString {
                mutableAttributedText.mutableString.setString(text)
                label.attributedText = mutableAttributedText as NSAttributedString
            } else {
                label.text = text
            }
        case let textField as UITextField:
            switch property {
            case TextFieldLocalizedProperty.text.description:
                if let mutableAttributedText = textField.attributedText?.mutableCopy() as? NSMutableAttributedString {
                    mutableAttributedText.mutableString.setString(text)
                    textField.attributedText = mutableAttributedText as NSAttributedString
                } else {
                    textField.text = text
                }
            case TextFieldLocalizedProperty.placeholder.description:
                textField.placeholder = text
            default:
                #if DEBUG
                    print("UITextField key should contain property" +
                        " (e.g. " + key + separator + TextFieldLocalizedProperty.text.description +
                        "/" + separator + TextFieldLocalizedProperty.placeholder.description + ")"
                    )
                #endif
            }
        case let textView as UITextView:
            if let mutableAttributedText = textView.attributedText?.mutableCopy() as? NSMutableAttributedString {
                mutableAttributedText.mutableString.setString(text)
                textView.attributedText = mutableAttributedText as NSAttributedString
            } else {
                textView.text = text
            }
        case let searchBar as UISearchBar:
            switch property {
            case SearchBarLocalizedProperty.text.description:
                searchBar.text = text
            case SearchBarLocalizedProperty.placeholder.description:
                searchBar.placeholder = text
            case SearchBarLocalizedProperty.prompt.description:
                searchBar.prompt = text
            default:
                #if DEBUG
                    print("UISearchBar key should contain property" +
                        " (e.g. " + key + separator + SearchBarLocalizedProperty.text.description +
                        "/" + separator + SearchBarLocalizedProperty.placeholder.description +
                        "/" + separator + SearchBarLocalizedProperty.prompt.description + ")"
                    )
                #endif
            }
        case let segmentedControl as UISegmentedControl:
            if let index = Int(property) {
                segmentedControl.setTitle(text, forSegmentAt: index)
            } else {
                #if DEBUG
                    print("UISegmentedControl key should contain index of a segment" +
                        " (e.g. " + key + separator + "0)")
                #endif
            }
        case let navigationItem as UINavigationItem:
            switch property {
            case NavigationItemLocalizedProperty.title.description:
                navigationItem.title = text
            case NavigationItemLocalizedProperty.prompt.description:
                navigationItem.prompt = text
            case NavigationItemLocalizedProperty.backButtonTitle.description:
                navigationItem.backBarButtonItem?.title = text
            default:
                navigationItem.title = text
            }
        case let barButtonItem as UIBarButtonItem:
            barButtonItem.title = text
        case let tabBarItem as UITabBarItem:
            switch property {
            case TabBarItemLocalizedProperty.title.description:
                tabBarItem.title = text
            case TabBarItemLocalizedProperty.badgeValue.description:
                tabBarItem.badgeValue = text
            default:
                tabBarItem.title = text
            }
        default:
            #if DEBUG
                print("Object \(object) has unsupported type")
            #endif
        }
    }
}
