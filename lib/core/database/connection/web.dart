import 'package:drift/drift.dart';
import 'package:drift/web.dart';

QueryExecutor createDatabaseConnection() {
  return WebDatabase.withStorage(DriftWebStorage.indexedDb('life_os'));
}
