import assert from "node:assert/strict";
import { test } from "node:test";

import worker, { isShareLinkFallbackPath, shareLinkFallbackPathFor } from "../worker.js";

test("isShareLinkFallbackPath matches every share-link path", () => {
  for (const pathname of ["/x", "/x/", "/x/abc", "/en/x", "/en/x/", "/en/x/abc"]) {
    assert.equal(isShareLinkFallbackPath(pathname), true, pathname);
  }
});

test("isShareLinkFallbackPath passes through everything else", () => {
  for (const pathname of ["/xyz", "/x-foo", "/exchange", "/", "/en/", "/sponsors"]) {
    assert.equal(isShareLinkFallbackPath(pathname), false, pathname);
  }
});

test("isShareLinkFallbackPath only looks at the pathname, not query or fragment", () => {
  const url = new URL("https://2026.flutterkaigi.jp/x/abc?ref=qr#top");
  assert.equal(isShareLinkFallbackPath(url.pathname), true);
});

test("shareLinkFallbackPathFor keeps the /en prefix for English share links", () => {
  assert.equal(shareLinkFallbackPathFor("/en/x"), "/en/x/");
  assert.equal(shareLinkFallbackPathFor("/en/x/abc"), "/en/x/");
});

test("shareLinkFallbackPathFor falls back to the Japanese page otherwise", () => {
  assert.equal(shareLinkFallbackPathFor("/x"), "/x/");
  assert.equal(shareLinkFallbackPathFor("/x/abc"), "/x/");
});

function fakeAssets(handler) {
  return { fetch: (request) => Promise.resolve(handler(request)) };
}

test("fetch redirects legacy share links without changing the signed token", async () => {
  const token = "v1.attendee-uid.9999999999.a0b1c2d3";
  const assets = fakeAssets(() => assert.fail("redirect must not fetch assets"));

  for (const prefix of ["/x/", "/en/x/"]) {
    const response = await worker.fetch(new Request(`https://2026.flutterkaigi.jp${prefix}${token}`), { ASSETS: assets });

    assert.equal(response.status, 302);
    assert.equal(response.headers.get("Location"), `https://2026-app.flutterkaigi.jp/x/${token}`);
    assert.equal(response.headers.get("Cache-Control"), "no-store");
    assert.equal(response.headers.get("Referrer-Policy"), "no-referrer");
    assert.equal(await response.text(), "");
  }
});

test("redirect destination keeps its fixed origin and drops unrelated query parameters", async () => {
  const assets = fakeAssets(() => assert.fail("redirect must not fetch assets"));

  for (const token of ["v1.attendee%2Duid.9999999999.a0b1", "%2F%2Fevil.example", "%5C%5Cevil.example", "@evil.example"]) {
    const response = await worker.fetch(
      new Request(`https://2026.flutterkaigi.jp/x/${token}?redirect=https://evil.example/&token=other`),
      { ASSETS: assets },
    );

    assert.equal(response.status, 302);
    assert.equal(response.headers.get("Location"), `https://2026-app.flutterkaigi.jp/x/${token}`);
    const location = new URL(response.headers.get("Location"));
    assert.equal(location.origin, "https://2026-app.flutterkaigi.jp");
    assert.equal(location.search, "");
  }
});

test("fetch rewrites missing-token and malformed paths to the locale fallback page", async () => {
  const requestedUrls = [];
  const assets = fakeAssets((request) => {
    requestedUrls.push(request.url);
    return new Response("fallback");
  });

  const paths = ["/x", "/x/", "/x/token/extra", "/x/token/", "/x//evil.example", "/en/x", "/en/x/", "/en/x/token/extra"];
  for (const path of paths) {
    const response = await worker.fetch(new Request(`https://2026.flutterkaigi.jp${path}`), { ASSETS: assets });

    assert.equal(response.status, 200);
    assert.equal(response.headers.has("Location"), false);
    assert.equal(await response.text(), "fallback");
  }
  assert.deepEqual(requestedUrls, paths.map((path) => `https://2026.flutterkaigi.jp${path.startsWith("/en/") ? "/en/x/" : "/x/"}`));
});

test("fetch passes non-share-link requests straight through", async () => {
  const requestedUrls = [];
  const assets = fakeAssets((request) => {
    requestedUrls.push(request.url);
    return new Response("sponsors");
  });

  await worker.fetch(new Request("https://2026.flutterkaigi.jp/sponsors"), { ASSETS: assets });

  assert.deepEqual(requestedUrls, ["https://2026.flutterkaigi.jp/sponsors"]);
});

test("fetch passes association files through without rewriting or redirecting", async () => {
  const requestedUrls = [];
  const expected = new Response("{}", { headers: { "Content-Type": "application/json" } });
  const assets = fakeAssets((request) => {
    requestedUrls.push(request.url);
    return expected;
  });

  for (const file of ["apple-app-site-association", "assetlinks.json"]) {
    const url = `https://2026.flutterkaigi.jp/.well-known/${file}`;
    const response = await worker.fetch(new Request(url), { ASSETS: assets });

    assert.equal(response, expected);
    assert.equal(requestedUrls.at(-1), url);
  }
});

test("fetch falls back to the original request when the fallback fetch throws", async () => {
  const requestedUrls = [];
  const assets = {
    fetch: (request) => {
      requestedUrls.push(request.url);
      if (request.url.endsWith("/x/")) {
        throw new Error("boom");
      }
      return Promise.resolve(new Response("original"));
    },
  };

  const response = await worker.fetch(new Request("https://2026.flutterkaigi.jp/x/token/extra"), { ASSETS: assets });

  assert.equal(await response.text(), "original");
  assert.deepEqual(requestedUrls, [
    "https://2026.flutterkaigi.jp/x/",
    "https://2026.flutterkaigi.jp/x/token/extra",
  ]);
});

test("fetch falls back to a plain fetch when env.ASSETS is missing", async () => {
  const originalFetch = globalThis.fetch;
  let calledWith;
  globalThis.fetch = (request) => {
    calledWith = request;
    return Promise.resolve(new Response("no-assets"));
  };
  try {
    const response = await worker.fetch(new Request("https://2026.flutterkaigi.jp/x/abc123"), {});
    assert.equal(await response.text(), "no-assets");
    assert.equal(calledWith.url, "https://2026.flutterkaigi.jp/x/abc123");
  } finally {
    globalThis.fetch = originalFetch;
  }
});
