// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import "../styles/application.scss";

import Rails from "@rails/ujs";
import { Turbo } from "@hotwired/turbo-rails";
// Turbo Drive disabled in Phase 1 — too many UJS-style links/forms in the
// codebase for Drive to coexist cleanly. The library is loaded so Phase 2
// can use Turbo Streams over ActionCable for the leaderboard. Drive gets
// turned back on (per-element or globally) as UJS patterns are migrated.
Turbo.session.drive = false;
import * as ActiveStorage from "@rails/activestorage";
import "bootstrap";
import "@fortawesome/fontawesome-free/js/all";
import { Application } from "@hotwired/stimulus";
import { definitionsFromContext } from "@hotwired/stimulus-webpack-helpers";

import flatpickr from "flatpickr";
import "flatpickr/dist/flatpickr.min.css";

import "../lib/remote_form_render";
import "../lib/live_leaderboard";
import "../lib/google_analytics";

Rails.start();
ActiveStorage.start();

const images = require.context("../images", true);
const imagePath = (name) => images(name, true);

import "datatables.net-bs4";
import "datatables.net-buttons-bs4";
import "datatables.net-buttons/js/buttons.html5.js";
require("datetime-moment");

require("trix");
import "@rails/actiontext";
import "@rails/actioncable";

// Support component names relative to this directory:
var componentRequireContext = require.context("components", true);
var ReactRailsUJS = require("react_ujs");
ReactRailsUJS.useContext(componentRequireContext);

// react_ujs 3.2 predates Turbo; explicitly bridge turbo:load/before-cache to
// mount/unmount React components on navigation. Retired in Phase 7 when
// react-rails goes.
document.addEventListener("turbo:load", () => ReactRailsUJS.mountComponents());
document.addEventListener("turbo:before-cache", () =>
  ReactRailsUJS.unmountComponents(),
);

// Stimulus
const application = Application.start();
const context = require.context("controllers", true, /\.js$/);
application.load(definitionsFromContext(context));

// Alpine.js (installed for Phase 2 leaderboard rewrite; not used yet)
import Alpine from "alpinejs";
window.Alpine = Alpine;
Alpine.start();
