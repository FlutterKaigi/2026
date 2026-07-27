/// Luma ticket-sales page for the event. Used by the Hero CTA and the
/// EventInformation ticket button (checkout-button embed), and by the
/// exploratory embedded-checkout preview (`TicketEmbedCard`).
library;

const lumaEventId = 'evt-qUO00SlCqL95v5b';

/// The event's page on Luma — also the checkout-button `href`, so a click
/// still reaches Luma even if the checkout script below fails to load.
const lumaEventUrl = 'https://luma.com/event/$lumaEventId';

/// Simple embeddable checkout iframe.
const lumaEmbedUrl = 'https://luma.com/embed/event/$lumaEventId/simple';

/// Luma's script that turns any `data-luma-action="checkout"` link into an
/// in-page checkout modal instead of a plain navigation.
const lumaCheckoutButtonScriptUrl = 'https://embed.lu.ma/checkout-button.js';
