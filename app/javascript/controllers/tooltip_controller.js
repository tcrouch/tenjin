import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    $(this.element).find('[data-toggle="tooltip"]').tooltip();
  }

  disconnect() {
    $(this.element).find('[data-toggle="tooltip"]').tooltip("dispose");
  }
}
