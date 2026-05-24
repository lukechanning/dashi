import { Controller } from "@hotwired/stimulus";
import { requireTitle, postJSON, dispatchWizardEvent } from "controllers/wizard_helpers";

// Manages the three-step chain creation flow: name → step builder → review.
// Navigation is delegated to the parent creation-wizard controller via events.
export default class extends Controller {
  static targets = [
    // Name step
    "emoji",
    "title",
    // Step builder
    "stepCounter",
    "itemType",
    "emojiWrapper",
    "stepEmoji",
    "stepTitle",
    "stepDescription",
    "dueDate",
    "dueDateWrapper",
    // Review
    "reviewTitle",
    "previewList",
  ];

  static ICONS = {
    project: `<svg class="w-4 h-4 text-blue-500 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
      <path stroke-linecap="round" stroke-linejoin="round" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
    </svg>`,
    todo: `<svg class="w-4 h-4 text-violet-500 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
      <path stroke-linecap="round" stroke-linejoin="round" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
    </svg>`,
  };

  // ─── Private state ────────────────────────────────────

  #chainData = { title: "", emoji: "", items: [] };

  connect() {
    this.#resetChainData();
  }

  // ─── Name step ────────────────────────────────────────

  goToAddStep() {
    if (!requireTitle(this.titleTarget)) return;
    this.#chainData.title = this.titleTarget.value.trim();
    this.#chainData.emoji = this.emojiTarget.value.trim();
    this.#updateStepCounter();
    dispatchWizardEvent(this.element, "wizard:navigate", { step: "chainStep" });
  }

  // ─── Step builder ─────────────────────────────────────

  itemTypeChanged() {
    const isProject = this.#selectedItemType() === "project";
    this.emojiWrapperTarget.classList.toggle("hidden", !isProject);
    this.dueDateWrapperTarget.classList.toggle("hidden", isProject);
  }

  addStep() {
    if (!requireTitle(this.stepTitleTarget)) return;

    const type = this.#selectedItemType();
    this.#chainData.items.push({
      title: this.stepTitleTarget.value.trim(),
      item_type: type,
      position: this.#chainData.items.length,
      description: this.hasStepDescriptionTarget ? this.stepDescriptionTarget.value.trim() || null : null,
      emoji: type === "project" ? this.stepEmojiTarget.value.trim() || null : null,
      due_date: type === "todo" ? this.dueDateTarget.value || null : null,
    });

    this.#renderReview();
    dispatchWizardEvent(this.element, "wizard:navigate", { step: "chainReview" });
  }

  addAnotherStep() {
    this.#clearStepForm(); // also calls #updateStepCounter
    dispatchWizardEvent(this.element, "wizard:navigate", { step: "chainStep" });
    requestAnimationFrame(() => this.stepTitleTarget.focus());
  }

  // ─── Review step ─────────────────────────────────────

  async submitChain() {
    if (this.#chainData.items.length === 0) return;

    dispatchWizardEvent(this.element, "wizard:submitting");
    const resp = await postJSON("/chains", {
      chain: {
        title: this.#chainData.title,
        emoji: this.#chainData.emoji || null,
        chain_items_attributes: this.#chainData.items,
      },
    });

    if (resp.ok) {
      const { redirect } = await resp.json();
      this.#resetChainData();
      dispatchWizardEvent(this.element, "wizard:done", { redirect });
    } else {
      const data = await resp.json().catch(() => ({}));
      dispatchWizardEvent(this.element, "wizard:error", {
        message: data.errors?.join(", "),
      });
    }
  }

  // ─── Private helpers ─────────────────────────────────

  #resetChainData() {
    this.#chainData = { title: "", emoji: "", items: [] };
  }

  #selectedItemType() {
    return this.itemTypeTargets.find((r) => r.checked)?.value ?? "todo";
  }

  #updateStepCounter() {
    if (this.hasStepCounterTarget) {
      this.stepCounterTarget.textContent = `Step ${this.#chainData.items.length + 1}`;
    }
  }

  #clearStepForm() {
    if (this.hasStepTitleTarget) this.stepTitleTarget.value = "";
    if (this.hasStepDescriptionTarget) this.stepDescriptionTarget.value = "";
    if (this.hasStepEmojiTarget) this.stepEmojiTarget.value = "";
    this.itemTypeTargets.forEach((r) => { r.checked = r.value === "todo"; });
    this.emojiWrapperTarget.classList.add("hidden");
    this.dueDateWrapperTarget.classList.remove("hidden");
    this.#updateStepCounter();
  }

  #renderReview() {
    this.previewListTarget.innerHTML = this.#chainData.items
      .map((item, i) => this.#itemHtml(item, i))
      .join("");

    if (this.hasReviewTitleTarget) {
      const emoji = this.#chainData.emoji ? `${this.#chainData.emoji} ` : "";
      const count = this.#chainData.items.length;
      this.reviewTitleTarget.textContent =
        `${emoji}${this.#chainData.title} — ${count} step${count !== 1 ? "s" : ""}`;
    }
  }

  #itemHtml(item, index) {
    const typeLabel = item.item_type === "project" ? "Project" : "Task";
    const icon = this.constructor.ICONS[item.item_type] ?? this.constructor.ICONS.todo;
    return `
      <li class="flex items-center gap-3 bg-stone-50 rounded-xl px-4 py-3">
        <span class="w-6 h-6 rounded-full bg-violet-100 text-violet-700 text-xs font-bold flex items-center justify-center shrink-0">${index + 1}</span>
        ${icon}
        <div class="flex-1 min-w-0">
          <p class="font-medium text-stone-800 truncate">${this.#escapeHtml(item.title)}</p>
          <p class="text-xs text-stone-400">${typeLabel}</p>
        </div>
      </li>
    `;
  }

  #escapeHtml(str) {
    return str
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }
}
