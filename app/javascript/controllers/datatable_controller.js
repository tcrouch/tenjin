import { Controller } from "@hotwired/stimulus";
import { TabulatorFull as Tabulator } from "tabulator-tables";

// Stimulus controller wrapping Tabulator. The "datatable" name is
// retained for markup continuity with existing views.
// Mount on a wrapping element (not the <table>) with the table as
// the `table` target. Optional `search` target binds a filter input;
// optional `copy`/`downloadCsv` actions back export buttons.
export default class extends Controller {
  static targets = ["table", "search"];
  static values = { options: { type: Object, default: {} } };

  connect() {
    // Snapshot source <tr> id/class/data-* before Tabulator regenerates rows.
    this.sourceRowAttrs = Array.from(
      this.tableTarget.querySelectorAll("tbody tr"),
    ).map((tr) => ({
      id: tr.id || null,
      className: tr.className || null,
      dataset: { ...tr.dataset },
    }));

    this.tabulator = new Tabulator(this.tableTarget, {
      layout: "fitColumns",
      autoColumns: true,
      pagination: true,
      paginationSize: 10,
      columnDefaults: { formatter: "html" },
      ...this.optionsValue,
      rowFormatter: (row) => this.reapplyRowAttrs(row),
    });
  }

  disconnect() {
    if (this.tabulator) this.tabulator.destroy();
  }

  filter(event) {
    const value = event.target.value;
    clearTimeout(this._filterTimeout);
    this._filterTimeout = setTimeout(() => {
      if (value) {
        this.tabulator.setFilter((row) =>
          Object.values(row).some(
            (cell) =>
              typeof cell === "string" &&
              cell.toLowerCase().includes(value.toLowerCase()),
          ),
        );
      } else {
        this.tabulator.clearFilter();
      }
    }, 150);
  }

  copy() {
    this.tabulator.copyToClipboard("active");
  }

  downloadCsv() {
    this.tabulator.download("csv", "data.csv");
  }

  reapplyRowAttrs(row) {
    const idx = row.getPosition(true) - 1;
    const src = this.sourceRowAttrs[idx];
    if (!src) return;
    const el = row.getElement();
    if (src.id) el.id = src.id;
    if (src.className) {
      src.className
        .split(/\s+/)
        .filter(Boolean)
        .forEach((c) => el.classList.add(c));
    }
    Object.entries(src.dataset).forEach(([k, v]) => {
      el.dataset[k] = v;
    });
  }
}
