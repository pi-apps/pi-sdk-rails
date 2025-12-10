// ============================================================================
// PiSdkComponent.jsx - Reusable Pi Sdk base React component
// For host app developers: use as a compositional base for advanced or custom
// Pi Sdk-enabled React UIs. Extends PiSdkBase and provides basic auth
// and connection-to-Pi logic. Add your additional UI, props, methods as needed.
// Consider extending or wrapping for advanced payment behaviors or multi-step UIs.
// ============================================================================
import React from 'react';
import PiSdkBase from "./pi_sdk_base";

export default class PiSdkComponent extends React.Component {
  constructor(props) {
    super(props);
    // Defensive mixin binding for underlying SDK logic
    Object.getOwnPropertyNames(PiSdkBase.prototype).forEach(name => {
      if (name !== 'constructor') {
        this[name] = PiSdkBase.prototype[name].bind(this);
      }
    });
    this.initializePiSdkBase();
  }
  componentDidMount() {
    // Connect to Pi Browser/session on mount
    this.connect();
  }
  // Utility: can be used in your custom render to check connection
  is_connected_to_pi() {
    return PiSdkBase.connected;
  }
}

// Make all PiSdkBase methods available to extending classes
Object.assign(PiSdkComponent.prototype, PiSdkBase.prototype);
