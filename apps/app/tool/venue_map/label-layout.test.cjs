const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const vm = require("node:vm");

const scene = fs.readFileSync(path.join(__dirname, "scene.js"), "utf8");
const projection = scene.slice(
  scene.indexOf("function projectLabels()"),
  scene.indexOf("function draw()"),
);
const layout = fs.readFileSync(path.join(__dirname, "label-layout.js"), "utf8");

// Measured from the failing 661 × 612 view with the information desk selected.
const measured = [
  ["main_hall_a", "hall", null, 105.006, 268.335, 48],
  ["main_hall_b", "hall", null, 105.006, 360.239, 66],
  ["grand_hall_a", "hall", null, 566.334, 261.265, 73],
  ["grand_hall_b", "hall", null, 566.334, 358.953, 63],
  ["exhibition_hall_1", "foyer", null, 273.629, 321.678, 69],
  ["exhibition_hall_2", "foyer", null, 434.299, 322.32, 69],
  ["hall_entrance_information", "facility", "info", 328.512, 362.809, 48],
  ["mens_wc", "facility", "wc", 251.358, 365.38, 48],
  ["womens_wc", "facility", "wc", 412.028, 367.951, 48],
  ["elevators", "facility", "lift", 194.885, 272.191, 48],
  ["entrance_hall_lounge", "facility", "entry", 345.215, 393.658, 48],
  ["ask_speaker", "facility", "person", 562.357, 283.117, 48],
].map(([id, type, icon, x, y, width]) => ({
  id,
  type,
  icon,
  anchor: [x, y],
  width,
  height: 48,
}));

function render(
  places,
  {
    width = 661,
    height = 612,
    selected = "hall_entrance_information",
    zoom = 1,
    polarAngle = 0,
  } = {},
) {
  const element = () => ({
    style: {},
    classList: {toggle() {}},
    attributes: {},
    setAttribute(key, value) {
      this.attributes[key] = value;
    },
  });
  const labels = places.map((p) => ({
    p,
    line: element(),
    dot: element(),
    el: {
      ...element(),
      hidden: false,
      get offsetWidth() {
        return this.hidden ? 0 : p.width;
      },
      get offsetHeight() {
        return this.hidden ? 0 : p.height;
      },
    },
  }));
  const environment = {
    stage: { clientWidth: width, clientHeight: height },
    labelNodes: labels,
    selected,
    camera: { zoom },
    controls: { getPolarAngle: () => polarAngle },
    unit: .028,
    fitZoom: 1,
    point: (anchor) => ({
      project: () => ({
        x: (anchor[0] * 2) / width - 1,
        y: 1 - (anchor[1] * 2) / height,
        z: 0,
      }),
    }),
  };
  vm.runInNewContext(
    layout + "\n" + projection + "\nprojectLabels();",
    environment,
  );
  return labels;
}

function bounds(node) {
  const x = Number.parseFloat(node.el.style.left),
    y = Number.parseFloat(node.el.style.top);
  return {
    left: x - node.p.width / 2,
    right: x + node.p.width / 2,
    top: y - node.p.height / 2,
    bottom: y + node.p.height / 2,
  };
}

function assertReadable(labels, width, height) {
  for (const [i, node] of labels.entries()) {
    assert.equal(node.el.hidden, false, `${node.p.id} must stay visible`);
    const box = bounds(node);
    assert.ok(
      box.left >= 0 &&
        box.right <= width &&
        box.top >= 0 &&
        box.bottom <= height,
      `${node.p.id} must fit the viewport`,
    );
    for (const other of labels.slice(i + 1)) {
      const next = bounds(other);
      assert.ok(
        box.right <= next.left ||
          box.left >= next.right ||
          box.bottom <= next.top ||
          box.top >= next.bottom,
        `${node.p.id} and ${other.p.id} must both be readable`,
      );
    }
  }
}

test("a selected information desk no longer hides the nearby foyer", () => {
  const labels = render(
    measured.filter((p) =>
      ["exhibition_hall_1", "hall_entrance_information"].includes(p.id),
    ),
  );
  assertReadable(labels, 661, 612);
});

