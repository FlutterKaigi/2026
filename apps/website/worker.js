/**
 * Sends legacy profile-exchange links (`/x/<token>` and `/en/x/<token>`) and
 * session-detail links (`/sessions/<id>`) to the conference app, preserving
 * the encoded path segment for native or web handling.
 * Missing tokens and malformed exchange paths still serve the locale's static
 * fallback page. All unrelated requests, including association files, pass
 * through to static assets unchanged.
 */

import { productionAppOrigin } from "../../tool/app_link_origins.mjs";

const SHARE_LINK_FALLBACK_PATTERN = /^\/(en\/)?x(\/|$)/;
const SHARE_LINK_TOKEN_PATTERN = /^\/(?:en\/)?x\/([^/]+)$/;
const SESSION_DETAIL_PATTERN = /^\/sessions\/([^/]+)$/;

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
    const shareLink = SHARE_LINK_TOKEN_PATTERN.exec(url.pathname);
    const sessionDetail = SESSION_DETAIL_PATTERN.exec(url.pathname);
    const appPath = shareLink ? `/x/${shareLink[1]}` : sessionDetail ? `/sessions/${sessionDetail[1]}` : null;
    if (appPath !== null) {
      // Keep the encoded token or ID under a fixed origin. Query parameters
      // and fragments are not part of the destination's identity.
      return new Response(null, {
        status: 302,
        headers: {
          Location: `${productionAppOrigin}${appPath}`,
          "Cache-Control": "no-store",
          "Referrer-Policy": "no-referrer",
        },
      });
    }

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
