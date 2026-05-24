import { Controller } from "@hotwired/stimulus";
import { requireTitle, postJSON, dispatchWizardEvent } from "controllers/wizard_helpers";

// Manages the three-step chain creation flow: name → step builder → review.
// Navigation is delegated to the parent creation-wizard controller via events.
// Chains are tasks-only; each step can optionally be assigned to a project.
export default class extends Controller {
  static targets = [
    // Name step
    "emoji",
    "title",
    // Step builder
    "stepCounter",
    "stepTitle",
    "dueDate",
    "projectSelect",
    // Review
    "reviewTitle",
    "previewList",
  ];

  static TASK_ICON = `<svg class="w-4 h-4 text-violet-500 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
    <path stroke-linecap="round" stroke-linejoin="round" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
  </svg>`;

  static DRAG_ICON = `<svg class="w-4 h-4 text-stone-300 shrink-0 cursor-grab" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
    <path stroke-linecap="round" stroke-linejoin="round" d="M4 8h16M4 16h16" />
  </svg>`;

  static DELETE_ICON = `<svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
    <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
  </svg>`;

  // ─── Private state ────────────────────────────────────

  #chainData = { title: "", emoji: "", items: [] };
  #dragSrcIndex = null;

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

  addStep() {
    if (!requireTitle(this.stepTitleTarget)) return;

    const projectSelect = this.hasProjectSelectTarget ? this.projectSelectTarget : null;
    const projectId = projectSelect?.value || null;
    const projectName = projectId
      ? projectSelect.options[projectSelect.selectedIndex].text
      : null;

    this.#chainData.items.push({
      title: this.stepTitleTarget.value.trim(),
      position: this.#chainData.items.length,
      due_date: this.hasDueDateTarget ? this.dueDateTarget.value || null : null,
      target_project_id: projectId,
      _projectName: projectName, // display-only, stripped before submission
    });

    this.#renderReview();
    dispatchWizardEvent(this.element, "wizard:navigate", { step: "chainReview" });
  }

  addAnotherStep() {
    this.#clearStepForm();
    dispatchWizardEvent(this.element, "wizard:navigate", { step: "chainStep" });
    requestAnimationFrame(() => this.stepTitleTarget.focus());
  }

  // ─── Review: delete & drag-to-reorder ─────────────────

  deleteStep(event) {
    const idx = parseInt(event.currentTarget.dataset.index, 10);
    this.#chainData.items.splice(idx, 1);
    this.#chainData.items.forEach((item, i) => (item.position = i));

    if (this.#chainData.items.length === 0) {
      dispatchWizardEvent(this.element, "wizard:navigate", { step: "chainStep" });
    } else {
      this.#renderReview();
    }
  }

  dragStart(event) {
    this.#dragSrcIndex = parseInt(event.currentTarget.dataset.index, 10);
    event.dataTransfer.effectAllowed = "move";
    event.currentTarget.classList.add("opacity-50");
  }

  dragEnd(event) {
    event.currentTarget.classList.remove("opacity-50");
    this.#dragSrcIndex = null;
  }

  dragOver(event) {
    event.preventDefault();
    event.dataTransfer.dropEffect = "move";
  }

  drop(event) {
    event.preventDefault();
    const targetIdx = parseInt(event.currentTarget.dataset.index, 10);
    if (this.#dragSrcIndex === null || this.#dragSrcIndex === targetIdx) return;

    const [moved] = this.#chainData.items.splice(this.#dragSrcIndex, 1);
    this.#chainData.items.splice(targetIdx, 0, moved);
    this.#chainData.items.forEach((item, i) => (item.position = i));

    this.#dragSrcIndex = null;
    this.#renderReview();
  }

  // ─── Review: submit ────────────────────────────────────

  async submitChain() {
    if (this.#chainData.items.length === 0) return;

    dispatchWizardEvent(this.element, "wizard:submitting");
    const resp = await postJSON("/chains", {
      chain: {
        title: this.#chainData.title,
        emoji: this.#chainData.emoji || null,
        // Strip display-only _projectName before sending
        chain_items_attributes: this.#chainData.items.map(
          // eslint-disable-next-line no-unused-vars
          ({ _projectName, ...rest }) => rest
        ),
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

  #updateStepCounter() {
    if (this.hasStepCounterTarget) {
      this.stepCounterTarget.textContent = `Step ${this.#chainData.items.length + 1}`;
    }
  }

  #clearStepForm() {
    if (this.hasStepTitleTarget) this.stepTitleTarget.value = "";
    if (this.hasProjectSelectTarget) this.projectSelectTarget.value = "";
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
    const subtitle = item._projectName
      ? this.#escapeHtml(item._projectName)
      : "";

    return `
      <li
        draggable="true"
        data-index="${index}"
        data-action="dragstart->wizard-chain#dragStart dragend->wizard-chain#dragEnd dragover->wizard-chain#dragOver drop->wizard-chain#drop"
        class="flex items-center gap-3 bg-stone-50 rounded-xl px-4 py-3 select-none"
      >
        ${this.constructor.DRAG_ICON}
        <span class="w-6 h-6 rounded-full bg-violet-100 text-violet-700 text-xs font-bold flex items-center justify-center shrink-0">${index + 1}</span>
        ${this.constructor.TASK_ICON}
        <div class="flex-1 min-w-0">
          <p class="font-medium text-stone-800 truncate">${this.#escapeHtml(item.title)}</p>
          ${subtitle ? `<p class="text-xs text-stone-400">${subtitle}</p>` : ""}
        </div>
        <button
          type="button"
          data-index="${index}"
          data-action="click->wizard-chain#deleteStep"
          class="text-stone-300 hover:text-red-400 transition-colors shrink-0 cursor-pointer"
          aria-label="Remove step"
        >
          ${this.constructor.DELETE_ICON}
        </button>
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
