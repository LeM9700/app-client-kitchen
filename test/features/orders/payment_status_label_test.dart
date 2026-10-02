import 'package:flutter_test/flutter_test.dart';

import 'package:app_client/features/orders/models/payment_status_label.dart';

void main() {
  test('known payment statuses have a readable label', () {
    expect(paymentStatusLabel('paid'), 'Payé');
    expect(
      paymentStatusLabel('guaranteed'),
      'Empreinte bancaire : à régler à la livraison',
    );
    expect(paymentStatusLabel('guarantee_released'), contains('rien'));
    expect(paymentStatusLabel('guarantee_captured'), contains('débitée'));
  });

  test('unknown statuses are shown as is, never hidden', () {
    expect(paymentStatusLabel('something_new'), 'something_new');
  });
}
