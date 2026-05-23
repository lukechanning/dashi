import { Controller } from "@hotwired/stimulus"

// Manages a single todo row on the daily page.
// Handles the toggle via fetch (to get JSON with chain context) and
// shows the inline chain prompt when a chained todo is completed.
export default class extends Controller {
  static targets = ["check", "checkIcon", "title", "chainPrompt"]
  static values = { toggleUrl: String }

  async toggle() {
    const csrfToken = document.querySelector("meta[name='csrf-token']").content
    const resp = await fetch(this.toggleUrlValue, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": csrfToken,
        "Accept": "application/json",
      },
    })
    if (!resp.ok) return

    const data = await resp.json()
    const completed = data.completed_at !== null
    this.#updateCheckUI(completed)

    if (completed && data.chain) {
      if (data.chain.chain_complete) {
        this.#triggerCelebration(data.chain.chain_title)
        this.#hideChainPrompt()
      } else {
        this.#showChainPrompt()
      }
    } else {
      this.#hideChainPrompt()
    }
  }

  async activateNow({ params: { chainId, chainItemId } }) {
    const today = new Date().toISOString().split("T")[0]
    await this.#activateItem(chainId, chainItemId, today)
  }

  async activateWithDate({ params: { chainId, chainItemId } }) {
    const input = this.element.querySelector("[data-chain-date-input]")
    const dueDate = input?.value
    if (!dueDate) return
    await this.#activateItem(chainId, chainItemId, dueDate)
  }

  // ─── Private ──────────────────────────────────────────

  #updateCheckUI(completed) {
    if (!this.hasCheckTarget) return

    if (completed) {
      this.checkTarget.classList.add("bg-violet-500", "border-violet-500")
      this.checkTarget.classList.remove("border-stone-300", "hover:border-violet-400")
      if (this.hasCheckIconTarget) this.checkIconTarget.classList.remove("hidden")
      if (this.hasTitleTarget) {
        this.titleTarget.classList.add("line-through", "text-stone-400")
        this.titleTarget.classList.remove("text-stone-800")
      }
    } else {
      this.checkTarget.classList.remove("bg-violet-500", "border-violet-500")
      this.checkTarget.classList.add("border-stone-300", "hover:border-violet-400")
      if (this.hasCheckIconTarget) this.checkIconTarget.classList.add("hidden")
      if (this.hasTitleTarget) {
        this.titleTarget.classList.remove("line-through", "text-stone-400")
        this.titleTarget.classList.add("text-stone-800")
      }
    }
  }

  #showChainPrompt() {
    if (this.hasChainPromptTarget) {
      this.chainPromptTarget.classList.remove("hidden")
    }
  }

  #hideChainPrompt() {
    if (this.hasChainPromptTarget) {
      this.chainPromptTarget.classList.add("hidden")
    }
  }

  async #activateItem(chainId, chainItemId, dueDate) {
    const csrfToken = document.querySelector("meta[name='csrf-token']").content
    const resp = await fetch(`/chains/${chainId}/chain_items/${chainItemId}/activate`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken,
        "Accept": "application/json",
      },
      body: JSON.stringify({ due_date: dueDate }),
    })

    if (resp.ok) {
      this.#hideChainPrompt()
      // Reload the page so the newly activated todo appears in the list
      Turbo.visit(window.location.href)
    } else {
      alert("Something went wrong scheduling the next step. Please try again.")
    }
  }

  #triggerCelebration(chainTitle) {
    const html = `
      <div
        data-controller="celebration"
        data-action="click->celebration#dismiss"
        class="fixed inset-0 z-50 flex items-center justify-center bg-stone-900/40 backdrop-blur-sm opacity-0 transition-opacity duration-300"
      >
        <div class="bg-white rounded-3xl shadow-2xl px-10 py-8 max-w-sm w-full mx-4 text-center">
          <div class="w-16 h-16 rounded-2xl bg-emerald-100 flex items-center justify-center mx-auto mb-4">
            <svg class="w-8 h-8 text-emerald-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <p class="text-2xl font-bold text-stone-800">Chain complete! 🎉</p>
          <p class="text-stone-500 mt-2 text-sm leading-relaxed">"${this.#escapeHtml(chainTitle)}" — every step done.</p>
          <p class="text-xs text-stone-300 mt-5">Click anywhere to dismiss</p>
        </div>
      </div>
    `
    document.body.insertAdjacentHTML("beforeend", html)
  }

  #escapeHtml(str) {
    return String(str)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
  }
}
