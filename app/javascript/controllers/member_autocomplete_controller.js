import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "menu", "list", "empty", "inviteLink"]
  static values = {
    inviteUrl: String,
    suggestionsUrl: String,
  }

  connect() {
    this.activeIndex = -1
    this.matches = []
    this.requestId = 0
  }

  async search() {
    const query = this.inputTarget.value.trim().toLowerCase()
    this.#syncInviteLink(query)
    const requestId = ++this.requestId

    if (query.length < 2) {
      this.matches = []
      this.#hide()
      return
    }

    const url = new URL(this.suggestionsUrlValue, window.location.origin)
    url.searchParams.set("q", query)
    const response = await fetch(url, { headers: { Accept: "application/json" } })
    if (!response.ok || requestId !== this.requestId) return

    const matches = await response.json()
    if (requestId !== this.requestId) return

    this.matches = matches
    this.activeIndex = -1
    this.#render()
  }

  navigate(event) {
    if (this.menuTarget.classList.contains("hidden")) return

    if (event.key === "ArrowDown") {
      event.preventDefault()
      this.activeIndex = Math.min(this.activeIndex + 1, this.matches.length - 1)
      this.#syncActiveOption()
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      this.activeIndex = Math.max(this.activeIndex - 1, 0)
      this.#syncActiveOption()
    } else if (event.key === "Enter" && this.activeIndex >= 0) {
      event.preventDefault()
      this.#selectUser(this.matches[this.activeIndex])
    } else if (event.key === "Escape") {
      this.#hide()
    }
  }

  deferHide() {
    setTimeout(() => this.#hide(), 150)
  }

  #render() {
    this.listTarget.replaceChildren()

    this.matches.forEach((user, index) => {
      const button = document.createElement("button")
      button.type = "button"
      button.className = "block w-full px-3 py-2 text-left hover:bg-app-surface-muted transition-colors"
      button.dataset.index = index
      button.addEventListener("mousedown", (event) => event.preventDefault())
      button.addEventListener("click", () => this.#selectUser(user))

      const name = document.createElement("span")
      name.className = "block text-sm font-medium text-app-text"
      name.textContent = user.name

      const email = document.createElement("span")
      email.className = "block text-xs text-app-faint"
      email.textContent = user.email

      button.append(name, email)
      this.listTarget.append(button)
    })

    this.listTarget.classList.toggle("hidden", this.matches.length === 0)
    if (this.hasEmptyTarget) {
      this.emptyTarget.classList.toggle("hidden", this.matches.length > 0)
    }

    const hasContent = this.matches.length > 0 || this.hasEmptyTarget
    this.menuTarget.classList.toggle("hidden", !hasContent)
  }

  #syncActiveOption() {
    this.listTarget.querySelectorAll("button").forEach((button, index) => {
      button.classList.toggle("bg-app-surface-muted", index === this.activeIndex)
    })
  }

  #selectUser(user) {
    this.inputTarget.value = user.email
    this.#hide()
  }

  #syncInviteLink(query) {
    if (!this.hasInviteLinkTarget) return

    const url = new URL(this.inviteUrlValue, window.location.origin)
    if (query) url.searchParams.set("email", query)
    this.inviteLinkTarget.href = url.pathname + url.search
  }

  #hide() {
    this.menuTarget.classList.add("hidden")
  }
}
