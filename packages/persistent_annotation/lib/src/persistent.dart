/// Default persistance decorator.
///
/// The default [Persistent.persistenceStore] is [PersistenceStore.sharedPreferences].
const persistent = Persistent(
  persistenceStore: PersistenceStore.sharedPreferences,
);

/// The supported types of local stores.
///
/// Currently, [SharedPreferences] is the only
/// supported store.
///
/// Used for [Persistent.persistenceStore].
enum PersistenceStore {
  sharedPreferences;
}

/// Decorator for flagging a base class
/// as a persistent model.
///
/// Set the store type by initializaing
/// [Persistent.persistenceStore] with a value
/// from [PersistenceStore].
class Persistent {
  final PersistenceStore persistenceStore;

  const Persistent({
    required this.persistenceStore,
  });
}

class Default {
  final dynamic value;

  const Default(
    this.value,
  );
}
