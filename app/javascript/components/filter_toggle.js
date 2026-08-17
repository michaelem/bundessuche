// A date filter takes up a lot of room for something most searches do not
// need, so JavaScript folds each one behind a checkbox in its legend. Without
// JavaScript the filters stay where they are and keep working, only unfolded.
document.querySelectorAll(".search__date").forEach((fieldset) => {
  const legend = fieldset.querySelector(".search__date-legend");
  const parts = fieldset.querySelector(".search__date-parts");
  const inputs = [...parts.querySelectorAll("input")];

  const toggle = document.createElement("input");
  toggle.type = "checkbox";
  toggle.id = `${fieldset.dataset.prefix}_toggle`;
  toggle.className = "search__date-toggle";
  toggle.checked = inputs.some((input) => input.value.trim() !== "");

  const label = document.createElement("label");
  label.htmlFor = toggle.id;
  label.className = "search__date-toggle-label";
  label.textContent = legend.textContent.trim();

  legend.replaceChildren(toggle, label);

  // Folding a filter away clears it, so that it can never be submitted unseen
  // and so no hidden input is left behind as required by the date filter.
  const update = () => {
    parts.hidden = !toggle.checked;
    if (toggle.checked) return;

    inputs.forEach((input) => {
      if (input.value === "") return;
      input.value = "";
      input.dispatchEvent(new Event("input", { bubbles: true }));
    });
  };

  toggle.addEventListener("change", update);
  update();
});
