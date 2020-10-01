/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

import Foundation
import ComponentKit

#if swift(>=5.3)

// MARK: ComponentInflatable

/// Can be inflated to a `Component` given a `SwiftComponentModel`.
/// Anything that is `ComponentInflatable` can be added to a CKSwift view hierarchy.
public protocol ComponentInflatable {
  func inflateComponent(with model: SwiftComponentModel?) -> Component
}

// MARK: View

public protocol View : ComponentInflatable {
  associatedtype Body
  @ComponentBuilder var body: Body { get }
}

extension View where Self.Body == Never {
  public var body: Never {
    // Leaf views don't return
    fatalError("Attempting to call .body on a leaf view")
  }
}

public protocol ViewIdentifiable {
  associatedtype ID: Hashable
  var id: ID { get }
}

// MARK: Non-leaf component

extension View where Self.Body == Component {
  public func inflateComponent(with model: SwiftComponentModel?) -> Component {
    // TODO: Reuse logic
    // TODO: CKDeflatedComponentContext

    let hasScopeHandle = linkPropertyWrappersWithScopeHandle(
      forceRequireNode: model?.requiresNode ?? false)

    if hasScopeHandle == false {
      // If the current view doesn't require a scope handle and there is no view configuration
      // simply inflate the body to reduce the number of components generated. aka Stateless.
      return body.inflateComponent(with: model)
    }

    defer {
      if hasScopeHandle {
        CKSwiftPopClass()
      }
    }

    return SwiftComponent(
      self,
      body: body,
      model: model
    ).animated(model?.animations)
  }
}

extension View where Self: ViewIdentifiable, Self.Body == Component {
  public func inflateComponent(with model: SwiftComponentModel?) -> Component {
    // TODO: Reuse logic
    // TODO: CKDeflatedComponentContext

    linkPropertyWrappersWithScopeHandle()

    defer {
      CKSwiftPopClass()
    }

    // We've got an identifier so we shouldn't just return our child.

    return SwiftComponent(
      self,
      body: body,
      model: model
    ).animated(model?.animations)
  }
}

extension View where Self: ViewConfigurationRepresentable, Self.Body == Component {
  public func inflateComponent(with model: SwiftComponentModel?) -> Component {
    // TODO: Reuse logic
    // TODO: CKDeflatedComponentContext

    let hasScopeHandle = linkPropertyWrappersWithScopeHandle()

    defer {
      if hasScopeHandle {
        CKSwiftPopClass()
      }
    }

    // We've got an identifier so we shouldn't just return our child.

    return SwiftComponent(
      self,
      body: body,
      viewConfiguration: viewConfiguration,
      model: model
    ).animated(model?.animations)
  }
}

extension View where Self: ViewIdentifiable & ViewConfigurationRepresentable, Self.Body == Component {
  public func inflateComponent(with model: SwiftComponentModel?) -> Component {
    // TODO: Reuse logic
    // TODO: CKDeflatedComponentContext

    linkPropertyWrappersWithScopeHandle()

    defer {
      CKSwiftPopClass()
    }

    // We've got an identifier so we shouldn't just return our child.

    return SwiftComponent(
      self,
      body: body,
      viewConfiguration: viewConfiguration,
      model: model
    ).animated(model?.animations)
  }
}

// MARK: Leaf component

extension View where Self: ViewConfigurationRepresentable, Self.Body == Never {
  public func inflateComponent(with model: SwiftComponentModel?) -> Component {
    // TODO: Reuse logic
    // TODO: CKDeflatedComponentContext

    let hasScopeHandle = linkPropertyWrappersWithScopeHandle(
      forceRequireNode: model?.requiresNode ?? false)

    defer {
      if hasScopeHandle {
        CKSwiftPopClass()
      }
    }

    return SwiftComponent(
      self,
      viewConfiguration: viewConfiguration,
      model: model
    )
    .animated(model?.animations)
  }
}

extension View where Self: ViewConfigurationRepresentable & ViewIdentifiable, Self.Body == Never {
  public func inflateComponent(with model: SwiftComponentModel?) -> Component {
    // TODO: Reuse logic
    // TODO: CKDeflatedComponentContext

    linkPropertyWrappersWithScopeHandle()

    defer {
      CKSwiftPopClass()
    }

    return SwiftComponent(
      self,
      viewConfiguration: viewConfiguration,
      model: model
    )
    .animated(model?.animations)
  }
}

// MARK: Link

private extension View {
  func linkPropertyWrappersWithScopeHandle(forceRequireNode: Bool = false) -> Bool {
    let states = Mirror(reflecting: self)
      .children
      .compactMap {
        $0.value as? ScopeHandleLinkable
      }

    guard states.isEmpty == false || forceRequireNode else {
      return false
    }

    let scopeHandle = CKSwiftCreateScopeHandle(SwiftComponent<Self>.self, nil)
    states
      .enumerated()
      .forEach { index, state in
        state.link(with: scopeHandle, at: index)
      }
    return true
  }
}

private extension View where Self: ViewIdentifiable {
  func linkPropertyWrappersWithScopeHandle() {
    let states = Mirror(reflecting: self)
      .children
      .compactMap {
        $0.value as? ScopeHandleLinkable
      }

    // We've got an identifier so we shouldn't skip the creation of the scope.
    let scopeHandle = CKSwiftCreateScopeHandle(SwiftComponent<Self>.self, id)
    states
      .enumerated()
      .forEach { index, state in
        state.link(with: scopeHandle, at: index)
      }
  }
}

#endif
