import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["col"];

  toggle() {
    this.colTargets.forEach((c) => c.classList.toggle("d-none"));
  }
}
