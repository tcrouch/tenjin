import ConfirmTextController from "../../../app/javascript/controllers/confirm_text_controller";

describe("ConfirmTextController#check", () => {
  let input, button, controller;

  beforeEach(() => {
    const match = document.createElement("strong");
    match.textContent = " reset year ";
    input = document.createElement("input");
    button = document.createElement("button");
    button.disabled = true;
    controller = new ConfirmTextController({
      scope: { element: document.body },
    });
    Object.defineProperties(controller, {
      inputTarget: { value: input },
      buttonTarget: { value: button },
      matchTarget: { value: match },
    });
  });

  it("enables the button once the input matches", () => {
    input.value = "reset year";
    controller.check();
    expect(button.disabled).toBe(false);
  });

  it("disables the button again when the input stops matching", () => {
    input.value = "reset year";
    controller.check();
    input.value = "reset yea";
    controller.check();
    expect(button.disabled).toBe(true);
  });
});
