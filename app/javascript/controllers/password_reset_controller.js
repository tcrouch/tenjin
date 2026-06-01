import { Controller } from "@hotwired/stimulus";
import csrfFetch from "../lib/csrf_fetch";

export default class extends Controller {
  async reset(event) {
    event.preventDefault();
    const response = await csrfFetch(this.element.href, { method: "PATCH" });
    if (!response.ok) {
      console.error("Password reset failed", response.status);
      return;
    }
    const { password } = await response.json();
    // Phase 5: Tabulator renders cells as `div.tabulator-cell` rather than
    // native `<td>`, so accept either container.
    const cell = this.element.closest("td, .tabulator-cell");
    cell.innerHTML = `<div class="new-password">${password}</div>`;
  }
}
