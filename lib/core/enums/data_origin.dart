/// Indicates whether an entity was resolved from the remote API or local cache.
///
/// Set by the repository impl at mapping time; consumed by the UI to show
/// a "last updated" indicator (Module 2) and a stale-data warning (Module 3).
enum DataOrigin { network, cache }