test("all labels remain readable at the reported angle, including both restrooms", () => {
  assertReadable(render(measured), 661, 612);
});

test("restrooms take priority over a selected hall and displaced labels point to their actual location", () => {
  const labels = render(
    [
      { ...measured[0], anchor: [200, 200] },
      { ...measured[7], anchor: [200, 200] },
    ],
    { selected: "main_hall_a" },
  );
  assertReadable(labels, 661, 612);
  const [hall, wc] = labels;
  assert.equal(Number.parseFloat(wc.el.style.left), 200);
  assert.equal(Number.parseFloat(wc.el.style.top), 200);
  assert.equal(hall.line.style.visibility, "visible");
  assert.equal(hall.line.attributes.x1, 200);
  assert.equal(hall.line.attributes.y1, 200);
});

test("rotating a compact map or changing the selection never removes an on-screen place", () => {
  const width = 320,
    height = 500;
  for (let degrees = 0; degrees < 360; degrees += 30) {
    const angle = (degrees * Math.PI) / 180;
    const places = measured.map((p) => {
      const x = (p.anchor[0] - 330) * 0.45,
        y = (p.anchor[1] - 330) * 0.45;
      return {
        ...p,
        anchor: [
          width / 2 + x * Math.cos(angle) - y * Math.sin(angle),
          height / 2 + x * Math.sin(angle) + y * Math.cos(angle),
        ],
      };
    });
    for (const selected of [
      null,
      "hall_entrance_information",
      "exhibition_hall_1",
      "womens_wc",
    ]) {
      assertReadable(
        render(places, { width, height, selected, zoom: 0.7 }),
        width,
        height,
      );
    }
  }
});

test("off-screen places do not create misleading labels at the edge", () => {
  const [wc] = render([{ ...measured[7], anchor: [-20, 200] }]);
  assert.equal(wc.el.hidden, true);
  assert.equal(wc.line.style.visibility, "hidden");
});

test("dense booth numbers appear on zoom and a selected booth remains identifiable", () => {
  const booth = {...measured[0], id: "sponsor_1", type: "sponsor", width: 24, height: 24};
  assert.equal(render([booth], {zoom: .7, selected: null})[0].el.hidden, true);
  assert.equal(render([booth], {zoom: 1.2, selected: null})[0].el.hidden, false);
  assert.equal(render([booth], {zoom: .7, selected: "sponsor_1"})[0].el.hidden, false);
});

test("tilting the floor postpones dense booth numbers until its compressed axis is readable", () => {
  const booth = {...measured[0], id: "sponsor_1", type: "sponsor", width: 24, height: 24};
  const view = {zoom: 1.2, polarAngle: Math.PI / 3, selected: null};
  assert.equal(render([booth], view)[0].el.hidden, true);
  assert.equal(render([booth], {...view, zoom: 2})[0].el.hidden, false);
  assert.equal(render([booth], {...view, selected: "sponsor_1"})[0].el.hidden, false);
});

test("English captions remain readable when the compact 3D map rotates", () => {
  const sizes = {
    hall_entrance_information: [75, 48],
    mens_wc: [60, 62],
    womens_wc: [60, 62],
    elevators: [60, 48],
    entrance_hall_lounge: [59, 48],
    ask_speaker: [53, 62],
  };
  for (let degrees = 0; degrees < 360; degrees += 30) {
    const angle = (degrees * Math.PI) / 180;
    const places = measured.map((p) => {
      const x = (p.anchor[0] - 330) * 0.45,
        y = (p.anchor[1] - 330) * 0.45;
      const [width, height] = sizes[p.id] || [p.width, p.height];
      return {
        ...p,
        width,
        height,
        anchor: [
          160 + x * Math.cos(angle) - y * Math.sin(angle),
          250 + x * Math.sin(angle) + y * Math.cos(angle),
        ],
      };
    });
    assertReadable(render(places, { width: 320, height: 500 }), 320, 500);
  }
});
