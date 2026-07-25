import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_event.dart';
import '../models/client.dart';
import '../models/installment.dart';
import '../models/loan.dart';

/// Inicializa o Hive, registra os adapters (escritos à mão — sem code
/// generation) e abre as boxes usadas pelo app.
class HiveService {
  static const clientsBox = 'clients';
  static const loansBox = 'loans';
  static const eventsBox = 'events';
  static const settingsBox = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();

    _registerAdapter(ClientAdapter());
    _registerAdapter(LoanAdapter());
    _registerAdapter(LoanInstallmentAdapter());
    _registerAdapter(InterestPaymentAdapter());
    _registerAdapter(AppEventAdapter());

    await Hive.openBox<Client>(clientsBox);
    await Hive.openBox<Loan>(loansBox);
    await Hive.openBox<AppEvent>(eventsBox);
    await Hive.openBox(settingsBox);
  }

  static void _registerAdapter<T>(TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  }

  static Box<Client> get clients => Hive.box<Client>(clientsBox);
  static Box<Loan> get loans => Hive.box<Loan>(loansBox);
  static Box<AppEvent> get events => Hive.box<AppEvent>(eventsBox);
  static Box get settings => Hive.box(settingsBox);
}
