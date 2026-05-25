import { Controller } from "@hotwired/stimulus";
import { requireTitle, postJSON, dispatchWizardEvent, handleFormResponse } from "controllers/wizard_helpers";

export default class extends Controller {
  static targets = ["title", "dueDate", "project"];

  async submit() {
    if (!requireTitle(this.titleTarget)) return;

    dispatchWizardEvent(this.element, "wizard:submitting");
    const resp = await postJSON("/todos", {
      todo: {
        title: this.titleTarget.value.trim(),
        due_date: this.dueDateTarget.value,
        project_id: this.projectTarget.value || null,
      },
    });
    await handleFormResponse(this.element, resp);
  }
}
