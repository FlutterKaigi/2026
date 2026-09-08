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
  const unit = 0.055,
    center = [434.5, 214],
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
  const palette = (p) =>
    ({
      purple: "primary",
      blue: "tertiary",
      rose: "secondary",
      teal: "onTertiaryContainer",
      gold: "onSecondaryContainer",
      neutral: "onSurfaceVariant",
    })[p];
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
  const artUniforms = {
    mapIsDark: { value: 0 },
    mapInk: { value: new Color() },
    mapPaper: { value: new Color() },
  };
  let artMaterial;
  if (MAP_ART) {
    const texture = new TextureLoader().load(MAP_ART, () => draw());
    texture.colorSpace = SRGBColorSpace;
    texture.anisotropy = renderer.capabilities.getMaxAnisotropy();
    artMaterial = new MeshBasicMaterial({ map: texture, toneMapped: false });
    artMaterial.onBeforeCompile = (shader) => {
      Object.assign(shader.uniforms, artUniforms);
      shader.fragmentShader =
        "uniform float mapIsDark; uniform vec3 mapInk; uniform vec3 mapPaper;\n" +
        shader.fragmentShader;
      shader.fragmentShader = shader.fragmentShader.replace(
        "#include <map_fragment>",
        `#include <map_fragment>
        if(mapIsDark>.5){float luminance=dot(diffuseColor.rgb,vec3(.2126,.7152,.0722));diffuseColor.rgb=mix(mapInk,mapPaper,luminance);}`,
      );
    };
    const plane = new Mesh(
      new PlaneGeometry(ART_BOX.w * unit, ART_BOX.h * unit),
      artMaterial,
    );
    plane.rotation.x = -Math.PI / 2;
    plane.position.copy(
      point([ART_BOX.x + ART_BOX.w / 2, ART_BOX.y + ART_BOX.h / 2], 0.006),
    );
    scene.add(plane);
  }
  PLAN.service.forEach((poly) => prism(poly, 0.52, "service", 0.014));
  function wall(a, b) {
    const pa = point(a),
      pb = point(b),
      dx = pb.x - pa.x,
      dz = pb.z - pa.z,
      length = Math.hypot(dx, dz);
    if (length < 0.01) return;
    const mesh = new Mesh(
      new BoxGeometry(length, 0.66, 0.075),
      material("surface"),
    );
    mesh.position.set((pa.x + pb.x) / 2, 0.4, (pa.z + pb.z) / 2);
    mesh.rotation.y = -Math.atan2(dz, dx);
    scene.add(mesh);
  }
  function roomWalls(p) {
    p.polygon.forEach((a, i) => {
      const b = p.polygon[(i + 1) % p.polygon.length];
      if (a[0] !== b[0]) {
        wall(a, b);
        return;
      }
      const low = Math.min(a[1], b[1]),
        high = Math.max(a[1], b[1]);
      const cuts = PLAN.doors
        .filter((d) => Math.abs(d.x - a[0]) < 2 && d.y > low && d.y < high)
        .sort((a, b) => a.y - b.y);
      let start = low;
      for (const door of cuts) {
        wall([a[0], start], [a[0], door.y - 6]);
        start = door.y + 6;
      }
      wall([a[0], start], [a[0], high]);
    });
  }
  places.forEach((p) => {
    if (p.id === "ask_speaker") return;
    const mesh = prism(p.polygon, 0.022, palette(p.palette), 0.014);
    if (MAP_ART) {
      mesh.material.transparent = true;
      mesh.material.opacity = 0.015;
      mesh.material.depthWrite = false;
    }
    mesh.userData.zoneId = p.id;
    targets.push(mesh);
    zoneMeshes.set(p.id, mesh);
    if (
      p.type === "hall" ||
      ["mens_wc", "womens_wc", "elevators"].includes(p.id)
    )
      roomWalls(p);
  });
  PLAN.booths.forEach(([x, y, w, h]) =>
    prism(rect(x, y, w, h), 0.24, "primaryContainer", 0.04),
  );
  PLAN.stairs.forEach(([x, y, w, h]) => {
    for (let i = 0; i < 7; i++)
      prism(
        rect(x, y + (i * h) / 7, w, h / 7 - 1),
        0.04 + i * 0.025,
        "service",
        0.02,
      );
  });
  let selected = null,
    active = true,
    frame = null,
    fitZoom = 1,
    cameraInitialized = false;
  const glyph = { info: "ⓘ", wc: "WC", lift: "EV", entry: "↪", person: "Ask" };
  const labelNodes = places.map((p) => {
    const el = document.createElement("button");
    el.className = `label ${p.type}`;
    el.onclick = () => send("selected", { id: p.id });
    labels.append(el);
    return { p, el };
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
    artUniforms.mapIsDark.value = colors.dark ? 1 : 0;
    artUniforms.mapInk.value.set(colors.onSurfaceVariant);
    artUniforms.mapPaper.value.set(colors.service);
    for (const { p, el } of labelNodes) {
      const name = p.name[config.language] || p.name.ja;
      el.textContent =
        p.type === "facility" ? glyph[p.icon] : name.replace(" HALL", "\nHALL");
      if (p.icon === "wc") {
        el.classList.add("wc");
        el.textContent =
          (config.language === "en"
            ? p.id === "mens_wc"
              ? "Men"
              : "Women"
            : p.id === "mens_wc"
              ? "男性"
              : "女性") + "\nWC";
      }
      el.title = name;
      el.setAttribute("aria-label", name);
      el.style.setProperty("--color", colors[palette(p.palette)]);
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
      mesh.material.emissive.set(
        key === id ? config.colors.primary : "#000000",
      );
      mesh.material.emissiveIntensity = key === id ? 0.12 : 0;
      if (MAP_ART)
        mesh.material.opacity =
          key === id ? 0.48 : config.colors.dark ? 0.16 : 0.015;
    }
    labelNodes.forEach(({ p, el }) => {
      el.classList.toggle("selected", p.id === id);
      el.setAttribute("aria-pressed", String(p.id === id));
    });
    draw();
  }
  function projectLabels() {
    const w = stage.clientWidth,
      h = stage.clientHeight,
      occupied = [];
    const ordered = [...labelNodes].sort(
      (a, b) =>
        (a.p.id === selected
          ? -9
          : a.p.type === "hall"
            ? 0
            : a.p.type === "foyer"
              ? 1
              : 2) -
        (b.p.id === selected
          ? -9
          : b.p.type === "hall"
            ? 0
            : b.p.type === "foyer"
              ? 1
              : 2),
    );
    for (const { p, el } of ordered) {
      const v = point(p.anchor, 0.8).project(camera);
      const x = ((v.x + 1) * w) / 2,
        y = ((1 - v.y) * h) / 2;
      let visible =
        (p.id !== "ask_speaker" ||
          selected === p.id ||
          camera.zoom > fitZoom * 1.4) &&
        v.z > -1 &&
        v.z < 1;
      el.style.left = x + "px";
      el.style.top = y + "px";
      el.hidden = !visible;
      if (!visible) continue;
      const bw = el.offsetWidth,
        bh = el.offsetHeight,
        box = { l: x - bw / 2, r: x + bw / 2, t: y - bh / 2, b: y + bh / 2 };
      if (x < 0 || x > w || y < 0 || y > h) visible = false;
      if (
        p.id !== selected &&
        occupied.some(
          (b) =>
            box.l < b.r + 3 &&
            box.r > b.l - 3 &&
            box.t < b.b + 3 &&
            box.b > b.t - 3,
        )
      )
        visible = false;
      el.hidden = !visible;
      if (visible) occupied.push(box);
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
    draw();
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
    camera.zoom = Math.min(0.87 / maxX, 0.78 / maxY, 100);
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
        fitZoom * 2.2,
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
    if (hit) {
      send("selected", { id: hit.object.userData.zoneId });
    }
  });

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
