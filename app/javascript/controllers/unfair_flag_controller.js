import { Controller } from "@hotwired/stimulus";
import { Modal } from "bootstrap";
import csrfFetch from "../lib/csrf_fetch";

export default class extends Controller {
  async flag(event) {
    event.preventDefault();
    const response = await csrfFetch(this.element.href, { method: "POST" });
    if (!response.ok) {
      console.error("Flag question POST failed", response.status);
      return;
    }

    const svg = this.element.querySelector("svg");
    if (svg.dataset.prefix === "far") {
      svg.classList.add("fas");
      svg.dataset.prefix = "fas";
      bootstrap.Modal.getOrCreateInstance(
        document.getElementById("feedbackModal"),
      ).show();
    } else {
      svg.classList.add("far");
      svg.dataset.prefix = "far";
    }
  }
}
