import { Controller } from "@hotwired/stimulus";
import { requireTitle, postJSON, dispatchWizardEvent, handleFormResponse } from "controllers/wizard_helpers";

export default class extends Controller {
  static targets = ["emoji", "title", "description", "goal"];

  async submit() {
    if (!requireTitle(this.titleTarget)) return;

    dispatchWizardEvent(this.element, "wizard:submitting");
    const resp = await postJSON("/projects", {
      project: {
        title: this.titleTarget.value.trim(),
        emoji: this.emojiTarget.value.trim() || null,
        description: this.descriptionTarget.value.trim() || null,
        goal_id: this.goalTarget.value || null,
      },
    });
    await handleFormResponse(this.element, resp);
  }
}
