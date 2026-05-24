import { Controller } from "@hotwired/stimulus";

// Toggles the chain step peek panel open/closed on the daily page todo rows.
export default class extends Controller {
  static targets = ["panel", "chevron"];

  toggle() {
    const isHidden = this.panelTarget.classList.toggle("hidden");
    this.chevronTarget.classList.toggle("rotate-180", !isHidden);
  }
}
