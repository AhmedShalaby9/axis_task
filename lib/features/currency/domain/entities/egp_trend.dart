/// Domain concept for the direction of EGP's strength relative to a target.
///
/// Derived from already-inverted rates (X→EGP). A FALLING inverted rate means
/// fewer EGP are needed per unit of foreign currency = EGP has strengthened.
/// This is the opposite of conventional "rate went up = good" intuition.
///
/// Widgets map this to colours: stronger → green, weaker → red, unchanged → grey,
/// unknown → hide the change badge entirely (no data to display).
/// No colour logic belongs outside this semantic boundary.
enum EgpTrend { stronger, weaker, unchanged, unknown }
