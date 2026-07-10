# Browser authentication contract v1

This document is normative for the EndlessNet admin console and public API
gateway.

## Flow

1. The admin console requests `GET /auth/providers` with
   `Accept: application/json`.
2. The gateway returns the provider list defined by the OpenAPI contract.
3. The browser navigates to the selected provider's `login_url` on the API
   origin.
4. The gateway performs the OIDC redirect and callback flow.
5. A successful callback creates the server-side session, writes the session
   cookie, and redirects to the configured admin URL.
6. Admin API requests include browser credentials. A bearer token may be used
   by non-browser consumers, but tokens must never be placed in redirect URLs.
7. `POST /auth/logout` invalidates the server-side session and clears the
   session cookie.

## Security and transport

- Public site, admin console and API origins use HTTPS.
- Cross-origin admin requests use `credentials: include`.
- The API CORS allow-list explicitly contains the deployed admin origin.
- Credentialed CORS responses return the concrete request origin, never `*`.
- Session cookies are `HttpOnly`, `Secure` on HTTPS, and use the configured
  `SameSite` policy required by the deployment topology.
- Authentication tokens, OIDC tokens and session identifiers never appear in
  query strings, URL fragments, logs or frontend build artifacts.
- The admin console must not scrape `/auth/login` HTML. `/auth/providers` is
  the only provider-discovery interface.

## Failure behavior

- Missing or expired sessions return `401`.
- Authenticated users without the required account role return `403`.
- The frontend treats either status as an authentication/authorization state,
  not as a transport failure.
- Responses include `X-Request-ID`; clients may surface it for diagnostics.
