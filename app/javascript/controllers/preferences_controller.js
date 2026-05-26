import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["thresholdRow", "notice"]

  connect() {
    this.syncThresholdVisibility()
  }

  save() {
    this.element.querySelector("form").requestSubmit()
  }

  // Called via turbo:submit-end on the form element
  saved(event) {
    if (!event.detail.success || !this.hasNoticeTarget) return
    this.noticeTarget.classList.remove("opacity-0")
    clearTimeout(this._hideTimer)
    this._hideTimer = setTimeout(() => {
      this.noticeTarget.classList.add("opacity-0")
    }, 2000)
  }

  // Fired when the stale-banner toggle changes — sync visibility then save
  staleBannerChanged() {
    this.syncThresholdVisibility()
    this.save()
  }

  // Dims and disables the threshold row when the stale banner is turned off
  syncThresholdVisibility() {
    if (!this.hasThresholdRowTarget) return
    const checkbox = this.element.querySelector('input[type="checkbox"][name="user[show_stale_banner]"]')
    if (!checkbox) return
    this.thresholdRowTarget.classList.toggle("opacity-40", !checkbox.checked)
    this.thresholdRowTarget.classList.toggle("pointer-events-none", !checkbox.checked)
  }
}
