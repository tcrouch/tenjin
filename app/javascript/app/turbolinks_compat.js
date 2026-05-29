// Compat shim for the Turbolinks->Turbo swap:
// - Re-dispatch Turbo events as Turbolinks events for legacy handlers
// - Polyfill the `Turbolinks` global so existing `Turbolinks.visit()` calls work
// Retired in Phase 4 once no `turbolinks:` references remain in the codebase.
const eventMap = {
  "turbo:load": "turbolinks:load",
  "turbo:before-cache": "turbolinks:before-cache",
};

for (const [from, to] of Object.entries(eventMap)) {
  document.addEventListener(from, (event) => {
    document.dispatchEvent(new CustomEvent(to, { detail: event.detail }));
  });
}

// Polyfill the global `Turbolinks` object so legacy `Turbolinks.visit(...)`
// callsites (in app/classroom.js, app/teacher_dashboard.js, app/questions.js,
// app/student_dashboard.js) keep working until Phases 3/4 migrate them to
// `Turbo.visit(...)`. Retired in Phase 4 with the rest of this shim.
window.Turbolinks = {
  visit: (url, options) => window.Turbo.visit(url, options),
};
