import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecommerce_app/providers/cart_order_provider.dart';

/// Checkout screen with address form and dummy payment.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  int _step = 0; // 0 = address, 1 = payment, 2 = confirmation
  final _formKey = GlobalKey<FormState>();
  bool _isPlacing = false;

  // Address fields
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _line1Ctrl = TextEditingController();
  final _line2Ctrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();

  String _paymentMethod = 'cod';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _line1Ctrl.dispose();
    _line2Ctrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _address => {
        'name': _nameCtrl.text,
        'phone': _phoneCtrl.text,
        'line1': _line1Ctrl.text,
        'line2': _line2Ctrl.text,
        'city': _cityCtrl.text,
        'state': _stateCtrl.text,
        'pincode': _pinCtrl.text,
      };

  Future<void> _placeOrder() async {
    setState(() => _isPlacing = true);
    try {
      final order = await ref.read(cartProvider.notifier).placeOrder(
            shippingAddress: _address,
            paymentMethod: _paymentMethod,
          );
      if (mounted) {
        setState(() {
          _step = 2;
          _isPlacing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order ${order.orderNumber} placed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPlacing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to place order: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = ref.watch(cartSubtotalProvider);
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: BackButton(onPressed: () {
          if (_step == 2) {
            context.go('/orders');
          } else if (_step > 0) {
            setState(() => _step--);
          } else {
            context.pop();
          }
        }),
      ),
      body: _step == 2
          ? _buildConfirmation(context)
          : isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: _step == 0
                            ? _buildAddressForm()
                            : _buildPaymentForm(),
                      ),
                    ),
                    SizedBox(
                      width: 370,
                      child: _buildSummary(subtotal),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Stepper indicator
                      _buildStepper(),
                      const SizedBox(height: 16),
                      if (_step == 0) _buildAddressForm(),
                      if (_step == 1) _buildPaymentForm(),
                      const SizedBox(height: 16),
                      _buildSummary(subtotal),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStepper() {
    return Row(
      children: [
        _StepCircle(number: 1, label: 'Address', isActive: _step >= 0,
            isDone: _step > 0),
        Expanded(
            child: Container(height: 2,
                color: _step > 0 ? Colors.green : Colors.grey[300])),
        _StepCircle(number: 2, label: 'Payment', isActive: _step >= 1,
            isDone: _step > 1),
        Expanded(
            child: Container(height: 2,
                color: _step > 1 ? Colors.green : Colors.grey[300])),
        _StepCircle(number: 3, label: 'Done', isActive: _step >= 2,
            isDone: _step >= 2),
      ],
    );
  }

  Widget _buildAddressForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shipping Address',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Full Name *',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneCtrl,
            decoration: const InputDecoration(
              labelText: 'Phone Number *',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (v) => v == null || v.length < 10 ? 'Enter valid phone' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _line1Ctrl,
            decoration: const InputDecoration(
              labelText: 'Address Line 1 *',
              prefixIcon: Icon(Icons.home),
              border: OutlineInputBorder(),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _line2Ctrl,
            decoration: const InputDecoration(
              labelText: 'Address Line 2',
              prefixIcon: Icon(Icons.location_on),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cityCtrl,
                  decoration: const InputDecoration(
                    labelText: 'City *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _stateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'State *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _pinCtrl,
            decoration: const InputDecoration(
              labelText: 'PIN Code *',
              prefixIcon: Icon(Icons.pin_drop),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (v) => v == null || v.length < 6 ? 'Enter valid PIN' : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  setState(() => _step = 1);
                }
              },
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Continue to Payment',
                  style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment Method',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Select a payment method (Dummy - no real payment)',
            style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 16),
        _PaymentOption(
          title: 'Cash on Delivery',
          subtitle: 'Pay when you receive the order',
          icon: Icons.payments_outlined,
          value: 'cod',
          groupValue: _paymentMethod,
          onChanged: (v) => setState(() => _paymentMethod = v!),
        ),
        _PaymentOption(
          title: 'Credit / Debit Card',
          subtitle: 'Visa, Mastercard, RuPay',
          icon: Icons.credit_card,
          value: 'card',
          groupValue: _paymentMethod,
          onChanged: (v) => setState(() => _paymentMethod = v!),
        ),
        _PaymentOption(
          title: 'UPI',
          subtitle: 'Google Pay, PhonePe, Paytm',
          icon: Icons.account_balance,
          value: 'upi',
          groupValue: _paymentMethod,
          onChanged: (v) => setState(() => _paymentMethod = v!),
        ),
        _PaymentOption(
          title: 'Net Banking',
          subtitle: 'All major banks',
          icon: Icons.account_balance_wallet,
          value: 'net_banking',
          groupValue: _paymentMethod,
          onChanged: (v) => setState(() => _paymentMethod = v!),
        ),
        _PaymentOption(
          title: 'Wallet',
          subtitle: 'Paytm, Amazon Pay',
          icon: Icons.wallet,
          value: 'wallet',
          groupValue: _paymentMethod,
          onChanged: (v) => setState(() => _paymentMethod = v!),
        ),
        const SizedBox(height: 24),
        // Address summary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Delivering to:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(_nameCtrl.text),
                Text('${_line1Ctrl.text}, ${_line2Ctrl.text}'),
                Text('${_cityCtrl.text}, ${_stateCtrl.text} - ${_pinCtrl.text}'),
                Text(_phoneCtrl.text),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isPlacing ? null : _placeOrder,
            style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.green),
            child: _isPlacing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Place Order',
                    style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(double subtotal) {
    final tax = subtotal * 0.18;
    final shipping = subtotal > 500 ? 0.0 : 50.0;
    final total = subtotal + tax + shipping;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Price Details',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _PriceRow('Subtotal', '₹${subtotal.toStringAsFixed(0)}'),
            _PriceRow('GST (18%)', '₹${tax.toStringAsFixed(0)}'),
            _PriceRow('Shipping',
                shipping > 0 ? '₹${shipping.toStringAsFixed(0)}' : 'FREE'),
            const Divider(),
            _PriceRow('Total', '₹${total.toStringAsFixed(0)}',
                isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmation(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 100),
            const SizedBox(height: 24),
            Text('Order Placed Successfully!',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Your order has been placed and is being processed.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.go('/orders'),
              icon: const Icon(Icons.receipt_long),
              label: const Text('View My Orders'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.shopping_bag),
              label: const Text('Continue Shopping'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String title, subtitle, value, groupValue;
  final IconData icon;
  final ValueChanged<String?> onChanged;

  const _PaymentOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return Card(
      color: selected
          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      child: RadioListTile<String>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        title: Row(children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label, value;
  final bool isBold;
  const _PriceRow(this.label, this.value, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: isBold ? 16 : 14)),
          Text(value,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: isBold ? 16 : 14)),
        ],
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  final int number;
  final String label;
  final bool isActive;
  final bool isDone;

  const _StepCircle({
    required this.number,
    required this.label,
    required this.isActive,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor:
              isDone ? Colors.green : (isActive ? Theme.of(context).colorScheme.primary : Colors.grey[300]),
          child: isDone
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text('$number',
                  style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: isActive ? null : Colors.grey,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
      ],
    );
  }
}
