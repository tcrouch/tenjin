// Re-dispatch Turbo events as Turbolinks events for legacy handlers.
// Retired in Phase 4 once no `turbolinks:` handlers remain in the codebase.
const eventMap = {
  "turbo:load": "turbolinks:load",
  "turbo:before-cache": "turbolinks:before-cache",
};

for (const [from, to] of Object.entries(eventMap)) {
  document.addEventListener(from, (event) => {
    document.dispatchEvent(new CustomEvent(to, { detail: event.detail }));
  });
}
