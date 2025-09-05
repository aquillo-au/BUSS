// Import and register all your controllers from the importmap under controllers/*
import { Application } from "@hotwired/stimulus"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

const application = Application.start()
window.Stimulus = application

// Auto-register all controllers under app/javascript/controllers
eagerLoadControllersFrom("controllers", application)
