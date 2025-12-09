import { Application } from "@hotwired/stimulus";
import { EnginePisdkController } from "./pi_sdk_controller";

global.Pi = {
  init: jest.fn(),
  authenticate: jest.fn(),
};

describe("EnginePiSdkController#connect", () => {
  let element, app, controllerInstance;

  beforeEach(() => {
    document.body.innerHTML = `<div data-controller="pisdk"></div>`;
    element = document.querySelector("[data-controller='pisdk']");
    app = Application.start();
    app.register("pisdk", EnginePiSdkController);
    Pi.init.mockClear();
    Pi.authenticate.mockClear();
    Pi.authenticate.mockImplementation(() =>
      Promise.resolve({ accessToken: "token", user: { id: "foo" } })
    );
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
    expect(Pi.init).toHaveBeenCalledWith({ version: "2.0", sandbox: true });
  });

  it("calls Pi.authenticate and sets accessToken, user, and connected = true", async () => {
    controllerInstance = getControllerInstance();
    controllerInstance.onConnection = jest.fn();
    await controllerInstance.connect();
    expect(Pi.authenticate).toHaveBeenCalled();
    expect(controllerInstance.accessToken).toBe("token");
    expect(controllerInstance.user).toEqual({ id: "foo" });
    expect(controllerInstance.connected).toBe(true);
  });

  it("calls onConnection after successful auth", async () => {
    controllerInstance = getControllerInstance();
    controllerInstance.onConnection = jest.fn();
    await controllerInstance.connect();
    expect(controllerInstance.onConnection).toHaveBeenCalled();
  });

  it("handles auth failure gracefully", async () => {
    Pi.authenticate.mockImplementationOnce(() => Promise.reject("error"));
    controllerInstance = getControllerInstance();
    controllerInstance.onConnection = jest.fn();
    await controllerInstance.connect();
    expect(controllerInstance.connected).toBe(false);
    expect(controllerInstance.onConnection).not.toHaveBeenCalled();
  });
});
