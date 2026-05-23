import { Controller } from "@hotwired/stimulus";

// Unified creation wizard — opens as a fixed overlay from any "+" entry point.
// Handles creating: standalone Task, Project, Goal, or a Chain (ordered sequence).
export default class extends Controller {
  static targets = [
    "overlay",
    "step",
    "backBtn",
    "stepTitle",
    // Task form
    "taskTitle",
    "taskDueDate",
    "taskProject",
    // Project form
    "projectEmoji",
    "projectTitle",
    "projectDescription",
    "projectGoal",
    // Goal form
    "goalEmoji",
    "goalTitle",
    "goalDescription",
    // Chain — name
    "chainEmoji",
    "chainTitle",
    // Chain — step builder
    "stepCounter",
    "stepItemType",
    "stepEmojiWrapper",
    "stepEmoji",
    "stepTitle",
    "stepDescription",
    "stepDueDate",
    "stepDueDateWrapper",
    // Chain — review
    "chainReviewTitle",
    "chainPreviewList",
    "submitChainBtn",
  ];

  connect() {
    this.#resetChainData();
    this.#currentStep = "type";
    this.#stepHistory = [];
  }

  // ─── Public: open / close ─────────────────────────────

  open() {
    this.overlayTarget.classList.remove("hidden");
    document.body.style.overflow = "hidden";
    this.#showStep("type");
    // Focus first input after transition
    requestAnimationFrame(() => {
      const firstInput = this.element.querySelector(
        "[data-step-name='type'] button",
      );
      firstInput?.focus();
    });
  }

  close() {
    this.overlayTarget.classList.add("hidden");
    document.body.style.overflow = "";
    this.#resetChainData();
    this.#stepHistory = [];
  }

  back() {
    const prev = this.#stepHistory.pop();
    if (prev) this.#showStep(prev, false);
  }

  // ─── Type selection ───────────────────────────────────

  selectType({ params: { type } }) {
    if (type === "chain") {
      this.#showStep("chainName");
    } else {
      this.#showStep(type);
      // Autofocus the first text input
      requestAnimationFrame(() => {
        const input = this.element.querySelector(
          `[data-step-name='${type}'] input[type='text']`,
        );
        input?.focus();
      });
    }
  }

  // ─── Chain: name step ────────────────────────────────

  goToAddStep() {
    const title = this.chainTitleTarget.value.trim();
    if (!title) {
      this.chainTitleTarget.focus();
      this.chainTitleTarget.classList.add(
        "ring-2",
        "ring-red-400",
        "border-red-400",
      );
      return;
    }
    this.chainTitleTarget.classList.remove(
      "ring-2",
      "ring-red-400",
      "border-red-400",
    );
    this.chainData.title = title;
    this.chainData.emoji = this.chainEmojiTarget.value.trim();
    this.#updateStepCounter();
    this.#showStep("chainStep");
    requestAnimationFrame(() => this.stepTitleTarget.focus());
  }

  // ─── Chain: step type toggling ───────────────────────

  stepTypeChanged() {
    const type = this.#selectedStepType();
    // Show emoji field only for projects
    this.stepEmojiWrapperTarget.classList.toggle("hidden", type !== "project");
    // Due date is only meaningful for todo steps — always hide for project steps
    this.stepDueDateWrapperTarget.classList.toggle(
      "hidden",
      type === "project",
    );
  }

  // ─── Chain: add step ─────────────────────────────────

  addStep() {
    const title = this.stepTitleTarget.value.trim();
    if (!title) {
      this.stepTitleTarget.focus();
      this.stepTitleTarget.classList.add(
        "ring-2",
        "ring-red-400",
        "border-red-400",
      );
      return;
    }
    this.stepTitleTarget.classList.remove(
      "ring-2",
      "ring-red-400",
      "border-red-400",
    );

    const type = this.#selectedStepType();
    const step = {
      title,
      item_type: type,
      position: this.chainData.items.length,
      description: this.stepDescriptionTarget.value.trim() || null,
      emoji:
        type === "project" ? this.stepEmojiTarget.value.trim() || null : null,
      due_date:
        type === "todo" || this.chainData.items.length === 0
          ? this.stepDueDateTarget.value || null
          : null,
    };
    this.chainData.items.push(step);

    this.#renderChainPreview();
    this.#showStep("chainReview");
  }

  addAnotherStep() {
    this.#clearStepForm();
    this.#updateStepCounter();
    this.#showStep("chainStep");
    requestAnimationFrame(() => this.stepTitleTarget.focus());
  }

  // ─── Standalone submits ──────────────────────────────

  async submitTask() {
    const title = this.taskTitleTarget.value.trim();
    if (!title) {
      this.taskTitleTarget.focus();
      return;
    }

    const payload = {
      todo: {
        title,
        due_date: this.taskDueDateTarget.value,
        project_id: this.taskProjectTarget.value || null,
      },
    };
    await this.#submit("/todos", payload);
  }

  async submitProject() {
    const title = this.projectTitleTarget.value.trim();
    if (!title) {
      this.projectTitleTarget.focus();
      return;
    }

    const payload = {
      project: {
        title,
        emoji: this.projectEmojiTarget.value.trim() || null,
        description: this.projectDescriptionTarget.value.trim() || null,
        goal_id: this.projectGoalTarget.value || null,
      },
    };
    await this.#submit("/projects", payload);
  }

