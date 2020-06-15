//
//  NSTableView+Rx.swift
//  RxDataSources
//
//  Created by Fabian Mücke on 15.06.20.
//  Copyright © 2020 kzaher. All rights reserved.
//

#if os(macOS)
    import AppKit
    #if !RX_NO_MODULE
        import RxSwift
    #endif

    extension Reactive where Base: NSTableView {
        /**
         Reactive wrapper for `dataSource`.

         For more information take a look at `DelegateProxyType` protocol documentation.
         */
        public var dataSource: DelegateProxy<NSTableView, NSTableViewDataSource> {
            return RxTableViewDataSourceProxy.proxy(for: base)
        }

        /**
         Installs data source as forwarding delegate on `rx.dataSource`.
         Data source won't be retained.

         It enables using normal delegate mechanism with reactive delegate mechanism.

         - parameter dataSource: Data source object.
         - returns: Disposable object that can be used to unbind the data source.
         */
        public func setDataSource(_ dataSource: NSTableViewDataSource)
            -> Disposable {
            return RxTableViewDataSourceProxy.installForwardDelegate(
                dataSource,
                retainDelegate: false,
                onProxyForObject: base
            )
        }
        
        /**
        Binds sequences of elements to table view rows using a custom reactive data used to perform the transformation.
        This method will retain the data source for as long as the subscription isn't disposed (result `Disposable`
        being disposed).
        In case `source` observable sequence terminates successfully, the data source will present latest element
        until the subscription isn't disposed.
        
        - parameter dataSource: Data source used to transform elements to view cells.
        - parameter source: Observable sequence of items.
        - returns: Disposable object that can be used to unbind.
        */
        public func items<
                DataSource: RxTableViewDataSourceType & NSTableViewDataSource,
                Source: ObservableType>
            (dataSource: DataSource)
            -> (_ source: Source)
            -> Disposable
            where DataSource.Element == Source.Element {
            return { source in
//                // This is called for sideeffects only, and to make sure delegate proxy is in place when
//                // data source is being bound.
//                // This is needed because theoretically the data source subscription itself might
//                // call `self.rx.delegate`. If that happens, it might cause weird side effects since
//                // setting data source will set delegate, and UITableView might get into a weird state.
//                // Therefore it's better to set delegate proxy first, just to be sure.
//                _ = self.delegate
                // Strong reference is needed because data source is in use until result subscription is disposed
                return source.subscribeProxyDataSource(ofObject: self.base, dataSource: dataSource as NSTableViewDataSource, retainDataSource: true) { [weak tableView = self.base] (_: RxTableViewDataSourceProxy, event) -> Void in
                    guard let tableView = tableView else {
                        return
                    }
                    dataSource.tableView(tableView, observedEvent: event)
                }
            }
        }
    }

#endif
