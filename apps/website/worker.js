/**
 * Routes every profile-exchange share-link request — `/x/<token>` and its
 * English-locale `/en/x/<token>` equivalent (see `ShareLinkFallbackPage` /
 * `AppLocale.shareLinkFallbackRoutePath`) — to the single static fallback
 * page the site builds for that locale. `jaspr` can only pre-render fixed
 * routes (SSG), so there is no per-token page to serve; every other request
 * is passed straight through to the static assets unchanged, so this leaves
 * every other path's behaviour — 404s included — exactly as the assets
 * binding would produce with no Worker script in front of it at all.
 */

const SHARE_LINK_FALLBACK_PATTERN = /^\/(en\/)?x(\/|$)/;

/** Whether `pathname` is a share-link request with no per-token page. */
export function isShareLinkFallbackPath(pathname) {
  return SHARE_LINK_FALLBACK_PATTERN.test(pathname);
}

/**
 * The single static fallback page's path for `pathname`, preserving the
 * `/en` locale prefix so `/en/x/<token>` still serves the English page
 * rather than falling back to Japanese.
 */
export function shareLinkFallbackPathFor(pathname) {
  return pathname.startsWith("/en/") || pathname === "/en" ? "/en/x/" : "/x/";
}

export default {
  async fetch(request, env) {
    const assets = env && env.ASSETS;
    if (!assets || typeof assets.fetch !== "function") {
      // No assets binding to route through at all — fall back to the
      // request exactly as received rather than throwing.
      return fetch(request);
    }

    const url = new URL(request.url);
    if (!isShareLinkFallbackPath(url.pathname)) {
      return assets.fetch(request);
    }

    try {
      const fallback = new URL(shareLinkFallbackPathFor(url.pathname), url);
      return await assets.fetch(new Request(fallback, request));
    } catch (error) {
      // Serving the rewritten fallback page failed — fall back to the
      // request exactly as received, the same behaviour every other path
      // already gets, instead of surfacing an unhandled Worker exception.
      return assets.fetch(request);
    }
  },
};
