import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { current: String }

  connect() {
    const detected = Intl.DateTimeFormat().resolvedOptions().timeZone
    if (!detected || detected === this.currentValue) return

    const meta = document.querySelector("meta[name='csrf-token']")
    fetch("/user/timezone", {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": meta?.content ?? ""
      },
      body: JSON.stringify({ timezone: detected })
    }).then(r => {
      if (r.ok) window.location.reload()
    })
  }
}
