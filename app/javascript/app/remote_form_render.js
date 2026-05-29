// Replaces `turbolinks_render` gem behavior under Turbo.
// When a `remote: true` form or link responds with HTML:
// - redirect -> Turbo.visit(responseURL)
// - inline render (e.g. validation errors) -> swap body, keep URL
// Also auto-annotates `data-remote="true"` elements with `data-turbo="false"`
// so Turbo doesn't double-handle submissions that @rails/ujs owns.
//
// Uses `window.Turbo` (set by `@hotwired/turbo-rails` once it loads — see
// packs/application.js) rather than a static import, so this file compiles
// even before Turbo is installed.
//
// All retired in Phase 7 alongside the `turbolinks_render` gem.

function handleAjaxSuccess(event) {
  const [data, , xhr] = event.detail;
  const contentType = xhr.getResponseHeader("Content-Type") || "";
  if (!contentType.includes("text/html")) return;

  // XHR auto-follows redirects, so xhr.status is always 200 here.
  // Detect a redirect by comparing the final URL to the originating element's URL.
  const target = event.target;
  const originalURL =
    target.href ||
    (target.action && new URL(target.action, document.baseURI).href);
  const wasRedirect =
    originalURL && xhr.responseURL && xhr.responseURL !== originalURL;

  if (wasRedirect) {
    window.Turbo.visit(xhr.responseURL);
  } else {
    const html = typeof data === "string" ? data : xhr.responseText;
    const doc = new DOMParser().parseFromString(html, "text/html");
    document.body.replaceWith(doc.body);
    document.dispatchEvent(new CustomEvent("turbo:load"));
  }
}

function tagRemoteForms() {
  document.querySelectorAll('[data-remote="true"]').forEach((el) => {
    if (!el.hasAttribute("data-turbo")) el.setAttribute("data-turbo", "false");
  });
}

document.addEventListener("ajax:success", handleAjaxSuccess);
document.addEventListener("turbo:load", tagRemoteForms);
// Also run on initial DOMContentLoaded for the very first page load, since
// `turbo:load` fires on first navigation but not before turbo is installed.
document.addEventListener("DOMContentLoaded", tagRemoteForms);
