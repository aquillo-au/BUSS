import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "prefix", "title"]
  static values = {
    showText: { type: String, default: "Show" },
    hideText: { type: String, default: "Hide" }
  }

  connect() {
    this._renderPrefix()
  }

  toggle() {
    this.panelTarget.hidden = !this.panelTarget.hidden
    this._renderPrefix()
  }

  _renderPrefix() {
    if (!this.hasPrefixTarget) return
    this.prefixTarget.textContent = this.panelTarget.hidden ? this.showTextValue : this.hideTextValue
  }
}
