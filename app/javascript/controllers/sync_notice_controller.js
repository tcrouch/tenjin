import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["status", "button"];
  static values = { neededLabel: String };

  notify() {
    this.statusTarget.textContent = this.neededLabelValue;
    if (!this.hasButtonTarget) return; // sync-status helper renders text instead of a button mid-sync
    this.buttonTarget.classList.remove("btn-primary");
    this.buttonTarget.classList.add("btn-danger");
    this.buttonTarget.textContent =
      "School sync required. Click here to start.";
  }
}
