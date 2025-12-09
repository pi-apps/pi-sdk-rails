import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
//window.Stimulus = Application.start()
//window.Stimulus.register("pinetwork", PinetworkController)
eagerLoadControllersFrom("controllers", application)
