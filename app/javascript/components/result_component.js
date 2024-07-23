async function fetchText(path) {
  try {
    const response = await fetch(path);
    if (!response.ok) {
      throw new Error(`Response status: ${response.status}`);
    }
    return await response.text();
  } catch (error) {
    console.error(error.message);
  }
}

document.querySelectorAll(".cite__copy-ris").forEach((button) => {
  button.addEventListener("click", async () => {
    if (button.disabled) {
      return;
    }
    button.disabled = true;

    const risPath = button.dataset.risPath;
    const clipboardItem = new ClipboardItem({ 'text/plain': fetchText(risPath) });

    navigator.clipboard
      .write([clipboardItem])
      .then(() => {
        const oldColor = button.style.backgroundColor;
        const oldText = button.textContent;
        button.textContent = "copied";
        button.style.backgroundColor = "green";

        setTimeout(() => {
          button.textContent = oldText;
          button.style.backgroundColor = oldColor;
          button.disabled = false;
        }, 1000);
      })
      .catch((error) => {
        console.log(error);
      });
  });
});
