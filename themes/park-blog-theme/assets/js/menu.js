// Full-screen menu toggle.
(() => {
  const button = document.getElementById("btn-menu");
  const overlay = document.getElementById("menu-overlay");
  if (!button || !overlay) return;

  const setOpen = (open) => {
    document.body.classList.toggle("menu-open", open);
    button.classList.toggle("is-active", open);
    button.setAttribute("aria-expanded", String(open));
    button.setAttribute("aria-label", open ? "Close menu" : "Open menu");
  };

  button.addEventListener("click", () => {
    setOpen(!document.body.classList.contains("menu-open"));
  });

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") setOpen(false);
  });
})();
