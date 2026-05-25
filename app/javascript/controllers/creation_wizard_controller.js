import { Controller } from "@hotwired/stimulus";

// Orchestrates the creation wizard overlay: step navigation, back/close, and
// header state. All form logic lives in child controllers (wizard-task-form,
// wizard-project-form, wizard-goal-form, wizard-chain) which communicate via
// bubbling CustomEvents on the "wizard:*" namespace.
export default class extends Controller {
  static targets = ["overlay", "step", "backBtn", "stepTitle"];

  static STEP_TITLES = {
    type: "What are you creating?",
    task: "New task",
    project: "New project",
    goal: "New goal",
    chainName: "Name your chain",
    chainStep: "Add chain step",
    chainReview: "Review your chain",
    submitting: "Creating…",
  };

  // ─── Private state ────────────────────────────────────

  #currentStep = "type";
  #stepHistory = [];

  // ─── Lifecycle ────────────────────────────────────────

  connect() {
    this.#reset();
    // If Turbo restored a cached page with the wizard open, close it cleanly.
    if (this.hasOverlayTarget && !this.overlayTarget.classList.contains("hidden")) {
      this.overlayTarget.classList.add("hidden");
      document.body.style.overflow = "";
    }
    this.element.addEventListener("wizard:submitting", this.#onSubmitting);
    this.element.addEventListener("wizard:navigate", this.#onNavigate);
    this.element.addEventListener("wizard:done", this.#onDone);
    this.element.addEventListener("wizard:error", this.#onError);
  }

  disconnect() {
    this.element.removeEventListener("wizard:submitting", this.#onSubmitting);
    this.element.removeEventListener("wizard:navigate", this.#onNavigate);
    this.element.removeEventListener("wizard:done", this.#onDone);
    this.element.removeEventListener("wizard:error", this.#onError);
  }

  // ─── Public actions ───────────────────────────────────

  open() {
    this.overlayTarget.classList.remove("hidden");
    document.body.style.overflow = "hidden";
    this.#showStep("type");
    requestAnimationFrame(() => {
      this.element.querySelector("[data-step-name='type'] button")?.focus();
    });
  }

  close() {
    this.overlayTarget.classList.add("hidden");
    document.body.style.overflow = "";
    this.#reset();
  }

  back() {
    const prev = this.#stepHistory.pop();
    if (prev) this.#showStep(prev, false);
  }

  selectType({ params: { type } }) {
    this.#showStep(type === "chain" ? "chainName" : type);
    if (type !== "chain") {
      requestAnimationFrame(() => {
        this.element.querySelector(`[data-step-name='${type}'] input[type='text']`)?.focus();
      });
    }
  }

  // ─── Child event handlers ─────────────────────────────

  #onSubmitting = () => {
    this.#showStep("submitting");
  };

  #onNavigate = ({ detail: { step } }) => {
    this.#showStep(step);
  };

  #onDone = ({ detail: { redirect } }) => {
    this.close();
    Turbo.visit(redirect || window.location.href);
  };

  #onError = ({ detail: { message } }) => {
    this.back();
    alert(message || "Something went wrong. Please try again.");
  };

  // ─── Private helpers ─────────────────────────────────

  #reset() {
    this.#currentStep = "type";
    this.#stepHistory = [];
    this.#resetStepDOM();
  }

  // Resets step visibility and header to the initial "type" state.
  // Called on connect() and close() so Turbo cache restores are always clean.
  #resetStepDOM() {
    this.stepTargets.forEach((el) => {
      el.classList.toggle("hidden", el.dataset.stepName !== "type");
    });
    if (this.hasBackBtnTarget) this.backBtnTarget.classList.add("hidden");
    if (this.hasStepTitleTarget) {
      this.stepTitleTarget.textContent = this.constructor.STEP_TITLES.type;
    }
  }

  #showStep(name, pushHistory = true) {
    if (pushHistory && this.#currentStep !== name) {
      this.#stepHistory.push(this.#currentStep);
    }
    this.#currentStep = name;

    this.stepTargets.forEach((el) => {
      el.classList.toggle("hidden", el.dataset.stepName !== name);
    });

    this.backBtnTarget.classList.toggle("hidden", ["type", "submitting"].includes(name));
    this.stepTitleTarget.textContent = this.constructor.STEP_TITLES[name] ?? "";
  }
}
