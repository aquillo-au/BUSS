import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="filter"
export default class extends Controller {
  static targets = ["list", "item"]

  search(event) {
    const query = event.target.value.toLowerCase()

    this.itemTargets.forEach((item) => {
      const name = item.querySelector(".guest-name").textContent.toLowerCase()
      item.style.display = name.includes(query) ? "flex" : "none"
    })

    // Move matches to top
    const matches = this.itemTargets.filter((item) =>
      item.querySelector(".guest-name").textContent.toLowerCase().includes(query)
    )
    matches.forEach((match) => this.listTarget.prepend(match))
  }
}
