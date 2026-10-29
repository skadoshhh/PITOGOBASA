import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/payment_service.dart';
import '../screens/xendit_webview_screens.dart';

const Color bgColor = Color(0xFF0D0D0D);
const Color cardColor = Color(0xFF1C1C1C);
const Color accentColor = Color(0xFF00E676);

/// TEST MODE: when true, tapping "I have completed the payment" on the
/// payment screen marks the order as PAID even if the server status check
/// cannot confirm it (e.g. Supabase `orders` table is missing).
/// Set this to false in production and rely on real status verification.
const bool kTrustUserConfirmation = true;

class OrderRecord {
  final String orderId;
  final String productName;
  final String imageUrl;
  final String size;
  final double amount;
  final DateTime createdAt;
  final String customerFullName;
  final String customerPhone;
  final String customerEmail;
  final String deliveryAddress;
  String status; // 'PENDING' or 'PAID'
  String? paymentUrl;

  OrderRecord({
    required this.orderId,
    required this.productName,
    required this.imageUrl,
    required this.size,
    required this.amount,
    required this.createdAt,
    required this.customerFullName,
    required this.customerPhone,
    required this.customerEmail,
    required this.deliveryAddress,
    this.status = 'PENDING',
    this.paymentUrl,
  });

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'productName': productName,
        'imageUrl': imageUrl,
        'size': size,
        'amount': amount,
        'createdAt': createdAt.toIso8601String(),
        'customerFullName': customerFullName,
        'customerPhone': customerPhone,
        'customerEmail': customerEmail,
        'deliveryAddress': deliveryAddress,
        'status': status,
        'paymentUrl': paymentUrl,
      };

  factory OrderRecord.fromJson(Map<String, dynamic> json) => OrderRecord(
        orderId: json['orderId'],
        productName: json['productName'],
        imageUrl: json['imageUrl'],
        size: json['size'],
        amount: (json['amount'] as num).toDouble(),
        createdAt: DateTime.parse(json['createdAt'] ?? json['paidAt']),
        customerFullName: json['customerFullName'],
        customerPhone: json['customerPhone'],
        customerEmail: json['customerEmail'],
        deliveryAddress: json['deliveryAddress'],
        status: json['status'] ?? 'PAID',
        paymentUrl: json['paymentUrl'],
      );
}

final ValueNotifier<List<OrderRecord>> paidOrders =
    ValueNotifier<List<OrderRecord>>(<OrderRecord>[]);

const String _storageKey = 'saved_paid_orders_key';

Future<void> loadPaidOrders() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_storageKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      final List<dynamic> decodedList = jsonDecode(jsonString);
      paidOrders.value =
          decodedList.map((item) => OrderRecord.fromJson(item)).toList();
    }
  } catch (e) {
    debugPrint('Error loading orders: $e');
  }
}

Future<void> persistOrders() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final String encodedList =
        jsonEncode(paidOrders.value.map((o) => o.toJson()).toList());
    await prefs.setString(_storageKey, encodedList);
  } catch (e) {
    debugPrint('Error saving orders: $e');
  }
}

Future<void> addPaidOrder(OrderRecord order) async {
  final index = paidOrders.value.indexWhere((o) => o.orderId == order.orderId);
  if (index >= 0) {
    paidOrders.value[index] = order;
    paidOrders.value = List.from(paidOrders.value);
  } else {
    paidOrders.value = [order, ...paidOrders.value];
  }
  await persistOrders();
}

/// Checks every PENDING order with Xendit and marks it PAID when it was paid.
Future<void> refreshPendingOrders() async {
  final service = PaymentService();
  var changed = false;
  final pending = paidOrders.value.where((o) => o.status == 'PENDING').toList();
  for (final order in pending) {
    try {
      final status = await service
          .getInvoiceStatus(order.orderId)
          .timeout(const Duration(seconds: 15));
      final s = (status ?? '').toUpperCase();
      if (s == 'PAID' || s == 'SETTLED') {
        order.status = 'PAID';
        changed = true;
      }
    } catch (_) {}
  }
  if (changed) {
    paidOrders.value = List.from(paidOrders.value);
    await persistOrders();
  }
}

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void initState() {
    super.initState();
    // Reload saved orders, then check pending ones with Xendit.
    loadPaidOrders().then((_) => refreshPendingOrders());
  }

  String _formatDate(DateTime d) {
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'PM' : 'AM';
    return '${_months[d.month - 1]} ${d.day}, ${d.year} • $hour12:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'ORDER RECORDS',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<List<OrderRecord>>(
          valueListenable: paidOrders,
          builder: (context, orders, _) {
            if (orders.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'NO ORDERS FOUND',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'ORDER RECORD',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              );
            }

            final totalPaid = orders
                .where((o) => o.status == 'PAID')
                .fold<double>(0, (sum, o) => sum + o.amount);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${orders.length} TOTAL ORDER${orders.length == 1 ? '' : 'S'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              'TOTAL PAID: PHP ${totalPaid.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final order = orders[index - 1];
                    return _OrderCard(
                      order: order,
                      dateText: _formatDate(order.createdAt),
                      onStatusUpdated: () => setState(() {}),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final OrderRecord order;
  final String dateText;
  final VoidCallback onStatusUpdated;

  const _OrderCard({
    Key? key,
    required this.order,
    required this.dateText,
    required this.onStatusUpdated,
  }) : super(key: key);

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  final PaymentService _paymentService = PaymentService();
  bool _isProcessing = false;

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.white38),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _continuePayment() async {
    final paymentUrl = widget.order.paymentUrl;
    if (paymentUrl == null || paymentUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment URL not available for this order.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final dynamic webviewResult = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute<dynamic>(
        builder: (_) => XenditWebViewScreen(invoiceUrl: paymentUrl),
      ),
    );

    try {
      String? status;
      try {
        status = await _paymentService
            .getInvoiceStatus(widget.order.orderId)
            .timeout(const Duration(seconds: 15));
      } catch (e) {
        debugPrint('Status check failed: $e');
      }
      final s = (status ?? '').toUpperCase();
      if ((kTrustUserConfirmation && webviewResult == true) ||
          s == 'PAID' ||
          s == 'SETTLED') {
        widget.order.status = 'PAID';
        await persistOrders();
        widget.onStatusUpdated();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order marked as PAID!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isPaid = order.status == 'PAID';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPaid ? Colors.white12 : Colors.orangeAccent.withOpacity(0.4),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: Image.network(
                    order.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF292929),
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isPaid
                                ? accentColor.withOpacity(0.15)
                                : Colors.orangeAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isPaid ? 'PAID' : 'PENDING',
                            style: TextStyle(
                              color: isPaid ? accentColor : Colors.orangeAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.dateText,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      order.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Size ${order.size}  •  PHP ${order.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isPaid ? accentColor : Colors.orangeAccent,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _infoRow(Icons.tag, order.orderId),
                    _infoRow(Icons.person_outline, order.customerFullName),
                    _infoRow(Icons.phone_outlined, order.customerPhone),
                    _infoRow(Icons.location_on_outlined, order.deliveryAddress),
                  ],
                ),
              ),
            ],
          ),
          if (!isPaid && order.paymentUrl != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isProcessing ? null : _continuePayment,
                icon: _isProcessing
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.payment, size: 18),
                label: Text(
                  _isProcessing ? 'CHECKING...' : 'CONTINUE TO PAYMENT',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}