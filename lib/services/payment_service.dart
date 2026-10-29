import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Result of creating a Xendit invoice.
class InvoiceResult {
  final String url;
  final String externalId;

  const InvoiceResult({required this.url, required this.externalId});
}

class PaymentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Calls the Supabase Edge Function `create-invoice`.
  /// The function creates its own `external_id` (order_<timestamp>), so the
  /// app must use the `external_id` returned here to check the order status.
  Future<InvoiceResult?> createXenditInvoice({
    required String productName,
    required double amount,
    required String payerEmail,
    int? productId,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'create-invoice',
        body: {
          'product_name': productName,
          'amount': amount,
          'payer_email': payerEmail,
          if (productId != null) 'product_id': productId,
        },
      );

      if (response.status == 200 && response.data != null) {
        final data = response.data is String
            ? jsonDecode(response.data)
            : response.data;

        final url = (data['invoice_url'] ?? data['invoiceUrl'])?.toString();
        final externalId = (data['external_id'] ?? data['externalId'])?.toString();

        if (url == null || url.isEmpty || externalId == null || externalId.isEmpty) {
          debugPrint('Invoice response is missing invoice_url or external_id: $data');
          return null;
        }
        return InvoiceResult(url: url, externalId: externalId);
      } else {
        debugPrint('Error creating invoice: ${response.status} - ${response.data}');
        return null;
      }
    } catch (e) {
      debugPrint('Exception while calling create-invoice: $e');
      return null;
    }
  }

  /// Returns the current stock of a product, or null if it cannot be read.
  Future<int?> getProductStock(String productId) async {
    try {
      final id = int.tryParse(productId);
      if (id == null) return null;
      final data = await _supabase
          .from('products')
          .select('stock')
          .eq('id', id)
          .maybeSingle();
      final stock = data?['stock'];
      return stock == null ? null : (stock as num).toInt();
    } catch (e) {
      debugPrint('Error fetching product stock: $e');
      return null;
    }
  }

  /// Reads the order status from the Supabase `orders` table using external_id.
  /// The `xendit-webhook` function sets it to PAID when Xendit confirms payment.
  Future<String?> getInvoiceStatus(String externalId) async {
    try {
      final data = await _supabase
          .from('orders')
          .select('status')
          .eq('external_id', externalId)
          .maybeSingle();

      if (data != null) {
        return data['status']?.toString();
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching order status: $e');
      return null;
    }
  }
}
 