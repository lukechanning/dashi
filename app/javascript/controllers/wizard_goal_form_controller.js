import { Controller } from "@hotwired/stimulus";
import { requireTitle, postJSON, dispatchWizardEvent, handleFormResponse } from "controllers/wizard_helpers";

export default class extends Controller {
  static targets = ["emoji", "title", "description"];

  async submit() {
    if (!requireTitle(this.titleTarget)) return;

    dispatchWizardEvent(this.element, "wizard:submitting");
    const resp = await postJSON("/goals", {
      goal: {
        title: this.titleTarget.value.trim(),
        emoji: this.emojiTarget.value.trim() || null,
        description: this.descriptionTarget.value.trim() || null,
      },
    });
    await handleFormResponse(this.element, resp);
  }
}
