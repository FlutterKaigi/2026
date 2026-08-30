/**
 * Routes every `/x/<token>` request — a profile-exchange share link opened
 * in a browser instead of the app — to the single static fallback page the
 * site builds at `/x/` (see `ShareLinkFallbackPage` / `AppLocale.
 * shareLinkFallbackRoutePath`). `jaspr` can only pre-render fixed routes
 * (SSG), so there is no per-token page to serve; every other request is
 * passed straight through to the static assets unchanged, so this leaves
 * every other path's behaviour — 404s included — exactly as the assets
 * binding would produce with no Worker script in front of it at all.
 */
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname === "/x" || url.pathname.startsWith("/x/")) {
      const fallback = new URL("/x/", url);
      return env.ASSETS.fetch(new Request(fallback, request));
    }
    return env.ASSETS.fetch(request);
  },
};
