import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "icon"]
  static values = { open: { type: Boolean, default: false } }

  toggle() {
    this.openValue = !this.openValue
  }

  openValueChanged() {
    if (this.openValue) {
      this.panelTarget.style.gridTemplateRows = "1fr"
      this.iconTarget.style.transform = "rotate(180deg)"
    } else {
      this.panelTarget.style.gridTemplateRows = "0fr"
      this.iconTarget.style.transform = "rotate(0deg)"
    }
  }
}
