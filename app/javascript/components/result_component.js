// How long the confirmation stays on screen, in milliseconds.
const TOAST_DURATION = 1900;

let toastElement = null;
let toastTimeout = null;

function toast(message) {
  if (!toastElement) {
    toastElement = document.createElement("div");
    toastElement.className = "toast";
    toastElement.setAttribute("role", "status");
    toastElement.setAttribute("aria-live", "polite");
    document.body.append(toastElement);
  }

  toastElement.textContent = message;
  // Reading the layout in between lets the fade replay on a second copy.
  toastElement.classList.remove("toast--visible");
  void toastElement.offsetWidth;
  toastElement.classList.add("toast--visible");

  clearTimeout(toastTimeout);
  toastTimeout = setTimeout(() => {
    toastElement.classList.remove("toast--visible");
  }, TOAST_DURATION);
}

// The clipboard API needs a secure context and a permission the reader may have
// withheld, so an old-fashioned selection stands in when it is unavailable.
function copyBySelection(text) {
  const textarea = document.createElement("textarea");
  textarea.value = text;
  textarea.setAttribute("readonly", "");
  textarea.setAttribute("aria-hidden", "true");
  textarea.style.position = "fixed";
  textarea.style.opacity = "0";
  document.body.append(textarea);
  textarea.select();

  try {
    return document.execCommand("copy");
  } catch (error) {
    console.error(error);
    return false;
  } finally {
    textarea.remove();
  }
}

async function copyToClipboard(text) {
  if (navigator.clipboard && window.isSecureContext) {
    try {
      await navigator.clipboard.writeText(text);
      return true;
    } catch (error) {
      console.error(error);
    }
  }

  return copyBySelection(text);
}

// One listener for the whole page: a result page carries hundreds of these
// buttons, and they all behave the same.
document.addEventListener("click", async (event) => {
  const button = event.target.closest('.cite__button[data-action="copy"]');
  if (!button || button.disabled) {
    return;
  }

  button.disabled = true;
  try {
    // The citation comes from the endpoint the download link points at, so the
    // two can never hand out different text.
    const response = await fetch(button.dataset.href);
    if (!response.ok) {
      throw new Error(`Response status: ${response.status}`);
    }

    const copied = await copyToClipboard(await response.text());
    toast(copied ? button.dataset.copied : button.dataset.failed);
  } catch (error) {
    console.error(error);
    toast(button.dataset.failed);
  } finally {
    button.disabled = false;
  }
});
