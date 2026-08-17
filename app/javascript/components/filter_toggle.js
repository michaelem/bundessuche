// The date filters take up a lot of room for something most searches do not
// need, so JavaScript folds them behind a single button in the section title.
// Without JavaScript the filters stay where they are and keep working, only
// unfolded.
const filters = document.querySelector(".search__filters");

if (filters) {
  const title = filters.querySelector(".search__filters-title");
  const list = filters.querySelector(".search__filters-list");
  const inputs = [...list.querySelectorAll("input")];

  const toggle = document.createElement("button");
  toggle.type = "button";
  toggle.className = "search__filters-toggle";
  toggle.textContent = title.textContent.trim();
  toggle.setAttribute("aria-controls", list.id);

  let open = inputs.some((input) => input.value.trim() !== "");

  // Folding the filters away clears them, so that they can never be submitted
  // unseen and no hidden input is left behind as required by the date filter.
  const update = () => {
    toggle.setAttribute("aria-expanded", String(open));
    list.hidden = !open;
    if (open) return;

    inputs.forEach((input) => {
      if (input.value === "") return;
      input.value = "";
      input.dispatchEvent(new Event("input", { bubbles: true }));
    });
  };

  toggle.addEventListener("click", () => {
    open = !open;
    update();
    if (open) inputs[0]?.focus();
  });

  title.replaceChildren(toggle);
  update();
}
