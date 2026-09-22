/// Converts an old root-hosted `/#/route` bookmark into a path URL.
///
/// Only the fragment was visible to HashUrlStrategy, so its query remains the
/// route's query. The original origin is retained and ordinary anchors, OAuth
/// fragments, and references to other origins are left untouched.
Uri? migrateLegacyHashRoute(Uri current) {
  if ((current.scheme != 'https' && current.scheme != 'http') ||
      !current.hasAuthority ||
      (current.path.isNotEmpty && current.path != '/')) {
    return null;
  }

  final fragment = current.fragment;
  if (!fragment.startsWith('/') || fragment.startsWith('//') || fragment.contains(r'\')) {
    return null;
  }
  final route = Uri.tryParse(fragment);
  if (route == null || route.hasScheme || route.hasAuthority || route.path.toLowerCase().contains('%5c')) {
    return null;
  }

  return current.resolveUri(route);
}
