// Place every on-screen label near its anchor. A collision moves a label; it never removes it.
function layoutMapLabels(items, width, height) {
  const margin = 4,
    gap = 6;
  const placed = [];
  const clamp = (value, min, max) => Math.max(min, Math.min(max, value));
  const ordered = items
    .map((item, index) => ({ ...item, index }))
    .sort(
      (a, b) =>
        (a.priority === 0 ? 0 : 1) - (b.priority === 0 ? 0 : 1) ||
        b.width * b.height - a.width * a.height ||
        a.priority - b.priority ||
        a.index - b.index,
    );
  for (const item of ordered) {
    const minX = margin + item.width / 2,
      maxX = Math.max(minX, width - minX);
    const minY = margin + item.height / 2,
      maxY = Math.max(minY, height - minY);
    const baseX = clamp(item.anchorX, minX, maxX),
      baseY = clamp(item.anchorY, minY, maxY);
    const previousX = clamp(item.anchorX + (item.offsetX || 0), minX, maxX);
    const previousY = clamp(item.anchorY + (item.offsetY || 0), minY, maxY);
    const xs = new Set([baseX, previousX, minX, maxX]);
    const ys = new Set([baseY, previousY, minY, maxY]);
    for (const other of placed) {
      xs.add(clamp(other.left - gap - item.width / 2, minX, maxX));
      xs.add(clamp(other.right + gap + item.width / 2, minX, maxX));
      ys.add(clamp(other.top - gap - item.height / 2, minY, maxY));
      ys.add(clamp(other.bottom + gap + item.height / 2, minY, maxY));
    }
    let best = null,
      bestScore = Infinity;
    for (const x of xs)
      for (const y of ys) {
        const box = {
          left: x - item.width / 2,
          right: x + item.width / 2,
          top: y - item.height / 2,
          bottom: y + item.height / 2,
        };
        const overlap = placed.reduce(
          (sum, other) =>
            sum +
            Math.max(
              0,
              Math.min(box.right + gap, other.right) -
                Math.max(box.left - gap, other.left),
            ) *
              Math.max(
                0,
                Math.min(box.bottom + gap, other.bottom) -
                  Math.max(box.top - gap, other.top),
              ),
          0,
        );
        const score =
          overlap * 1e6 +
          (x - item.anchorX) ** 2 +
          (y - item.anchorY) ** 2 +
          0.15 * ((x - previousX) ** 2 + (y - previousY) ** 2);
        if (score < bestScore) {
          bestScore = score;
          best = { ...item, ...box, x, y };
        }
      }
    placed.push(best);
  }
  return placed;
}
