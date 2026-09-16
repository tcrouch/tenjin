import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "button", "match"];

  check() {
    const mismatch =
      this.inputTarget.value !== this.matchTarget.textContent.trim();
    this.buttonTarget.disabled = mismatch;
  }
}
