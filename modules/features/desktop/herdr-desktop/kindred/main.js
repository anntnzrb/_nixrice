import { View } from "gpui-kit";
import { props } from "herdr";
import Agents from "./agents.js";
import Chrome from "./chrome.js";
import Spaces from "./spaces.js";
import Tabs from "./tabs.js";
import Pane from "./pane.js";
import { loadGeometry } from "./kit.js";

const roles = { agents: Agents, chrome: Chrome, spaces: Spaces, tabs: Tabs, pane: Pane };

export default class Kindred extends View {
  /** @param {{role?: keyof typeof roles}} p @param {import("gpui-kit").Context} cx */
  init(p, cx) {
    const pr = props() ?? p ?? {};
    const Role = roles[pr.role ?? "agents"];
    if (!Role) throw new Error(`Unknown Kindred role: ${pr.role}`);
    this.role = new Role();
    this.role.init?.(pr, cx);
    cx.spawn(async (cx) => { await loadGeometry(); cx.notify(); });
  }
  /** @param {import("gpui-kit").Context} cx */
  render(cx) { return this.role.render(cx); }
}
