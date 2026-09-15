import { Controller } from "@hotwired/stimulus";

// Scrolls its element into view once a Turbo visit has done its own scroll-to-top
export default class extends Controller {
  connect() {
    this.frame = requestAnimationFrame(() => this.element.scrollIntoView());
  }

  disconnect() {
    cancelAnimationFrame(this.frame);
  }
}
