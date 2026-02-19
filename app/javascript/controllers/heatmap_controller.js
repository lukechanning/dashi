import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["square", "tooltip"]

  connect() {
    this.squareTargets.forEach(square => {
      square.addEventListener("mouseenter", this.show.bind(this))
      square.addEventListener("mouseleave", this.hide.bind(this))
    })
  }

  show(event) {
    const sq = event.currentTarget
    const count = parseInt(sq.dataset.count)
    const label = count === 0 ? "No todos" : count === 1 ? "1 todo" : `${count} todos`
    this.tooltipTarget.textContent = `${sq.dataset.date} · ${label}`
    this.tooltipTarget.classList.remove("hidden")
    const containerRect = this.element.getBoundingClientRect()
    const squareRect = sq.getBoundingClientRect()
    this.tooltipTarget.style.left = `${squareRect.left - containerRect.left}px`
  }

  hide() {
    this.tooltipTarget.classList.add("hidden")
  }
}
