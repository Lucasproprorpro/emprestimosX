# EmprestaFácil

Sistema profissional de **gestão de empréstimos** (substitui cadernos e
planilhas) com três modalidades: **Penhor**, **Diário** e **Parcelado**.
Feito em **Flutter + Material 3**, estado com **Riverpod**, banco local com
**Hive** e estruturado para futura sincronização com **Firebase**.

## ⚠️ Passos obrigatórios antes de compilar

Este pacote contém todo o código-fonte (`lib/`, `test/`, `pubspec.yaml`), mas
**não** inclui as pastas de plataforma (`android/`, `ios/`) porque elas são
específicas da máquina/SDK e devem ser geradas pelo próprio Flutter. Faça:

```bash
# 1. Entre na pasta do projeto
cd emprestafacil

# 2. Gere as pastas de plataforma (android/, ios/, etc.) SEM apagar o lib/
flutter create .

# 3. Baixe as dependências
flutter pub get

# 4. Adicione as permissões Android (veja ANDROID_PERMISSIONS.md)

# 5. Rode em um dispositivo/emulador
flutter run

# 6. Gere o APK de release
flutter build apk --release
# O APK fica em: build/app/outputs/flutter-apk/app-release.apk
```

> Os *adapters* do Hive foram escritos **à mão** — **não é necessário rodar
> `build_runner`** nem gerar arquivos `.g.dart`.

## Rodar os testes

```bash
flutter test
```

Os testes em `test/loan_calculator_test.dart` validam os cálculos das três
modalidades.

## Arquitetura (Clean / camadas)

```
lib/
├── core/
│   ├── constants/enums.dart        # Modalidades, status, tipos de comércio
│   ├── theme/app_theme.dart        # Material 3 (claro/escuro) + cores semânticas
│   └── utils/
│       ├── date_utils.dart
│       ├── formatters.dart         # Moeda/datas (moeda configurável)
│       └── loan_calculator.dart    # ★ Regras de cálculo (puras e testadas)
├── data/
│   ├── models/                     # Client, Loan, LoanInstallment, ... (+ adapters)
│   ├── local/hive_service.dart     # Init do Hive e boxes
│   └── repositories/               # (reservado para futura camada remota)
└── presentation/
    ├── providers/                  # Riverpod: app_controller, settings, derived
    ├── shell/home_shell.dart       # Navegação inferior + menu lateral
    ├── screens/                    # Todas as telas
    └── widgets/common.dart         # Componentes reutilizáveis
```

O `AppController` (Riverpod `Notifier`) centraliza a lógica de negócio e é o
único ponto que grava no Hive. Isso facilita, no futuro, plugar um repositório
remoto (Firebase) por trás da mesma interface, sem alterar a UI.

## Premissas dos cálculos (documentadas e fáceis de ajustar)

Tudo está em `core/utils/loan_calculator.dart`:

- **Penhor:** `juros = capital × taxa%`. O cliente paga só os juros; ao devolver
  o capital, encerra-se o empréstimo.
- **Diário:** a taxa é interpretada como **percentual total sobre o período**.
  `total = capital × (1 + taxa%)`, dividido igualmente pelos dias (o último dia
  absorve o arredondamento). 1º vencimento no dia seguinte ao início.
- **Parcelado (flat):** `juros = capital × taxa%`; `total = capital + juros`;
  `parcela = total ÷ nº parcelas` (última parcela ajusta o arredondamento);
  vencimentos mensais.

Se o seu negócio usa outra convenção (ex.: juros compostos ou juros por mês),
basta ajustar essas funções — o restante do app continua funcionando.

## Funcionalidades

- Cadastro de clientes com foto, documento, CPF, telefone, endereço, GPS,
  dados do comércio e observações.
- Três modalidades de empréstimo com **simulação em tempo real**.
- Baixa de pagamentos, estorno, recebimento de juros e encerramento.
- **Cobranças do dia** e **mapa de visitas** (ordena e abre rota no Google Maps).
- **Dashboard** com métricas e gráfico de recebimentos mensais.
- **Relatórios** por cliente, período e modalidade (com compartilhamento).
- **Histórico** (auditoria de todas as ações).
- **Configurações:** tema claro/escuro, moeda, backup e restauração (.json).

## Rumo a SaaS (próximos passos sugeridos)

- Adicionar `firebase_core` + `cloud_firestore` e um `RemoteRepository`
  implementando a mesma interface do `AppController`.
- Autenticação (`firebase_auth`) para múltiplos usuários.
- Sincronização offline-first (Hive local ↔ Firestore).
- Camada de assinatura (RevenueCat / Play Billing).

## Observação legal

Este é um software de **controle e organização financeira**. As taxas de juros,
o registro da atividade e as práticas de cobrança devem respeitar a legislação
aplicável na sua região. O app não impõe nem sugere taxas.
