import { div, image, svg } from "gpui-kit";
import { h_flex } from "gpui-base";
import { theme, settings } from "herdr";

/** @typedef {`#${string}`} Color */
/** @typedef {ReturnType<typeof theme>} Palette */
/** @typedef {"working" | "blocked" | "done" | "idle"} Status */
export const geometry = { radius: 3, gap: 10, control: 26, portrait: 60, rail: 32 };
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
      ? svg("mods/kindred/spinner.svg").size(10).flex_none().text_color(ink).spin(900)
      : status === "blocked"
        ? div().flex_none().child("!").loop("opacity", { from: 0.45, to: 1, period: 1200 })
        : status === "done"
          ? svg("mods/kindred/check.svg").size(10).flex_none().text_color(ink)
          : div().w(pixel(3)).h(pixel(9)).bg(ink))
    .when(!compact, el => el.child(labels[status] ?? labels.idle));
}
