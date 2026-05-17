import { Controller } from "@hotwired/stimulus"

const MAX_TASKS = 3
const POMODORO_SECONDS = 25 * 60

export default class extends Controller {
  static targets = [
    "panel", "view",
    "checkbox", "checkmark", "checkIcon",
    "selectionCount", "startBtn",
    "taskList",
    "timerDisplay", "timerBtn",
  ]

  connect() {
    this.selected = []       // [{ id, title, toggleUrl }]
    this.timerRemaining = POMODORO_SECONDS
    this.timerRunning = false
    this.timerInterval = null
    this.timerStartedAt = null
    this.timerElapsedAtPause = 0
  }

  disconnect() {
    this.#clearTimer()
  }

  // ── Panel ────────────────────────────────────────────

  openPanel() {
    this.panelTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
  }

  closePanel() {
    this.panelTarget.classList.add("hidden")
    document.body.style.overflow = ""
  }

  selectionChanged(event) {
    const checkbox = event.currentTarget.querySelector("input[type=checkbox]")
    const id = checkbox.value
    const title = checkbox.dataset.title
    const toggleUrl = checkbox.dataset.toggleUrl
    const label = event.currentTarget
    const checkmark = label.querySelector("[data-focus-mode-target='checkmark']")
    const checkIcon = label.querySelector("[data-focus-mode-target='checkIcon']")

    // The browser has already toggled checkbox.checked before the change event fires,
    // so checked===true means the user just selected this item.
    if (checkbox.checked) {
      if (this.selected.length >= MAX_TASKS) {
        // At the limit — reject this selection
        checkbox.checked = false
        return
      }
      this.selected.push({ id, title, toggleUrl })
      if (checkmark) {
        checkmark.classList.add("bg-violet-500", "border-violet-500")
        checkmark.classList.remove("border-stone-300")
      }
      if (checkIcon) checkIcon.classList.remove("hidden")
    } else {
      // User just unchecked this item
      this.selected = this.selected.filter(t => t.id !== id)
      if (checkmark) {
        checkmark.classList.remove("bg-violet-500", "border-violet-500")
        checkmark.classList.add("border-stone-300")
      }
      if (checkIcon) checkIcon.classList.add("hidden")
    }

    this.#updateSelectionUI()
  }

  startSession() {
    if (this.selected.length === 0) return
    this.closePanel()
    this.#renderTaskList()
    this.viewTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
    document.getElementById("fab-new-todo")?.classList.add("!hidden")
  }

  endSession() {
    this.#clearTimer()
    this.viewTarget.classList.add("hidden")
    document.body.style.overflow = ""
    document.getElementById("fab-new-todo")?.classList.remove("!hidden")
    // Reset timer state
    this.timerRemaining = POMODORO_SECONDS
    this.timerRunning = false
    this.timerElapsedAtPause = 0
    this.#renderTimer()
    if (this.hasTimerBtnTarget) this.timerBtnTarget.textContent = "Start"
  }

  // ── Timer ────────────────────────────────────────────

  toggleTimer() {
    if (this.timerRunning) {
      this.#pauseTimer()
    } else {
      this.#startTimer()
    }
  }

  resetTimer() {
    this.#clearTimer()
    this.timerRemaining = POMODORO_SECONDS
    this.timerRunning = false
    this.timerElapsedAtPause = 0
    this.#renderTimer()
    if (this.hasTimerBtnTarget) this.timerBtnTarget.textContent = "Start"
  }

  async toggleTask(event) {
    const btn = event.currentTarget
    const todoId = btn.dataset.todoId
    const toggleUrl = btn.dataset.toggleUrl
    const csrfToken = document.querySelector("meta[name='csrf-token']").content

    const response = await fetch(toggleUrl, {
      method: "PATCH",
      headers: { "X-CSRF-Token": csrfToken, "Accept": "application/json" },
    })

    if (response.ok) {
      const data = await response.json()
      const completed = data.completed_at !== null
      this.#updateTaskRowState(btn, completed)
    }
  }

