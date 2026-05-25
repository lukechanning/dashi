// Shared utilities for the creation wizard's child form controllers.

export const ERROR_CLASSES = ["ring-2", "ring-red-400", "border-red-400"];

// Validates that `input` has a non-empty value. Applies/removes error styles
// and focuses the input when invalid. Returns true if valid.
export function requireTitle(input) {
  const valid = input.value.trim().length > 0;
  ERROR_CLASSES.forEach((cls) => input.classList.toggle(cls, !valid));
  if (!valid) input.focus();
  return valid;
}

// Fires a bubbling CustomEvent on `element` with an optional detail payload.
export function dispatchWizardEvent(element, name, detail = {}) {
  element.dispatchEvent(new CustomEvent(name, { bubbles: true, detail }));
}

// POST JSON to `url` with CSRF token. Returns the raw Response.
export function postJSON(url, body) {
  return fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content,
      Accept: "application/json",
    },
    body: JSON.stringify(body),
  });
}

// Reads a JSON response and fires wizard:done or wizard:error on `element`.
export async function handleFormResponse(element, resp) {
  if (resp.ok) {
    const { redirect } = await resp.json();
    dispatchWizardEvent(element, "wizard:done", { redirect });
  } else {
    const data = await resp.json().catch(() => ({}));
    dispatchWizardEvent(element, "wizard:error", {
      message: data.errors?.join(", "),
    });
  }
}
