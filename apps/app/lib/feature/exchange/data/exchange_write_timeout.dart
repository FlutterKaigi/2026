/// How long to wait for an exchange-related Firestore write before treating
/// it as offline-pending instead of hanging indefinitely.
///
/// `cloud_firestore`'s write `Future`s (`set`/`update`) do not resolve until
/// the write reaches the server, even though the write is applied to the
/// local cache — and reflected by `snapshots()` — immediately. While
/// offline, that `Future` can stay pending until connectivity returns, which
/// would otherwise leave a loading spinner on screen indefinitely. Timing
/// the await out lets the UI report an "offline, will sync later" state and
/// move on; the underlying write is untouched and still completes once the
/// device reconnects.
const exchangeWriteTimeout = Duration(seconds: 5);
