import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "label"];

  update() {
    const file = this.inputTarget.files[0];
    if (file) this.labelTarget.textContent = file.name;
  }
}
