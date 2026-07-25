/// Enumeradores centrais do domínio.
///
/// Os valores são persistidos no Hive pelo seu `index`, portanto NÃO reordene
/// os itens existentes (apenas acrescente novos no final) para manter a
/// compatibilidade com dados já gravados.

/// Modalidade do empréstimo.
enum LoanType {
  pledge, // Penhor: cliente paga apenas os juros até devolver o capital.
  daily, // Diário: agenda diária de pagamentos por um prazo em dias.
  installment, // Parcelado: capital + juros divididos em parcelas mensais.
}

extension LoanTypeX on LoanType {
  String get label => switch (this) {
        LoanType.pledge => 'Penhor',
        LoanType.daily => 'Diário',
        LoanType.installment => 'Parcelado',
      };

  String get description => switch (this) {
        LoanType.pledge => 'Cliente paga apenas os juros até devolver o capital.',
        LoanType.daily => 'Agenda diária de cobranças por um prazo em dias.',
        LoanType.installment => 'Capital + juros divididos em parcelas mensais.',
      };
}

/// Situação geral do empréstimo.
enum LoanStatus { active, closed, overdue }

extension LoanStatusX on LoanStatus {
  String get label => switch (this) {
        LoanStatus.active => 'Ativo',
        LoanStatus.closed => 'Encerrado',
        LoanStatus.overdue => 'Atrasado',
      };
}

/// Situação de uma parcela / dia da agenda.
enum PaymentStatus { paid, overdue, future }

extension PaymentStatusX on PaymentStatus {
  String get label => switch (this) {
        PaymentStatus.paid => 'Pago',
        PaymentStatus.overdue => 'Atrasado',
        PaymentStatus.future => 'Futuro',
      };
}

/// Tipo de comércio (usado na modalidade Diário).
enum BusinessType { grocery, restaurant, store, workshop, bar, other }

extension BusinessTypeX on BusinessType {
  String get label => switch (this) {
        BusinessType.grocery => 'Mercadinho',
        BusinessType.restaurant => 'Restaurante',
        BusinessType.store => 'Loja',
        BusinessType.workshop => 'Oficina',
        BusinessType.bar => 'Bar',
        BusinessType.other => 'Outros',
      };
}
