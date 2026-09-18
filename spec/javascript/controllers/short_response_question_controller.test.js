import ShortResponseQuestionController from "../../../app/javascript/controllers/short_response_question_controller";

// Minimal Stimulus context: an unregistered controller has no target getters,
// so the targets are plain properties set here.
function makeController() {
  const input = document.createElement("input");
  const button = document.createElement("button");
  const controller = new ShortResponseQuestionController({
    scope: { element: document.body },
  });
  controller.inputTarget = input;
  controller.submitButtonTarget = button;
  return { controller, input, button };
}

describe("ShortResponseQuestionController#_mark", () => {
  it("paints the server's verdict rather than comparing the guess itself", () => {
    const { controller, input, button } = makeController();
    input.value = "the autumn";

    controller._mark({ correct: false, answer: [{ text: "the autumn" }] });

    expect(button.classList.contains("incorrect-answer")).toBe(true);
    expect(button.textContent).toMatch(/^Incorrect/);
  });

  it("marks a correct verdict", () => {
    const { controller, input, button } = makeController();
    input.value = "anything";

    controller._mark({ correct: true, answer: [{ text: "To Autumn" }] });

    expect(button.classList.contains("correct-answer")).toBe(true);
    expect(button.textContent).toMatch(/^Correct!/);
  });

  it("reveals every accepted answer after a miss", () => {
    const { controller, input } = makeController();
    input.value = "nope";

    controller._mark({
      correct: false,
      answer: [{ text: "To Autumn" }, { text: "The Autumn" }],
    });

    expect(input.value).toBe("To Autumn or The Autumn");
  });
});
