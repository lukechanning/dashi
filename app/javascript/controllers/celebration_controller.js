import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Allow the browser to paint the element at opacity-0 before transitioning in
    requestAnimationFrame(() => {
      this.element.classList.replace("opacity-0", "opacity-100")
    })
    // Auto-dismiss after 3.5 seconds
    this.timer = setTimeout(() => this.dismiss(), 3500)
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  dismiss() {
    clearTimeout(this.timer)
    this.element.classList.replace("opacity-100", "opacity-0")
    setTimeout(() => {
      if (this.element.isConnected) this.element.remove()
    }, 300)
  }
}
