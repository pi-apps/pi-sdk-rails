import React from "react";

export default function PiNetwork(props) {
  console.log("pinetwork");
  if (!window.Pi || typeof window.Pi.init !== "function") {
    this.constructor.error("Pi SDK not loaded.");
    return;
  }
  // Determine Pi.init options based on Rails env
  let piInitOptions = { version: "2.0" };
  const railsEnv = (window.RAILS_ENV || process.env?.RAILS_ENV || process.env?.NODE_ENV || "development");
  if (railsEnv === "development" || railsEnv === "test") {
    piInitOptions.sandbox = true;
  }
  Pi.init(piInitOptions);
  console.log("SDK initialized", piInitOptions);

  return (
    <button type="button" className="btn btn-primary" onClick={onBuy}>
      Buy
    </button>
  );
}

export function onBuy() {
  console.log("clicked");
  alert("Purchase started!");
}
