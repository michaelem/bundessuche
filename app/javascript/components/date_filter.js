// A day only means something together with a month, and a month only together
// with a year, so filling in a finer field makes the coarser ones required.
// Without JavaScript nothing breaks: the server ignores the parts it cannot
// place and falls back to the coarser precision.
document.querySelectorAll(".search__date").forEach((fieldset) => {
  const parts = ["day", "month", "year"]
    .map((part) => fieldset.querySelector(`.search__date-input--${part}`))
    .filter(Boolean);

  const update = () => {
    let finerFilled = false;
    parts.forEach((input) => {
      input.required = finerFilled;
      finerFilled ||= input.value.trim() !== "";
    });
  };

  parts.forEach((input) => input.addEventListener("input", update));
  update();
});
