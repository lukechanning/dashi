import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["frequency", "customDays"]

  toggle() {
    if (this.frequencyTarget.value === "custom") {
      this.customDaysTarget.classList.remove("hidden")
    } else {
      this.customDaysTarget.classList.add("hidden")
    }
  }
}
