// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"

let Hooks = {}
const lastUpdatedElements = document.getElementsByClassName("last-updated")

Hooks.clipboard = {
  mounted() {
    this.el.addEventListener("click", () => {
      const text = this.el.getAttribute("data-clipboard-text")
      navigator.clipboard.writeText(text).then(() => {
        // Visual feedback
        const originalColor = this.el.style.color
        this.el.style.color = "#10B981" // Green color for success
        setTimeout(() => {
          this.el.style.color = originalColor
        }, 1000)
      })
    })
  }
}

Hooks.timer = {
  mounted() {
    this.secondsAgo = 0;

    this.interval = setInterval(() => {
      this.secondsAgo += 1;
      for (let el of lastUpdatedElements) {
        el.innerHTML = `${this.secondsAgo} seconds ago`;
      }
    }, 1000);

    this.handleEvent("resetCounter", () => {
      this.secondsAgo = 0;
    });
  },
  destroyed() {
    this.interval && clearInterval(this.interval);
  }
};

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

