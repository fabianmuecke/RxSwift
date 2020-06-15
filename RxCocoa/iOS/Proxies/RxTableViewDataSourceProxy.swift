//
//  RxTableViewDataSourceProxy.swift
//  RxCocoa
//
//  Created by Krunoslav Zaher on 6/15/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if os(iOS) || os(tvOS)

import UIKit
import RxSwift
    
extension UITableView: HasDataSource {
    public typealias DataSource = UITableViewDataSource
}

private let tableViewDataSourceNotSet = TableViewDataSourceNotSet()

private final class TableViewDataSourceNotSet
    : NSObject
    , UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        rxAbstractMethod(message: dataSourceNotSet)
    }
}

/// For more information take a look at `DelegateProxyType`.
open class RxTableViewDataSourceProxy
    : DelegateProxy<UITableView, UITableViewDataSource>
    , DelegateProxyType 
    , UITableViewDataSource {

    /// Typed parent object.
    public weak private(set) var tableView: UITableView?

    /// - parameter tableView: Parent object for delegate proxy.
    public init(tableView: UITableView) {
        self.tableView = tableView
        super.init(parentObject: tableView, delegateProxy: RxTableViewDataSourceProxy.self)
    }

    // Register known implementations
    public static func registerKnownImplementations() {
        self.register { RxTableViewDataSourceProxy(tableView: $0) }
    }

    private weak var _requiredMethodsDataSource: UITableViewDataSource? = tableViewDataSourceNotSet

    // MARK: delegate

    /// Required delegate method implementation.
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (_requiredMethodsDataSource ?? tableViewDataSourceNotSet).tableView(tableView, numberOfRowsInSection: section)
    }

    /// Required delegate method implementation.
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return (_requiredMethodsDataSource ?? tableViewDataSourceNotSet).tableView(tableView, cellForRowAt: indexPath)
    }

    /// For more information take a look at `DelegateProxyType`.
    open override func setForwardToDelegate(_ forwardToDelegate: UITableViewDataSource?, retainDelegate: Bool) {
        _requiredMethodsDataSource = forwardToDelegate  ?? tableViewDataSourceNotSet
        super.setForwardToDelegate(forwardToDelegate, retainDelegate: retainDelegate)
    }

}

#elseif os(macOS)

    import AppKit
    import RxSwift

    extension NSTableView: HasDataSource {
        public typealias DataSource = NSTableViewDataSource
    }

    private let tableViewDataSourceNotSet = TableViewDataSourceNotSet()

    private final class TableViewDataSourceNotSet:
        NSObject,
        NSTableViewDataSource {
        func numberOfRows(in tableView: NSTableView) -> Int {
            0
        }

        func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
            fatalError("DataSource not set")
        }
    }

    /// For more information take a look at `DelegateProxyType`.
    open class RxTableViewDataSourceProxy:
        DelegateProxy<NSTableView, NSTableViewDataSource>,
        DelegateProxyType,
        NSTableViewDataSource {
        /// Typed parent object.
        public private(set) weak var tableView: NSTableView?

        /// - parameter tableView: Parent object for delegate proxy.
        public init(tableView: NSTableView) {
            self.tableView = tableView
            super.init(parentObject: tableView, delegateProxy: RxTableViewDataSourceProxy.self)
        }

        // Register known implementations
        public static func registerKnownImplementations() {
            register { RxTableViewDataSourceProxy(tableView: $0) }
        }

        private weak var _requiredMethodsDataSource: NSTableViewDataSource? = tableViewDataSourceNotSet

        // MARK: delegate

        /// Required delegate method implementation.
        public func numberOfRows(in tableView: NSTableView) -> Int {
            guard let rows = (_requiredMethodsDataSource ?? tableViewDataSourceNotSet).numberOfRows?(in: tableView) else {
                fatalError("numberOfRows in tableView not implemented")
            }
            return rows
        }

        /// Required delegate method implementation.
        public func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
            (_requiredMethodsDataSource ?? tableViewDataSourceNotSet)
                .tableView?(tableView, objectValueFor: tableColumn, row: row)
        }

        /// For more information take a look at `DelegateProxyType`.
        override open func setForwardToDelegate(_ forwardToDelegate: NSTableViewDataSource?, retainDelegate: Bool) {
            _requiredMethodsDataSource = forwardToDelegate ?? tableViewDataSourceNotSet
            super.setForwardToDelegate(forwardToDelegate, retainDelegate: retainDelegate)
        }
    }

#endif
