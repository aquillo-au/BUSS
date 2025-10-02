import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="filter"
export default class extends Controller {
  static targets = ["list", "item", "input"]

  connect() {
    // Uncomment for debugging:
     console.log("FilterController connected", { items: this.itemTargets.length })
  }

  search(event) {
    console.log("Search called", event);
    const query = (event?.target?.value ?? this.inputTarget?.value ?? "")
      .trim()
      .toLowerCase()

    // Show/hide items based on match
    this.itemTargets.forEach((item) => {
      const nameEl = item.querySelector(".guest-name")
      const text = (nameEl?.textContent || item.textContent || "").toLowerCase()
      const matches = text.includes(query)
      item.classList.toggle("d-none", !matches)
    })

    // Move matches to top, preserving order they appear in the DOM
    if (query.length > 0) {
      const matches = this.itemTargets.filter((item) => !item.classList.contains("d-none"))
      matches.forEach((node) => this.listTarget.appendChild(node))
    }
  }
}
