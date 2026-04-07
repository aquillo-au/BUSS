import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  connect() {
    // Wait for Chartkick to render, then add click handlers
    setTimeout(() => {
      this.attachLegendListeners()
    }, 100)
  }

  attachLegendListeners() {
    const canvas = this.element.querySelector('canvas')
    if (!canvas || !canvas.__chart) return

    const chart = canvas.__chart
    const legendContainer = this.element.querySelector('.chartjs-legend')

    if (!legendContainer) return

    const legendItems = legendContainer.querySelectorAll('li')

    legendItems.forEach((item, index) => {
      item.style.cursor = 'pointer'
      item.addEventListener('click', (e) => {
        e.preventDefault()
        e.stopPropagation()

        const meta = chart.getDatasetMeta(index)
        meta.hidden = !meta.hidden
        chart.update()
      })
    })
  }
}
