// Import and register all your controllers from the importmap under controllers/*
import { Application } from "@hotwired/stimulus"
import { definitionsFromContext } from "@hotwired/stimulus-loading"

const application = Application.start()
window.Stimulus = application

// Auto-register all controllers under app/javascript/controllers
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)
