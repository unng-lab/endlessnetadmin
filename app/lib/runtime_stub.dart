String defaultApiBase() => '';

String adminLoginUrl() => 'login.html';

String siteRoot() => '../';

String readStoredCheckoutID() => '';

void writeStoredCheckoutID(String value) {}

String readStoredThemeMode() => '';

void writeStoredThemeMode(String value) {}

void redirectTo(String url) {}

void openExternal(String url) {}

String currentAdminViewSlug() => '';

List<String> currentAdminRouteSegments() => const [];

String currentBillingViewSlug() => '';

String currentCheckoutID() => '';

void pushAdminView(String viewSlug) {}

void replaceAdminView(String viewSlug) {}

void pushAdminPath(List<String> segments) {}

void replaceAdminPath(List<String> segments) {}

void pushBillingView(String billingSlug) {}

void replaceBillingView(String billingSlug) {}

void Function() listenAdminHistory(void Function() onChange) {
  return () {};
}
