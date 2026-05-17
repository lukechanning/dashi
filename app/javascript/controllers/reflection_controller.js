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

  // "Let it go" — the button_to generates a <form>; Turbo fires turbo:submit-end on it
  letItGo(event) {
    const todoId = event.currentTarget.dataset.todoId
    const form = event.currentTarget.closest("form")
    form?.addEventListener("turbo:submit-end", () => this.#removeRow(todoId), { once: true })
  }

  async saveNote(event) {
    event.preventDefault()
    const body = this.noteBodyTarget.value.trim()
    if (!body) return

    const response = await this.#postNote(event.target.action, body)

    if (response.ok) {
      this.noteBodyTarget.value = ""
      this.noteBodyTarget.placeholder = "Saved!"
      setTimeout(() => { this.noteBodyTarget.placeholder = "What did you learn this week? What would you do differently?" }, 2000)
    } else {
      this.noteBodyTarget.placeholder = "Couldn't save — try again"
    }
  }

  async finish() {
    // Save note if there's content, then close
    const body = this.hasNoteBodyTarget ? this.noteBodyTarget.value.trim() : ""
    if (body && this.hasNoteFormTarget) {
      const response = await this.#postNote(this.noteFormTarget.action, body)
      if (!response.ok) {
        // Note failed to save — stay open so the user can retry
        this.noteBodyTarget.placeholder = "Couldn't save — try again"
        return
      }
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

  #postNote(url, body) {
    const csrfToken = document.querySelector("meta[name='csrf-token']").content
    return fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "X-CSRF-Token": csrfToken,
      },
      body: new URLSearchParams({ "note[body]": body }),
    })
  }
}
