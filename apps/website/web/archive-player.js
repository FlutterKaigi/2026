// Loading the iframe only while its popover is open also stops hidden playback.
export function syncArchivePlayers(dialog, open = dialog.matches(":popover-open")) {
  for (const frame of dialog.querySelectorAll("iframe[data-archive-src]")) {
    const source = frame.getAttribute("data-archive-src");
    if (open && source) {
      if (frame.getAttribute("src") !== source) frame.setAttribute("src", source);
    } else {
      // Removing src navigates to about:blank and unloads audio/video playback.
      frame.removeAttribute("src");
    }
  }
}

export function installArchivePlayers(root) {
  const isDialog = (target) => target?.matches?.("[popover]");
  const beforeToggle = (event) => {
    if (isDialog(event.target) && event.newState === "closed") syncArchivePlayers(event.target, false);
  };
  const toggle = (event) => {
    if (isDialog(event.target)) syncArchivePlayers(event.target);
  };
  root.addEventListener("beforetoggle", beforeToggle, true);
  root.addEventListener("toggle", toggle, true);
  for (const dialog of root.querySelectorAll("[popover]")) syncArchivePlayers(dialog);
  return () => {
    root.removeEventListener("beforetoggle", beforeToggle, true);
    root.removeEventListener("toggle", toggle, true);
  };
}

if (typeof document !== "undefined") installArchivePlayers(document);
