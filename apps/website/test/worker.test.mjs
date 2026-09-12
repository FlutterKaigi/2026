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

test("fetch rewrites a share-link request to the locale fallback page", async () => {
  const requestedUrls = [];
  const assets = fakeAssets((request) => {
    requestedUrls.push(request.url);
    return new Response("fallback");
  });

  const response = await worker.fetch(new Request("https://2026.flutterkaigi.jp/en/x/abc123"), { ASSETS: assets });

  assert.equal(await response.text(), "fallback");
  assert.deepEqual(requestedUrls, ["https://2026.flutterkaigi.jp/en/x/"]);
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

  const response = await worker.fetch(new Request("https://2026.flutterkaigi.jp/x/abc123"), { ASSETS: assets });

  assert.equal(await response.text(), "original");
  assert.deepEqual(requestedUrls, [
    "https://2026.flutterkaigi.jp/x/",
    "https://2026.flutterkaigi.jp/x/abc123",
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
