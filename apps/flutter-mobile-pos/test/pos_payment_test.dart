import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_mobile_pos/models/device_session.dart';
import 'package:flutter_mobile_pos/models/payment_tender.dart';
import 'package:flutter_mobile_pos/models/pos_product.dart';
import 'package:flutter_mobile_pos/providers/pos_cart_provider.dart';
import 'package:flutter_mobile_pos/providers/pos_payment_provider.dart';
import 'package:flutter_mobile_pos/services/esc_pos_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sampleProduct = PosProduct(
    id: 1,
    uuid: 'p-1',
    name: 'Apple iPhone 16 Pro Max 256GB',
    sku: 'TECH-IPH-16PM',
    barcode: '445566',
    category: 'Smartphones & Tech',
    brand: 'Apple',
    sellingPrice: 400000.0,
    stock: 15,
  );

  group('PosPaymentProvider Split Tender & Change Tests', () {
    test('Payment state computes remaining balance correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const targetTotal = 400000.0;
      final paymentNotifier = container.read(posPaymentProvider.notifier);

      expect(container.read(posPaymentProvider).remaining(targetTotal), equals(400000.0));
      expect(container.read(posPaymentProvider).isFullyPaid(targetTotal), isFalse);

      // Add Cash Tender LKR 100,000
      paymentNotifier.addTender(
        PaymentTender(method: PosPaymentMethod.cash, amount: 100000.0),
      );

      expect(container.read(posPaymentProvider).paidSoFar, equals(100000.0));
      expect(container.read(posPaymentProvider).remaining(targetTotal), equals(300000.0));
      expect(container.read(posPaymentProvider).isFullyPaid(targetTotal), isFalse);

      // Add Card Tender LKR 300,000 (Split Tender Complete)
      paymentNotifier.addTender(
        PaymentTender(method: PosPaymentMethod.card, amount: 300000.0, reference: 'AUTH-12345'),
      );

      expect(container.read(posPaymentProvider).paidSoFar, equals(400000.0));
      expect(container.read(posPaymentProvider).remaining(targetTotal), equals(0.0));
      expect(container.read(posPaymentProvider).isFullyPaid(targetTotal), isTrue);
    });

    test('Cash payment calculates change due when tendered > total', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const targetTotal = 78500.0;
      final paymentNotifier = container.read(posPaymentProvider.notifier);

      // Customer hands 80,000 LKR in cash for 78,500 LKR total
      paymentNotifier.addTender(
        PaymentTender(
          method: PosPaymentMethod.cash,
          amount: 78500.0,
          tenderedAmount: 80000.0,
          changeAmount: 1500.0,
        ),
      );

      final change = container.read(posPaymentProvider).calculateChange(targetTotal);
      expect(change, equals(1500.0));
    });

    test('Gift card verification and application', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final paymentNotifier = container.read(posPaymentProvider.notifier);
      final balance = await paymentNotifier.verifyGiftCard('GC-LUXE-2026', 50000.0);

      expect(balance, isNotNull);
      expect(balance! > 0, isTrue);
      expect(container.read(posPaymentProvider).giftCardCode, equals('GC-LUXE-2026'));
    });

    test('VIP loyalty points discount applies properly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final paymentNotifier = container.read(posPaymentProvider.notifier);
      paymentNotifier.applyLoyaltyPoints(250, 100000.0); // 250 pts = 2,500 LKR discount

      final state = container.read(posPaymentProvider);
      expect(state.loyaltyDiscount, equals(2500.0));
      expect(state.remaining(100000.0), equals(97500.0));
    });

    test('Completing sale clears register cart and creates SaleReceipt', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 1. Populate cart
      final cartNotifier = container.read(posCartProvider.notifier);
      cartNotifier.addItem(sampleProduct, quantity: 1);
      final cartState = container.read(posCartProvider);

      // 2. Tender payment
      final paymentNotifier = container.read(posPaymentProvider.notifier);
      paymentNotifier.addTender(
        PaymentTender(method: PosPaymentMethod.cash, amount: 400000.0),
      );

      // 3. Complete sale
      const session = DeviceSession(deviceCode: 'ROAMING-01', storeName: 'OmniLuxe Flagship');
      final receipt = await paymentNotifier.completeSale(
        cart: cartState,
        session: session,
        printReceipt: true,
        sendSms: false,
      );

      expect(receipt, isNotNull);
      expect(receipt!.invoiceNumber, startsWith('INV-'));
      expect(receipt.totalAmount, equals(400000.0));
      expect(receipt.terminalCode, equals('ROAMING-01'));
      expect(receipt.loyaltyPointsEarned > 0, isTrue);

      // Cart should be reset for next shopper
      expect(container.read(posCartProvider).isEmpty, isTrue);
    });
  });

  group('EscPosService Thermal Receipt Tests', () {
    test('Builds ESC/POS binary buffer containing init, header, and cut commands for 58mm', () {
      final receipt = SaleReceipt(
        uuid: 'test-uuid-001',
        invoiceNumber: 'INV-TEST-8899',
        storeName: 'OmniLuxe Flagship',
        terminalCode: 'ROAMING-01',
        cashierName: 'Chanaka Staff',
        soldAt: DateTime(2026, 11, 18, 20, 30),
        items: [],
        subtotal: 50000.0,
        discountAmount: 2500.0,
        taxAmount: 3800.0,
        totalAmount: 51300.0,
        paidAmount: 51300.0,
        changeAmount: 0.0,
        payments: [
          PaymentTender(method: PosPaymentMethod.cash, amount: 51300.0),
        ],
        loyaltyPointsEarned: 255,
      );

      final bytes58 = EscPosService.buildReceiptBytes(receipt, width: PrinterPaperWidth.mm58);
      expect(bytes58.isNotEmpty, isTrue);

      // Verify ESC/POS Init header (0x1B, 0x40)
      expect(bytes58[0], equals(0x1B));
      expect(bytes58[1], equals(0x40));

      // Verify Paper Cut command (0x1D, 0x56, 0x00)
      final len = bytes58.length;
      expect(bytes58[len - 3], equals(0x1D));
      expect(bytes58[len - 2], equals(0x56));
      expect(bytes58[len - 1], equals(0x00));

      // Verify 80mm width buffer
      final bytes80 = EscPosService.buildReceiptBytes(receipt, width: PrinterPaperWidth.mm80);
      expect(bytes80.isNotEmpty, isTrue);
      expect(EscPosService.printAuditLog.isNotEmpty, isTrue);
    });
  });
}
