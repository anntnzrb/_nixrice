import { layout, run, shared, setShared, window } from "herdr";
import { geometry } from "./kit.js";

/** @typedef {{ id?: string, children?: LayoutNode[], size?: { px?: number } }} LayoutNode */
/** @param {LayoutNode} node @param {string} id @returns {LayoutNode | null} */
export function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}
const sidebar = () => find(/** @type {LayoutNode} */ (layout()), "sidebar");
export const narrow = () => (sidebar()?.size?.px ?? Infinity) < geometry.portrait * 3 + geometry.gap * 2;
export function toggleSidebar() {
  const collapsed = narrow();
  const width = sidebar()?.size?.px;
  if (!collapsed) setShared("sidebar.width", width);
  setShared("sidebar.collapsed", !collapsed);
  run("layout.resize", { id: "sidebar", px: collapsed ? (shared("sidebar.width") ?? 320) : window()?.platform === "macos" ? 76 : 44 });
}
