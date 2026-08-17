// The date filters take up a lot of room for something most searches do not
// need, so the toggle in the section title folds them away. The button and the
// folded state are both rendered by the server, so nothing here changes what is
// on screen until the button is pressed. Without JavaScript the button is
// hidden and the filters stay where they are, only unfolded.
const OPEN_CLASS = "search__filters-list--open";

const filters = document.querySelector(".search__filters");

if (filters) {
  const toggle = filters.querySelector(".search__filters-toggle");
  const list = filters.querySelector(".search__filters-list");
  const inputs = [...list.querySelectorAll("input")];

  let open = list.classList.contains(OPEN_CLASS);

  // Folding the filters away clears them, so that they can never be submitted
  // unseen and no hidden input is left behind as required by the date filter.
  const update = () => {
    toggle.setAttribute("aria-expanded", String(open));
    list.classList.toggle(OPEN_CLASS, open);
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

  update();
}
