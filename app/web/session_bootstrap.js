(function () {
  "use strict";

  var statusEl = document.getElementById("sessionBootstrap");
  var configured = String(window.ENDLESSNET_API_BASE || "")
    .trim()
    .replace(/\/+$/, "");
  var apiBase = configured || location.origin.replace(/\/+$/, "");

  function showFailure() {
    if (!statusEl) {
      return;
    }
    statusEl.textContent = "Не удалось проверить сессию. Обновите страницу.";
  }

  function redirectToLogin() {
    location.replace(new URL("login/", document.baseURI).href);
  }

  function startAdminApp() {
    if (statusEl) {
      statusEl.remove();
    }
    var script = document.createElement("script");
    script.src = new URL("flutter_bootstrap.js", document.baseURI).href;
    script.async = true;
    document.body.appendChild(script);
  }

  fetch(new URL("/auth/me", apiBase).href, {
    credentials: "include",
    headers: { "Accept": "application/json" }
  })
    .then(function (response) {
      if (response.ok) {
        startAdminApp();
        return;
      }
      if (response.status === 401 || response.status === 403) {
        redirectToLogin();
        return;
      }
      showFailure();
    })
    .catch(showFailure);
})();
