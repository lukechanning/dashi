import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "noteForm", "noteBody"]

  open() {
    this.overlayTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
  }

  close() {
    this.overlayTarget.classList.add("hidden")
    document.body.style.overflow = ""
  }

  // "Keep it" — just remove the row from the overlay UI, task stays in DB
  carryForward(event) {
    const todoId = event.currentTarget.dataset.todoId
    this.#removeRow(todoId)
  }

  // "Let it go" — the button_to already DELETEs the todo via Turbo;
  // we remove the row from the overlay after the delete completes
  letItGo(event) {
    const todoId = event.currentTarget.dataset.todoId
    // Wait for the Turbo delete to fire, then remove the row
    event.currentTarget.closest("[data-todo-id]")?.addEventListener(
      "turbo:submit-end",
      () => this.#removeRow(todoId),
      { once: true }
    )
  }

  async saveNote(event) {
    event.preventDefault()
    const body = this.noteBodyTarget.value.trim()
    if (!body) return

    const form = event.target
    const url = form.action
    const csrfToken = document.querySelector("meta[name='csrf-token']").content

    await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "X-CSRF-Token": csrfToken,
      },
      body: new URLSearchParams({ "note[body]": body }),
    })

    this.noteBodyTarget.value = ""
    this.noteBodyTarget.placeholder = "Saved!"
    setTimeout(() => { this.noteBodyTarget.placeholder = "What did you learn this week? What would you do differently?" }, 2000)
  }

  async finish() {
    // Save note if there's content, then close
    const body = this.hasNoteBodyTarget ? this.noteBodyTarget.value.trim() : ""
    if (body && this.hasNoteFormTarget) {
      const form = this.noteFormTarget
      const url = form.action
      const csrfToken = document.querySelector("meta[name='csrf-token']").content
      await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "X-CSRF-Token": csrfToken,
        },
        body: new URLSearchParams({ "note[body]": body }),
      })
    }
    this.close()
  }

  #removeRow(todoId) {
    const row = this.overlayTarget.querySelector(`[data-todo-id="${todoId}"]`)
    if (row) {
      row.style.opacity = "0"
      row.style.transition = "opacity 0.2s"
      setTimeout(() => row.remove(), 200)
    }
  }
}
