import { layout, run, shared, setShared, window } from "herdr";
import { geometry, find, loadGeometry } from "./kit.js";
export { find } from "./kit.js";

/** @typedef {import("./kit.js").LayoutNode} LayoutNode */
const sidebar = () => find(/** @type {LayoutNode} */ (layout()), "sidebar");
export const narrow = () => { const width = sidebar()?.size?.px; return width != null && width < geometry.portrait * 3 + geometry.gap * 2; };
export function toggleSidebar() {
  const collapsed = narrow();
  const width = sidebar()?.size?.px;
  if (!collapsed) setShared("sidebar.width", width);
  setShared("sidebar.collapsed", !collapsed);
  loadGeometry().then(() => run("layout.resize", { id: "sidebar", px: collapsed ? (shared("sidebar.width") ?? geometry.defaultWidth) : window()?.platform === "macos" ? geometry.macCollapsed : geometry.minWidth }));
}
