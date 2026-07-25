import '../models/app_event.dart';
import '../models/client.dart';
import '../models/loan.dart';

/// Contrato da camada de dados.
///
/// Hoje o [AppController] fala direto com o Hive (implementação local). Para
/// evoluir para SaaS com sincronização em nuvem, basta criar uma implementação
/// desta interface usando Firestore (ex.: `FirebaseDataRepository`) e injetá-la
/// no controlador — a UI não precisa mudar.
abstract interface class DataRepository {
  Future<List<Client>> fetchClients();
  Future<void> saveClient(Client client);
  Future<void> deleteClient(String id);

  Future<List<Loan>> fetchLoans();
  Future<void> saveLoan(Loan loan);
  Future<void> deleteLoan(String id);

  Future<List<AppEvent>> fetchEvents();
  Future<void> logEvent(AppEvent event);

  /// Sincroniza mudanças locais com o backend (offline-first).
  Future<void> sync();
}
