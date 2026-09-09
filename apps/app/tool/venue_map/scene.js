const stage = document.getElementById("stage"),
  labels = document.getElementById("labels");
const places = PLAN.places;
const rect = (x, y, w, h) => [
  [x, y],
  [x + w, y],
  [x + w, y + h],
  [x, y + h],
];
const send = (type, extra = {}) => {
  const payload = JSON.stringify({ type, ...extra });
  if (window.VenueMapChannel) window.VenueMapChannel.postMessage(payload);
  else parent.postMessage(payload, location.origin);
};
let api = null;
function initialize(config) {
  const scene = new Scene(),
    renderer = new WebGLRenderer({ antialias: true, alpha: true });
  renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
  renderer.setClearColor(0, 0);
  renderer.outputColorSpace = SRGBColorSpace;
  renderer.toneMapping = ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1;
  stage.append(renderer.domElement);
  const camera = new OrthographicCamera(-30, 30, 25, -25, 0.1, 300);
  const controls = new OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true;
  controls.dampingFactor = 0.1;
  controls.minPolarAngle = 0.12;
  controls.maxPolarAngle = Math.PI / 2.35;
  controls.enablePan = true;
  controls.zoomSpeed = 0.8;
  controls.touches.TWO = TOUCH.DOLLY_PAN;
  scene.add(new AmbientLight(0xffffff, 0.9));
  const light = new DirectionalLight(0xffffff, 2);
  light.position.set(-12, 35, 15);
  scene.add(light);
  const unit = 0.028,
    center = [PLAN.bounds.x + PLAN.bounds.w / 2, PLAN.bounds.y + PLAN.bounds.h / 2],
    zoneMeshes = new Map(),
    targets = [];
  const point = (p, y = 0.12) =>
    new Vector3((p[0] - center[0]) * unit, y, (p[1] - center[1]) * unit);
  const bindings = [];
  const material = (role) => {
    const m = new MeshStandardMaterial({
      color: config.colors[role],
      roughness: 0.95,
    });
    bindings.push([m, role]);
    return m;
  };
  function prism(poly, depth, color, y = 0) {
    const shape = new Shape();
    poly.forEach((p, i) => {
      const v = point(p);
      i ? shape.lineTo(v.x, -v.z) : shape.moveTo(v.x, -v.z);
    });
    shape.closePath();
    const mesh = new Mesh(
      new ExtrudeGeometry(shape, { depth, bevelEnabled: false }),
      material(color),
    );
    mesh.rotation.x = -Math.PI / 2;
    mesh.position.y = y;
    scene.add(mesh);
    return mesh;
  }
  prism(PLAN.outline, 0.14, "surface", -0.14);
  const textureLoader = new TextureLoader();
  let artMaterial;
  const lightArt = textureLoader.load(MAP_ART, () => draw());
  const darkArt = textureLoader.load(MAP_ART_DARK, () => draw());
  for (const texture of [lightArt, darkArt]) {
    texture.colorSpace = SRGBColorSpace;
    texture.anisotropy = renderer.capabilities.getMaxAnisotropy();
  }
  artMaterial = new MeshBasicMaterial({map: lightArt, toneMapped: false});
  const floorArt = new Mesh(new PlaneGeometry(ART_BOX.w * unit, ART_BOX.h * unit), artMaterial);
  floorArt.rotation.x = -Math.PI / 2;
  floorArt.position.copy(point([ART_BOX.x + ART_BOX.w / 2, ART_BOX.y + ART_BOX.h / 2], .006));
  scene.add(floorArt);

  // Only the reviewed wall segments are extruded; openings are never inferred
  // by cutting arbitrary gaps into closed room rectangles.
  function wall(a, b, height = .64, thickness = .065) {
    const pa = point(a), pb = point(b), dx = pb.x - pa.x, dz = pb.z - pa.z;
    const length = Math.hypot(dx, dz);
    if (length < .01) return;
    const mesh = new Mesh(new BoxGeometry(length, height, thickness), material("service"));
    mesh.position.set((pa.x + pb.x) / 2, height / 2 + .02, (pa.z + pb.z) / 2);
    mesh.rotation.y = -Math.atan2(dz, dx);
    scene.add(mesh);
  }
  PLAN.walls.forEach(([a, b]) => wall(a, b));
  function hitArea(polygon, id, y = .025) {
    const shape = new Shape();
    polygon.forEach((p, i) => { const v = point(p); i ? shape.lineTo(v.x, -v.z) : shape.moveTo(v.x, -v.z); });
    shape.closePath();
    const m = new MeshBasicMaterial({color: config.colors.primary, transparent: true, opacity: 0, depthWrite: false, toneMapped: false});
    const mesh = new Mesh(new ShapeGeometry(shape), m);
    mesh.rotation.x = -Math.PI / 2;
    mesh.position.y = y;
    mesh.userData.zoneId = id;
    scene.add(mesh);
    targets.push(mesh);
    return mesh;
  }
  // Higher hit planes give nested facilities and numbered tables precedence.
  places.forEach((p) => zoneMeshes.set(p.id, hitArea(p.polygon, p.id, p.type === "sponsor" ? .30 : p.type === "facility" ? .04 : .02)));
  PLAN.publicEntrances.forEach(e => hitArea(e.polygon, e.placeId, .035));
  PLAN.restrictedAreas.forEach(poly => hitArea(poly, null, .045));
  PLAN.booths.forEach(({rect: [x, y, w, h], color}) => {
    const mesh = prism(rect(x, y, w, h), .23, "surface", .03);
    // Every booth uses the same visitor-facing color in both themes.
    bindings.splice(bindings.findIndex(([m]) => m === mesh.material), 1);
    mesh.material.color.set(color);
  });
  PLAN.escalators.forEach(({bank, x0, x1, y0, y1}) => {
    wall([x0, y0], [x1, y0], .12, .055);
    wall([bank === "west" ? x0-11 : x0, y1], [x1, y1], .12, .055);
    // Flat boarding ends face the shared central landing. The paired runs
    // follow the east/west direction, not the north/south room orientation.
  });
  let selected = null,
    active = true,
    frame = null,
    fitZoom = 1,
    cameraInitialized = false;
  const labelNodes = places.map((p) => {
    const el = document.createElement("button");
    el.className = `label ${p.type}`;
    el.onclick = () => send("selected", { id: p.id });
    labels.append(el);
    const svg = document.getElementById("label-connectors");
    const line = document.createElementNS("http://www.w3.org/2000/svg", "line");
    const dot = document.createElementNS(
      "http://www.w3.org/2000/svg",
      "circle",
    );
    dot.setAttribute("r", "2.5");
    svg.append(line, dot);
    return { p, el, line, dot, offsetX: 0, offsetY: 0 };
  });
  function configure(next) {
    config = next;
    const colors = config.colors;
    for (const [key, value] of Object.entries(colors))
      if (typeof value === "string")
        document.documentElement.style.setProperty("--" + key, value);
    document.documentElement.style.setProperty(
      "--text-scale",
      config.textScale || 1,
    );
    document.documentElement.lang = config.language;
    bindings.forEach(([m, role]) => m.color.set(colors[role]));
    artMaterial.map = colors.dark ? darkArt : lightArt;
    for (const { p, el } of labelNodes) {
      const name = p.name[config.language] || p.name.ja;
      if (p.type === "sponsor") {
        el.textContent = String(p.boothNumber);
      } else if (p.type === "facility") {
        const content = document.createElement("span");
        content.className = "facility-content";
        content.setAttribute("aria-hidden", "true");
        const icon = document.createElement("span");
        icon.className = "material-icon";
        icon.textContent = MAP_ICONS[p.materialIcon];
        content.append(icon);
        const caption =
          p.mapLabel?.[config.language] ?? (p.icon === "wc" ? "WC" : "");
        if (caption) {
          const text = document.createElement("span");
          text.textContent = caption;
          content.append(text);
        }
        el.replaceChildren(content);
      } else {
        el.textContent = name.replace(" HALL", "\nHALL");
      }
      el.title = p.boothNumber ? p.boothNumber + " · " + name : name;
      el.setAttribute("aria-label", el.title);
      const marker = ({booth:PLAN.colors.booth,purple:"#8061BD",blue:"#408FC3",rose:"#945838",teal:"#326E58",gold:"#B98227",pink:"#CE6BA5"})[p.palette] || colors.onSurfaceVariant;
      el.style.setProperty("--color", colors.dark ? new Color(marker).lerp(new Color("white"), .4).getStyle() : marker);
    }
    highlight(config.selected);
    active = config.active;
    if (active) {
      resize();
      if (!frame) tick();
    } else {
      if (frame) cancelAnimationFrame(frame);
      frame = null;
    }
  }
  function highlight(id) {
    selected = id;
    for (const [key, mesh] of zoneMeshes) {
      mesh.material.color.set(config.colors.primary);
      mesh.material.opacity = key === id ? .28 : 0;
    }
    labelNodes.forEach(({ p, el }) => {
      el.classList.toggle("selected", p.id === id);
      el.setAttribute("aria-pressed", String(p.id === id));
    });
    draw();
  }
  function projectLabels() {
    const w = stage.clientWidth,
      h = stage.clientHeight;
    // At an oblique angle the floor is compressed; use its smaller projected
    // scale so booth numbers do not spill far away from their tables.
    const detailed = camera.zoom * 20 * unit * Math.cos(controls.getPolarAngle()) >= .5;
    const items = [];
    for (const node of labelNodes) {
      const { p, el, line, dot } = node;
      const v = point(p.anchor, 0.8).project(camera);
      const x = ((v.x + 1) * w) / 2,
        y = ((1 - v.y) * h) / 2;
      const visible = v.z > -1 && v.z < 1 && x >= 0 && x <= w && y >= 0 && y <= h && (p.type !== "sponsor" || detailed || p.id === selected);
      el.classList.toggle("compact", !detailed && p.id !== selected && !p.id.startsWith("ask_"));
      el.hidden = !visible;
      line.style.visibility = dot.style.visibility = "hidden";
      if (!visible) continue;
      items.push({
        node,
        anchorX: x,
        anchorY: y,
        width: el.offsetWidth,
        height: el.offsetHeight,
        offsetX: node.offsetX,
        offsetY: node.offsetY,
        priority:
          p.icon === "wc"
            ? 0
            : p.id === selected
              ? 1
              : p.type === "hall"
                ? 2
                : p.type === "foyer"
                  ? 3
                  : 4,
      });
    }
    for (const item of layoutMapLabels(items, w, h)) {
      const { node, x, y, anchorX, anchorY, left, right, top, bottom } = item;
      const { el, line, dot } = node;
      node.offsetX = x - anchorX;
      node.offsetY = y - anchorY;
      el.style.left = x + "px";
      el.style.top = y + "px";
      el.style.zIndex = String(10 - item.priority);
      const endX = Math.max(left, Math.min(right, anchorX));
      const endY = Math.max(top, Math.min(bottom, anchorY));
      if (Math.hypot(endX - anchorX, endY - anchorY) > 3) {
        line.style.visibility = dot.style.visibility = "visible";
        line.setAttribute("x1", anchorX);
        line.setAttribute("y1", anchorY);
        line.setAttribute("x2", endX);
        line.setAttribute("y2", endY);
        dot.setAttribute("cx", anchorX);
        dot.setAttribute("cy", anchorY);
      }
    }
  }
  function draw() {
    if (!active) return;
    renderer.render(scene, camera);
    projectLabels();
  }
  function tick() {
    frame = null;
    if (!active) return;
    controls.update();
    frame = requestAnimationFrame(tick);
  }
  function setFrustum(w, h) {
    // Keep world units per screen pixel constant when the selection summary resizes the map.
    camera.left = -w / 40;
    camera.right = w / 40;
    camera.top = h / 40;
    camera.bottom = -h / 40;
    camera.updateProjectionMatrix();
  }
  function fit() {
    const w = stage.clientWidth,
      h = stage.clientHeight;
    if (!w || !h) return;
    const portrait = w < h * 0.9,
      focus = new Vector3(0, 0, 0);
    camera.zoom = 1;
    setFrustum(w, h);
    controls.target.copy(focus);
    camera.position
      .copy(focus)
      .add(portrait ? new Vector3(36, 58, 1) : new Vector3(0, 48, 35));
    camera.lookAt(focus);
    camera.updateProjectionMatrix();
    camera.updateMatrixWorld();
    const points = PLAN.outline.map((v) => point(v, 0.8).project(camera));
    const maxX = Math.max(...points.map((v) => Math.abs(v.x))),
      maxY = Math.max(...points.map((v) => Math.abs(v.y)));
    camera.zoom = Math.min(0.94 / maxX, 0.88 / maxY, 100);
    fitZoom = camera.zoom;
    controls.minZoom = fitZoom * 0.7;
    controls.maxZoom = fitZoom * 6;
    cameraInitialized = true;
    camera.updateProjectionMatrix();
    controls.update();
    draw();
  }
  function focusSelection(id) {
    const p = places.find((p) => p.id === id),
      w = stage.clientWidth,
      h = stage.clientHeight;
    if (!p || !w || !h) return;
    if (!cameraInitialized) resize();
    camera.updateMatrixWorld();
    const focus = point(p.anchor, 0.8).applyMatrix4(camera.matrixWorldInverse);
    const corners = p.polygon.map((v) =>
      point(v, 0.8).applyMatrix4(camera.matrixWorldInverse),
    );
    const radiusX =
      Math.max(...corners.map((v) => Math.abs(v.x - focus.x))) + 36 * unit;
    const radiusY =
      Math.max(...corners.map((v) => Math.abs(v.y - focus.y))) + 36 * unit;
    camera.zoom = Math.max(
      fitZoom,
      Math.min(
        fitZoom * (["sponsor", "facility"].includes(p.type) ? 4.5 : 2.2),
        (w - 72) / (40 * radiusX),
        (h - 80) / (40 * radiusY),
      ),
    );
    // Apply an ordinary pan and zoom once. Later controls never consult the selection.
    const delta = point(p.anchor, 0.8).sub(controls.target);
    camera.position.add(delta);
    controls.target.add(delta);
    setFrustum(w, h);
    controls.update();
    draw();
  }
  function resize() {
    const w = stage.clientWidth,
      h = stage.clientHeight;
    if (!w || !h) return;
    renderer.setSize(w, h);
    setFrustum(w, h);
    if (!cameraInitialized) fit();
    else draw();
  }
  const raycaster = new Raycaster(),
    mouse = new Vector2();
  let down = null;
  const pointers = new Set();
  let multiTouch = false;
  renderer.domElement.addEventListener("pointerdown", (e) => {
    pointers.add(e.pointerId);
    if (pointers.size === 1) multiTouch = false;
    else multiTouch = true;
    down = [e.clientX, e.clientY];
  });
  renderer.domElement.addEventListener("pointercancel", (e) => {
    pointers.delete(e.pointerId);
    down = null;
  });
  renderer.domElement.addEventListener("pointerup", (e) => {
    pointers.delete(e.pointerId);
    if (
      multiTouch ||
      !down ||
      Math.hypot(e.clientX - down[0], e.clientY - down[1]) > 6
    )
      return;
    const r = renderer.domElement.getBoundingClientRect();
    mouse.set(
      ((e.clientX - r.left) / r.width) * 2 - 1,
      (-(e.clientY - r.top) / r.height) * 2 + 1,
    );
    raycaster.setFromCamera(mouse, camera);
    const hit = raycaster.intersectObjects(targets)[0];
    if (hit?.object.userData.zoneId) {
      send("selected", { id: hit.object.userData.zoneId });
    }
  });

  controls.addEventListener("change", draw);
  const observer = new ResizeObserver(resize);
  observer.observe(stage);
  renderer.domElement.addEventListener("webglcontextlost", (event) => {
    event.preventDefault();
    send("error");
  });
  configure(config);
  send("loaded");
  return {
    configure,
    focus: focusSelection,
    fit,
    rotate() {
      const offset = camera.position.clone().sub(controls.target);
      offset.applyAxisAngle(new Vector3(0, 1, 0), Math.PI / 2);
      camera.position.copy(controls.target).add(offset);
      controls.update();
      draw();
    },
    zoom(factor) {
      camera.zoom = Math.max(
        controls.minZoom,
        Math.min(controls.maxZoom, camera.zoom * factor),
      );
      camera.updateProjectionMatrix();
      draw();
    },
  };
}
window.VenueMap = {
  receive(command) {
    try {
      if (command.action === "configure") {
        if (api) api.configure(command);
        else api = initialize(command);
      } else if (api) {
        if (command.action === "focus") api.focus(command.value);
        if (command.action === "fit") api.fit();
        if (command.action === "zoom") api.zoom(command.value);
        if (command.action === "rotate") api.rotate();
      }
    } catch (error) {
      send("error");
      console.error(error);
    }
  },
};
window.addEventListener("message", (event) => {
  if (
    event.source !== parent ||
    event.origin !== location.origin ||
    typeof event.data !== "string"
  )
    return;
  try {
    window.VenueMap.receive(JSON.parse(event.data));
  } catch {
    /* Ignore messages for other app components. */
  }
});
send("ready");
