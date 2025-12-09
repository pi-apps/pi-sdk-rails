console.log("index.jsx loading")
import React from "react";
import { createRoot } from "react-dom/client";
import Hello from "./Hello";
import PiNetwork, { onBuy } from "./PiNetwork";

// Wait until the DOM is loaded before mounting React
document.addEventListener("DOMContentLoaded", () => {
  const rootDiv = document.getElementById("pinetwork");
  if (rootDiv) {
    createRoot(rootDiv).render(<PiNetwork disabled={false} onBuy={onBuy} />);
  }
});
