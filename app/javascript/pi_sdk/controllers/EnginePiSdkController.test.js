import { describe, it, beforeEach, afterEach, expect, vi } from "vitest";
import { Application } from "@hotwired/stimulus";
import EnginePiSdkController from "./EnginePiSdkController.js";
import { PiSdkBase } from "pi-sdk-js";

// Setup global Pi with Vitest instead of Jest
// Use vi.fn() for mocks

global.Pi = window.Pi = {
  init: vi.fn(),
  authenticate: vi.fn(),
};

describe("EnginePiSdkController#connect Successful", () => {
  let element, app, controllerInstance;

  beforeEach(() => {
    const piMockGoldenPath = {
      init: vi.fn(),
      authenticate: vi.fn(() =>
	Promise.resolve({
          accessToken: "token",
          user: { name: "Jane Pi", email: "jane@pi.com", role: "tester" }
	})
      )
    };
    global.Pi = window.Pi = piMockGoldenPath;

    document.body.innerHTML = `<div data-controller="pisdk"></div>`;
    element = document.querySelector("[data-controller='pisdk']");
    app = Application.start();
    app.register("pisdk", EnginePiSdkController);
    window.Pi.init.mockClear();
    window.Pi.authenticate.mockClear();
    // Reset PiSdkBase static state
    PiSdkBase.user = null;
    PiSdkBase.connected = false;
    PiSdkBase.accessToken = null;
  });

  afterEach(() => {
    app.stop();
    document.body.innerHTML = "";
  });

  function getControllerInstance() {
    return app.getControllerForElementAndIdentifier(element, "pisdk");
  }

  it("calls Pi.init with correct options", async () => {
    controllerInstance = getControllerInstance();
    await controllerInstance.connect();
    expect(window.Pi.init).toHaveBeenCalledWith({ version: "2.0", sandbox: true });
  });

  it("calls Pi.authenticate and sets accessToken, user, and connected = true", async () => {
    controllerInstance = getControllerInstance();
    const spy = vi.fn();
    controllerInstance.onConnection = spy;
    controllerInstance._piSdk.onConnection = spy;

    await controllerInstance.connect();
    await Promise.resolve(); // allow async to complete

    expect(window.Pi.authenticate).toHaveBeenCalled();
    expect(controllerInstance.user).toMatchObject({ name: "Jane Pi" });
    expect(controllerInstance.is_connected()).toBe(true);
    expect(spy).toHaveBeenCalled();
  });

  it("calls onConnection after successful auth", async () => {
    controllerInstance = getControllerInstance();
    const spy = vi.fn();
    controllerInstance.onConnection = spy;
    controllerInstance._piSdk.onConnection = spy;
    await controllerInstance.connect();
    await Promise.resolve(); // wait for async callback
    expect(spy).toHaveBeenCalled();
  });

});

describe("EnginePiSdkController#connect Failure", () => {
  let element, app, controllerInstance;
  beforeEach(() => {
    const piMockGoldenPath = {
      init: vi.fn(),
      authenticate: vi.fn(() =>
	Promise.reject("error")
      )
    };
    global.Pi = window.Pi = piMockGoldenPath;

    document.body.innerHTML = `<div data-controller="pisdk"></div>`;
    element = document.querySelector("[data-controller='pisdk']");
    app = Application.start();
    app.register("pisdk", EnginePiSdkController);
    window.Pi.init.mockClear();
    window.Pi.authenticate.mockClear();
    // Reset PiSdkBase static state
    PiSdkBase.user = null;
    PiSdkBase.connected = false;
    PiSdkBase.accessToken = null;
  });

  function getControllerInstance() {
    return app.getControllerForElementAndIdentifier(element, "pisdk");
  }

  it("handles auth failure gracefully", async () => {
    // Pi.authenticate.mockImplementation(() => Promise.reject("error"));
    controllerInstance = getControllerInstance();
    const spy = vi.fn();
    controllerInstance.onConnection = spy;
    controllerInstance._piSdk.onConnection = spy;
    await controllerInstance.connect();
    await Promise.resolve(); // wait for async to flush
    expect(controllerInstance.is_connected()).toBe(false);
    expect(spy).not.toHaveBeenCalled();
  });
});
