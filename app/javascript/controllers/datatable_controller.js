import { Controller } from "@hotwired/stimulus";

// Stimulus controller wrapping jQuery DataTables. Mount on a wrapping element
// (e.g. a div around the <table>), not on the table itself: DataTables'
// initialisation calls $().wrap() on the table, which detaches+reattaches the
// element. If the controller lives on the table, that mutation triggers
// disconnect/connect repeatedly and crashes the tab.
export default class extends Controller {
  static targets = ["table"];
  static values = { options: { type: Object, default: {} } };

  connect() {
    if ($.fn.dataTable.moment) $.fn.dataTable.moment("dd/MM/YYYY HH:mm"); // Phase 5
    this.table = $(this.tableTarget).DataTable(this.optionsValue);
  }

  disconnect() {
    if (this.table) this.table.destroy();
  }
}
