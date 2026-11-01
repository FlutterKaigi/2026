import assert from "node:assert/strict";
import { test } from "node:test";

import { installArchivePlayers } from "../web/archive-player.js";

function fixture({ open = false, source = "https://www.youtube-nocookie.com/embed/aqz-KE-bpKQ" } = {}) {
  const attributes = new Map([["data-archive-src", source]]);
  const writes = [];
  const frame = {
    getAttribute: (name) => attributes.get(name) ?? null,
    setAttribute: (name, value) => { attributes.set(name, value); writes.push([name, value]); },
    removeAttribute: (name) => attributes.delete(name),
  };
  const dialog = {
    open,
    matches: (selector) => selector === "[popover]" || (selector === ":popover-open" && dialog.open),
    querySelectorAll: () => [frame],
  };
  const listeners = new Map();
  const root = {
    querySelectorAll: () => [dialog],
    addEventListener: (name, callback, capture) => { assert.equal(capture, true); listeners.set(name, callback); },
    removeEventListener: (name) => listeners.delete(name),
  };
  const dispose = installArchivePlayers(root);
  return { dialog, frame, attributes, writes, source, listeners, dispose };
}

test("keeps closed archive players unloaded until the popover opens", () => {
  const f = fixture();
  assert.equal(f.frame.getAttribute("src"), null);
  f.listeners.get("beforetoggle")({ target: f.dialog, newState: "open" });
  assert.equal(f.frame.getAttribute("src"), null);
  f.dialog.open = true;
  f.listeners.get("toggle")({ target: f.dialog, newState: "open" });
  assert.equal(f.frame.getAttribute("src"), f.source);
});

test("unloads the player immediately before every kind of popover closure", () => {
  const f = fixture({ open: true });
  assert.equal(f.frame.getAttribute("src"), f.source);
  f.listeners.get("beforetoggle")({ target: f.dialog, newState: "closed" });
  assert.equal(f.frame.getAttribute("src"), null);
  assert.equal(f.frame.getAttribute("data-archive-src"), f.source);
  f.dialog.open = false;
  f.listeners.get("toggle")({ target: f.dialog, newState: "closed" });
  assert.equal(f.frame.getAttribute("src"), null);
});

test("reopening a dialog reloads its player without redundant open-state reloads", () => {
  const f = fixture({ open: true });
  f.listeners.get("toggle")({ target: f.dialog });
  assert.equal(f.writes.length, 1);
  f.dialog.open = false;
  f.listeners.get("toggle")({ target: f.dialog });
  f.dialog.open = true;
  f.listeners.get("toggle")({ target: f.dialog });
  assert.equal(f.writes.length, 2);
});

test("uses the final popover state when rapid toggles are coalesced", () => {
  const f = fixture();
  f.listeners.get("toggle")({ target: f.dialog, newState: "open" });
  assert.equal(f.frame.getAttribute("src"), null);
});

test("ignores other toggle targets and removes listeners on disposal", () => {
  const f = fixture();
  f.listeners.get("toggle")({ target: { matches: () => false } });
  f.listeners.get("toggle")({ target: null });
  assert.equal(f.frame.getAttribute("src"), null);
  f.dispose();
  assert.equal(f.listeners.size, 0);
});
