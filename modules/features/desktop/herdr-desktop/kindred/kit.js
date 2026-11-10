import { div, image, svg } from "gpui-kit";
import { h_flex } from "gpui-base";
import { theme, settings, layout, appHome, readTextFile } from "herdr";

/** @typedef {`#${string}`} Color */
/** @typedef {ReturnType<typeof theme>} Palette */
/** @typedef {"working" | "blocked" | "done" | "idle"} Status */
/** @typedef {{ id?: string, children?: LayoutNode[], size?: { px?: number }, gap?: number, content?: { props?: { geometry?: Geometry }, pane?: { radius?: number } } }} LayoutNode */
/** @typedef {{ defaultWidth: number, minWidth: number, macCollapsed: number, maxWidth: number, radius: number, gap: number }} Geometry */
/** @param {LayoutNode} node @param {string} id @returns {LayoutNode | null} */
export function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}
/** @type {Geometry} */
let layoutGeometry;
let geometryLoad;
export function loadGeometry() {
  return geometryLoad ??= readTextFile(`${appHome()}/layouts/kindred.json`).then(text => {
    const root = /** @type {LayoutNode} */ (JSON.parse(text));
    layoutGeometry = find(root, "brand").content.props.geometry;
  });
}
export const geometry = { get radius() { return find(/** @type {LayoutNode} */ (layout()), "main").content.pane.radius; }, get gap() { return find(/** @type {LayoutNode} */ (layout()), "work-body").gap; }, get defaultWidth() { return layoutGeometry.defaultWidth; }, get minWidth() { return layoutGeometry.minWidth; }, get macCollapsed() { return layoutGeometry.macCollapsed; }, control: 26, portrait: 60, rail: 32 };
/** @param {{ icon?: string, tint?: boolean }} p @param {number} size @param {Color} ink @param {boolean} flexNone */
export function programIcon(p, size, ink, flexNone = true) {
  if (!p?.icon) return null;
  const icon = p.tint ? svg(p.icon).size(size).text_color(ink) : image(p.icon).w(size).h(size);
  return flexNone ? icon.flex_none() : icon;
}
/** @param {number} size @param {Color} ink */
export function spinner(size, ink) {
  return svg("mods/kindred/spinner.svg").size(size).flex_none().text_color(ink).spin(900);
}
export const palette = theme;
export function pixel(n = 1) { return n / (Number(settings()?.zoom) || 1); }
/** @param {string} value @returns {Color} */
const color = value => /** @type {Color} */ (value);
/** @param {Palette} t */
export function rule(t = palette()) {
  return h_flex().h(pixel(9)).gap(7).items_center()
    .child(div().flex_1().h(pixel()).bg(color(t.border)))
    .child(div().size(pixel(3)).bg(color(t.accent)))
    .child(div().flex_1().h(pixel()).bg(color(t.border)));
}
/** @param {boolean} remote @param {Status} status @param {Palette} t */
export function portrait(remote, status, t = palette()) {
  return div().relative().size(geometry.portrait).flex_none().p(2).border(pixel()).border_color(color(t.border))
    .bg(color(t.canvas)).rounded(geometry.radius)
    .child(image(`mods/kindred/${remote ? "manor" : "knight"}.svg`).size(54))
    .child(div().absolute().bottom(1).left(1).right(1).h(pixel(3)).bg(color(t[status] ?? t.dim)));
}
/** @param {Status} status @param {Palette} t */
export function badge(status, t = palette(), compact = false) {
  const labels = { working: "working", blocked: "needs you", done: "done", idle: "idle" };
  const ink = color(t[status] ?? t.dim);
  return h_flex().flex_none().gap(5).items_center().text_size(10).text_color(ink)
    .child(status === "working"
      ? spinner(10, ink)
      : status === "blocked"
        ? div().flex_none().child("!").loop("opacity", { from: 0.45, to: 1, period: 1200 })
        : status === "done"
          ? svg("mods/kindred/check.svg").size(10).flex_none().text_color(ink)
          : div().w(pixel(3)).h(pixel(9)).bg(ink))
    .when(!compact, el => el.child(labels[status] ?? labels.idle));
}
