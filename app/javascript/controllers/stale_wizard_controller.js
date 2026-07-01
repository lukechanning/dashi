import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "step", "done", "currentNum", "banner"]
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

  dismissBanner() {
    this.close()
    if (!this.hasBannerTarget) return
    this.#postDismissal("stale")
    const banner = this.bannerTarget
    banner.style.transition = "opacity 0.3s"
    banner.style.opacity = "0"
    setTimeout(() => banner.remove(), 300)
  }

  #postDismissal(banner) {
    const csrfToken = document.querySelector("meta[name='csrf-token']").content
    return fetch("/dismissals", {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "X-CSRF-Token": csrfToken,
      },
      body: new URLSearchParams({ banner }),
    })
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

  advanceAfterSubmit(event) {
    if (!event.detail?.success) return
    this.advance()
  }

  toggleDelay({ params: { step } }) {
    this.#togglePanel(`delayForm${step}`)
  }

  toggleBreakUp({ params: { step } }) {
    this.#togglePanel(`breakUpForm${step}`)
  }

  async submitDelete(event) {
    const { todoId } = event.params
    await this.#withDisabledActions(event.currentTarget, async () => {
      try {
        const response = await fetch(`/todos/${todoId}`, {
          method: "DELETE",
          headers: { "X-CSRF-Token": this.#csrfToken(), "Accept": "application/json" },
        })
        if (response.ok) {
          this.advance()
        } else {
          alert("Something went wrong removing this task. Please try again.")
        }
      } catch {
        alert("Something went wrong removing this task. Please try again.")
      }
    })
  }

  async submitDelay(event) {
    const { todoId, step } = event.params
    const input = this.element.querySelector(`[data-stale-wizard-target="delayDateInput${step}"]`)
    const dueDate = input?.value
    if (!dueDate) return

    await this.#withDisabledActions(event.currentTarget, async () => {
      try {
        const response = await fetch(`/todos/${todoId}`, {
          method: "PATCH",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": this.#csrfToken(),
            "Accept": "application/json",
          },
          body: JSON.stringify({ todo: { due_date: dueDate } }),
        })
        if (response.ok) {
          this.advance()
        } else {
          alert("Something went wrong updating the due date. Please try again.")
        }
      } catch {
        alert("Something went wrong updating the due date. Please try again.")
      }
    })
  }

  async submitBreakUp(event) {
    const { todoId, step, projectId } = event.params
    const input = this.element.querySelector(`[data-stale-wizard-target="breakUpInput${step}"]`)
    const lines = input.value.split("\n").map(l => l.trim()).filter(Boolean)
    if (lines.length === 0) return

    await this.#withDisabledActions(event.currentTarget, async () => {
      try {
        // Create each subtask; abort if any request fails to avoid losing the original.
        for (const title of lines) {
          const todo = { title, due_date: new Date().toISOString().split("T")[0] }
          if (projectId) todo.project_id = projectId

          const response = await fetch("/todos", {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              "X-CSRF-Token": this.#csrfToken(),
              "Accept": "application/json",
            },
            body: JSON.stringify({ todo }),
          })
          if (!response.ok) {
            alert("Something went wrong creating a subtask. Your original task has not been removed.")
            return
          }
        }

        const deleteResponse = await fetch(`/todos/${todoId}`, {
          method: "DELETE",
          headers: { "X-CSRF-Token": this.#csrfToken(), "Accept": "application/json" },
        })
        if (deleteResponse.ok) {
          this.advance()
        } else {
          alert("Subtasks were created but the original task could not be removed. You can delete it manually.")
        }
      } catch {
        alert("Something went wrong creating a subtask. Your original task has not been removed.")
      }
    })
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
    setTimeout(() => {
      if (!this.element.isConnected) return
      if (window.Turbo?.visit) {
        window.Turbo.visit(window.location.href)
      } else {
        window.location.reload()
      }
    }, 1200)
  }

  #togglePanel(targetName) {
    const panel = this.element.querySelector(`[data-stale-wizard-target="${targetName}"]`)
    if (panel) panel.classList.toggle("hidden")
  }

  #csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content || ""
  }

  async #withDisabledActions(button, callback) {
    const step = button.closest("[data-stale-wizard-target='step']")
    const buttons = Array.from(step?.querySelectorAll("button") || [button])
    buttons.forEach((actionButton) => { actionButton.disabled = true })
    try {
      await callback()
    } finally {
      buttons.forEach((actionButton) => { actionButton.disabled = false })
    }
  }
}
