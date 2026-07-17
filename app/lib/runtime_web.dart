import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'admin_routing.dart';

const _checkoutKey = 'endlessnet_checkout_id';
const _themeModeKey = 'endlessnet.admin.theme_mode';

String defaultApiBase() {
  final configured = _trimSlash(_globalString('ENDLESSNET_API_BASE'));
  if (configured.isNotEmpty) {
    return configured;
  }
  return _trimSlash(web.window.location.origin);
}

String adminLoginUrl() {
  return Uri.parse(
    web.window.location.origin,
  ).resolve(_adminRootPath()).resolve('login/').toString();
}

String siteRoot() {
  final configured = _globalString('ENDLESSNET_SITE_ROOT').trim();
  if (configured.isNotEmpty) {
    return Uri.parse(web.window.location.href).resolve(configured).toString();
  }
  return Uri.parse(
    web.window.location.origin,
  ).resolve(_adminRootPath()).resolve('../').toString();
}

String readStoredCheckoutID() {
  return web.window.localStorage.getItem(_checkoutKey) ?? '';
}

void writeStoredCheckoutID(String value) {
  web.window.localStorage.setItem(_checkoutKey, value);
}

String readStoredThemeMode() {
  return web.window.localStorage.getItem(_themeModeKey) ?? '';
}

void writeStoredThemeMode(String value) {
  web.window.localStorage.setItem(_themeModeKey, value);
}

void redirectTo(String url) {
  web.window.location.assign(url);
}

void openExternal(String url) {
  if (url.startsWith('mailto:')) {
    web.window.location.assign(url);
    return;
  }
  web.window.open(url, '_blank');
}

String currentAdminViewSlug() {
  final route = _adminRouteSegments();
  if (route.isEmpty) {
    return '';
  }
  return route.first;
}

List<String> currentAdminRouteSegments() => _adminRouteSegments();

String currentBillingViewSlug() {
  final route = _adminRouteSegments();
  if (route.isEmpty || route.first != 'billing') {
    return '';
  }
  if (route.length == 1) {
    return '';
  }
  if (route.length >= 3 && route[1] == 'yookassa' && route[2] == 'return') {
    return 'return';
  }
  return route[1];
}

String currentCheckoutID() {
  return Uri.parse(web.window.location.href).queryParameters['checkout_id'] ??
      '';
}

String currentEnrollmentRequestID() {
  return Uri.parse(
        web.window.location.href,
      ).queryParameters['enrollment_request'] ??
      '';
}

String currentMachineID() {
  return machineIdFromAdminLocation(Uri.parse(web.window.location.href));
}

void pushAdminView(String viewSlug) {
  _setAdminView(viewSlug, replace: false);
}

void replaceAdminView(String viewSlug) {
  _setAdminView(viewSlug, replace: true);
}

void pushAdminPath(List<String> segments) {
  _setAdminPath(segments, replace: false);
}

void replaceAdminPath(List<String> segments) {
  _setAdminPath(segments, replace: true);
}

void pushMachineSelection(String machineId) {
  _setMachineSelection(machineId, replace: false);
}

void replaceMachineSelection(String machineId) {
  _setMachineSelection(machineId, replace: true);
}

void pushBillingView(String billingSlug) {
  _setBillingView(billingSlug, replace: false);
}

void replaceBillingView(String billingSlug) {
  _setBillingView(billingSlug, replace: true);
}

void Function() listenAdminHistory(void Function() onChange) {
  final listener = ((web.Event _) {
    onChange();
  }).toJS;
  web.window.addEventListener('popstate', listener);
  return () => web.window.removeEventListener('popstate', listener);
}

void _setAdminView(String viewSlug, {required bool replace}) {
  final normalized = viewSlug.trim();
  final next = switch (normalized) {
    '' || 'overview' => _adminRootPath(),
    'billing' => '${_adminRootPath()}billing/',
    _ => '${_adminRootPath()}$normalized/',
  };
  _writeHistory(next, replace: replace);
}

void _setAdminPath(List<String> segments, {required bool replace}) {
  final clean = segments
      .map((item) => item.trim().toLowerCase())
      .where((item) => item.isNotEmpty)
      .map(Uri.encodeComponent)
      .join('/');
  final next = clean.isEmpty ? _adminRootPath() : '${_adminRootPath()}$clean/';
  _writeHistory(next, replace: replace);
}

void _setMachineSelection(String machineId, {required bool replace}) {
  final next = adminMachineSelectionLocation(_adminRootPath(), machineId);
  _writeHistory(next, replace: replace);
}

void _setBillingView(String billingSlug, {required bool replace}) {
  final normalized = billingSlug.trim();
  final suffix = switch (normalized) {
    '' || 'overview' => 'billing/',
    'return' => 'billing/yookassa/return/',
    _ => 'billing/$normalized/',
  };
  _writeHistory('${_adminRootPath()}$suffix', replace: replace);
}

void _writeHistory(String next, {required bool replace}) {
  final current =
      '${web.window.location.pathname}${web.window.location.search}';
  if (next == current) {
    return;
  }
  if (replace) {
    web.window.history.replaceState(_historyState(), '', next);
  } else {
    web.window.history.pushState(_historyState(), '', next);
  }
}

JSAny _historyState() {
  return web.window.history.getProperty<JSAny?>('state'.toJS) ??
      <String, Object?>{}.jsify()!;
}

String _adminRootPath() {
  final configured = _globalString('ENDLESSNET_ADMIN_ROOT').trim();
  if (configured.isNotEmpty) {
    final withLeadingSlash = configured.startsWith('/')
        ? configured
        : '/$configured';
    return withLeadingSlash.endsWith('/')
        ? withLeadingSlash
        : '$withLeadingSlash/';
  }
  final path = web.window.location.pathname;
  final marker = '/admin/';
  final index = path.indexOf(marker);
  if (index >= 0) {
    return path.substring(0, index + marker.length);
  }
  if (path.endsWith('/admin')) {
    return '$path/';
  }
  return Uri.parse(web.window.location.href).resolve('./').path;
}

List<String> _adminRouteSegments() {
  final root = _adminRootPath();
  var path = web.window.location.pathname;
  if (path.startsWith(root)) {
    path = path.substring(root.length);
  }
  return path
      .split('/')
      .map((item) => item.trim().toLowerCase())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

String _globalString(String name) {
  final value = web.window.getProperty<JSAny?>(name.toJS);
  final dartValue = value?.dartify();
  return dartValue is String ? dartValue.trim() : '';
}

String _trimSlash(String value) =>
    value.trim().replaceFirst(RegExp(r'/+$'), '');