  async submitGoal() {
    const title = this.goalTitleTarget.value.trim();
    if (!title) {
      this.goalTitleTarget.focus();
      return;
    }

    const payload = {
      goal: {
        title,
        emoji: this.goalEmojiTarget.value.trim() || null,
        description: this.goalDescriptionTarget.value.trim() || null,
      },
    };
    await this.#submit("/goals", payload);
  }

  // ─── Chain submit ────────────────────────────────────

  async submitChain() {
    if (this.chainData.items.length === 0) return;
    this.#showStep("submitting");

    const payload = {
      chain: {
        title: this.chainData.title,
        emoji: this.chainData.emoji || null,
        chain_items_attributes: this.chainData.items,
      },
    };

    const resp = await this.#postJSON("/chains", payload);
    if (resp.ok) {
      const data = await resp.json();
      this.close();
      Turbo.visit(data.redirect || window.location.href);
    } else {
      this.#showStep("chainReview");
      const data = await resp.json().catch(() => ({}));
      alert(
        data.errors?.join(", ") || "Something went wrong. Please try again.",
      );
    }
  }

  // ─── Private helpers ──────────────────────────────────

  #currentStep = "type";
  #stepHistory = [];
  chainData = {};

  #resetChainData() {
    this.chainData = { title: "", emoji: "", items: [] };
  }

  #showStep(name, pushHistory = true) {
    if (pushHistory && this.#currentStep !== name) {
      this.#stepHistory.push(this.#currentStep);
    }
    this.#currentStep = name;

    this.stepTargets.forEach((el) => {
      el.classList.toggle("hidden", el.dataset.stepName !== name);
    });

    // Back button: hide on type step and submitting
    const showBack = !["type", "submitting"].includes(name);
    this.backBtnTarget.classList.toggle("hidden", !showBack);

    // Step title
    const titles = {
      type: "What are you creating?",
      task: "New task",
      project: "New project",
      goal: "New goal",
      chainName: "Name your chain",
      chainStep: `Chain step ${this.chainData.items.length + 1}`,
      chainReview: "Review your chain",
      submitting: "Creating…",
    };
    this.stepTitleTarget.textContent = titles[name] || "";
  }

  #selectedStepType() {
    const checked = this.stepItemTypeTargets.find((r) => r.checked);
    return checked?.value || "todo";
  }

  #updateStepCounter() {
    if (this.hasStepCounterTarget) {
      this.stepCounterTarget.textContent = `Step ${this.chainData.items.length + 1}`;
    }
  }

  #clearStepForm() {
    if (this.hasStepTitleTarget) this.stepTitleTarget.value = "";
    if (this.hasStepDescriptionTarget) this.stepDescriptionTarget.value = "";
    if (this.hasStepEmojiTarget) this.stepEmojiTarget.value = "";
    // Reset radio to "todo"
    this.stepItemTypeTargets.forEach((r) => {
      r.checked = r.value === "todo";
    });
    this.stepEmojiWrapperTarget.classList.add("hidden");
    this.stepDueDateWrapperTarget.classList.remove("hidden");
    this.#updateStepCounter();
  }

  #renderChainPreview() {
    const list = this.chainPreviewListTarget;
    list.innerHTML = this.chainData.items
      .map((item, i) => {
        const typeLabel = item.item_type === "project" ? "Project" : "Task";
        const icon =
          item.item_type === "project"
            ? `<svg class="w-4 h-4 text-blue-500 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" /></svg>`
            : `<svg class="w-4 h-4 text-violet-500 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" /></svg>`;

        return `
        <li class="flex items-center gap-3 bg-stone-50 rounded-xl px-4 py-3">
          <span class="w-6 h-6 rounded-full bg-violet-100 text-violet-700 text-xs font-bold flex items-center justify-center shrink-0">${i + 1}</span>
          ${icon}
          <div class="flex-1 min-w-0">
            <p class="font-medium text-stone-800 truncate">${this.#escapeHtml(item.title)}</p>
            <p class="text-xs text-stone-400">${typeLabel}</p>
          </div>
        </li>
      `;
      })
      .join("");

    if (this.hasChainReviewTitleTarget) {
      const emoji = this.chainData.emoji ? `${this.chainData.emoji} ` : "";
      this.chainReviewTitleTarget.textContent = `${emoji}${this.chainData.title} — ${this.chainData.items.length} step${this.chainData.items.length !== 1 ? "s" : ""}`;
    }
  }

  async #submit(url, payload) {
    this.#showStep("submitting");
    const resp = await this.#postJSON(url, payload);
    if (resp.ok) {
      const data = await resp.json();
      this.close();
      Turbo.visit(data.redirect || window.location.href);
    } else {
      // Go back to the form step
      this.back();
      const data = await resp.json().catch(() => ({}));
      alert(
        data.errors?.join(", ") || "Something went wrong. Please try again.",
      );
    }
  }

  #postJSON(url, body) {
    return fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")
          .content,
        Accept: "application/json",
      },
      body: JSON.stringify(body),
    });
  }

  #escapeHtml(str) {
    return str
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }
}
