// app/javascript/application.js
console.log("loading index.jsx")
import React from 'react';
import ReactDOM from 'react-dom/client';
import PiNetwork from './PiNetwork';

document.addEventListener('DOMContentLoaded', () => {
  const rootElement = document.getElementById('pinetwork');
  if (rootElement) {
    const root = ReactDOM.createRoot(rootElement);
    // You can pass props here if needed, e.g., name="User"
    console.log("adding")
    root.render(<PiNetwork />);
  }
});
