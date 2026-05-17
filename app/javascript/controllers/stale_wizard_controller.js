import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "step", "done", "currentNum"]
  static values = { currentIndex: { type: Number, default: 0 } }

  open() {
    this.overlayTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
    this.showStep(this.currentIndexValue)
  }

  close() {
    this.overlayTarget.classList.add("hidden")
    document.body.style.overflow = ""
  }

  advance() {
    const next = this.currentIndexValue + 1
    if (next >= this.stepTargets.length) {
      this.showDone()
    } else {
      this.currentIndexValue = next
      this.showStep(next)
    }
  }

  prev() {
    const prev = this.currentIndexValue - 1
    if (prev >= 0) {
      this.currentIndexValue = prev
      this.showStep(prev)
    }
  }

  next() {
    const next = this.currentIndexValue + 1
    if (next < this.stepTargets.length) {
      this.currentIndexValue = next
      this.showStep(next)
    }
  }

  advanceAfterSubmit() {
    this.advance()
  }

  toggleDelay({ params: { step } }) {
    this.#togglePanel(`delayForm${step}`)
  }

  toggleBreakUp({ params: { step } }) {
    this.#togglePanel(`breakUpForm${step}`)
  }

  async submitBreakUp({ params: { todoId, step } }) {
    const input = this.targets.find(`breakUpInput${step}`)
    const lines = input.value.split("\n").map(l => l.trim()).filter(Boolean)
    if (lines.length === 0) return

    const csrfToken = document.querySelector("meta[name='csrf-token']").content

    // Create each subtask — abort if any request fails to avoid losing the original
    for (const title of lines) {
      const response = await fetch("/todos", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          "Accept": "application/json",
        },
        body: JSON.stringify({ todo: { title, due_date: new Date().toISOString().split("T")[0] } }),
      })
      if (!response.ok) {
        alert("Something went wrong creating a subtask. Your original task has not been removed.")
        return
      }
    }

    // All subtasks created — safe to delete the original
    await fetch(`/todos/${todoId}`, {
      method: "DELETE",
      headers: { "X-CSRF-Token": csrfToken, "Accept": "application/json" },
    })

    this.advance()
  }

  showStep(index) {
    this.stepTargets.forEach((step, i) => {
      step.classList.toggle("hidden", i !== index)
    })
    if (this.hasCurrentNumTarget) {
      this.currentNumTarget.textContent = index + 1
    }
  }

  showDone() {
    this.stepTargets.forEach(step => step.classList.add("hidden"))
    this.doneTarget.classList.remove("hidden")
    setTimeout(() => { if (this.element.isConnected) window.location.reload() }, 1200)
  }

  #togglePanel(targetName) {
    const panel = this.targets.find(targetName)
    if (panel) panel.classList.toggle("hidden")
  }
}