  // ── Private ──────────────────────────────────────────

  #updateSelectionUI() {
    const count = this.selected.length
    if (this.hasSelectionCountTarget) {
      this.selectionCountTarget.textContent = `${count} of ${MAX_TASKS} selected`
    }
    if (this.hasStartBtnTarget) {
      this.startBtnTarget.disabled = count === 0
    }
  }

  #renderTaskList() {
    if (!this.hasTaskListTarget) return
    this.taskListTarget.innerHTML = this.selected.map(task => `
      <div class="flex items-center gap-3 bg-stone-900 rounded-2xl p-4" data-todo-id="${task.id}">
        <button
          data-action="focus-mode#toggleTask"
          data-todo-id="${task.id}"
          data-toggle-url="${task.toggleUrl}"
          class="flex-shrink-0 w-7 h-7 rounded-full border-2 border-stone-600 hover:border-violet-400 flex items-center justify-center transition-colors cursor-pointer"
        >
        </button>
        <span class="text-white text-base flex-1">${task.title}</span>
      </div>
    `).join("")
  }

  #updateTaskRowState(btn, completed) {
    if (completed) {
      btn.classList.add("bg-violet-600", "border-violet-600")
      btn.classList.remove("border-stone-600")
      btn.innerHTML = `<svg class="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="3"><path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"/></svg>`
      const title = btn.closest("[data-todo-id]")?.querySelector("span")
      if (title) title.classList.add("line-through", "text-stone-500")
    } else {
      btn.classList.remove("bg-violet-600", "border-violet-600")
      btn.classList.add("border-stone-600")
      btn.innerHTML = ""
      const title = btn.closest("[data-todo-id]")?.querySelector("span")
      if (title) title.classList.remove("line-through", "text-stone-500")
    }
  }

  #startTimer() {
    this.timerRunning = true
    this.timerStartedAt = Date.now()
    if (this.hasTimerBtnTarget) this.timerBtnTarget.textContent = "Pause"
    this.timerInterval = setInterval(() => this.#tick(), 500)
  }

  #pauseTimer() {
    this.#clearTimer()
    this.timerElapsedAtPause += Date.now() - this.timerStartedAt
    this.timerRunning = false
    if (this.hasTimerBtnTarget) this.timerBtnTarget.textContent = "Resume"
  }

  #tick() {
    const elapsed = this.timerElapsedAtPause + (Date.now() - this.timerStartedAt)
    const remaining = Math.max(0, POMODORO_SECONDS * 1000 - elapsed)
    this.timerRemaining = Math.ceil(remaining / 1000)
    this.#renderTimer()
    if (this.timerRemaining === 0) {
      this.#clearTimer()
      this.timerRunning = false
      if (this.hasTimerBtnTarget) this.timerBtnTarget.textContent = "Start"
      this.#ringBell()
    }
  }

  #renderTimer() {
    if (!this.hasTimerDisplayTarget) return
    const m = Math.floor(this.timerRemaining / 60).toString().padStart(2, "0")
    const s = (this.timerRemaining % 60).toString().padStart(2, "0")
    this.timerDisplayTarget.textContent = `${m}:${s}`
  }

  #clearTimer() {
    if (this.timerInterval) {
      clearInterval(this.timerInterval)
      this.timerInterval = null
    }
  }

  #ringBell() {
    try {
      const ctx = new (window.AudioContext || window.webkitAudioContext)()
      const osc = ctx.createOscillator()
      const gain = ctx.createGain()
      osc.connect(gain)
      gain.connect(ctx.destination)
      osc.frequency.value = 528
      gain.gain.setValueAtTime(0.3, ctx.currentTime)
      gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 1.5)
      osc.start(ctx.currentTime)
      osc.stop(ctx.currentTime + 1.5)
    } catch {
      // Audio not available — fail silently
    }
  }
}
