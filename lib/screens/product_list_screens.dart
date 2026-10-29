import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';
import '../services/payment_service.dart';
import '../screens/xendit_webview_screens.dart';
import '../screens/orders_screen.dart';

const Color bgColor = Color(0xFF0D0D0D);
const Color cardColor = Color(0xFF1C1C1C);
const Color accentColor = Color(0xFF00E676);


class CartItem {
  final Product product;
  final String size;
  int quantity;

  CartItem({required this.product, required this.size, this.quantity = 1});

  double get subtotal => product.price * quantity;
}

final ValueNotifier<List<CartItem>> cartItemsNotifier =
    ValueNotifier<List<CartItem>>(<CartItem>[]);

void addItemToCart(Product product, String size) {
  final items = List<CartItem>.from(cartItemsNotifier.value);
  final index = items.indexWhere(
    (item) => item.product.id == product.id && item.size == size,
  );
  if (index >= 0) {
    items[index].quantity++;
  } else {
    items.add(CartItem(product: product, size: size));
  }
  cartItemsNotifier.value = items;
}

class CustomerInfo {
  final String fullName;
  final String phone;
  final String email;
  final String address;

  const CustomerInfo({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.address,
  });
}

class CustomerInfoDialog extends StatefulWidget {
  final CustomerInfo? initial;

  const CustomerInfoDialog({Key? key, this.initial}) : super(key: key);

  @override
  State<CustomerInfoDialog> createState() => _CustomerInfoDialogState();
}

class _CustomerInfoDialogState extends State<CustomerInfoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _fullNameController =
        TextEditingController(text: widget.initial?.fullName ?? '');
    _phoneController =
        TextEditingController(text: widget.initial?.phone ?? '');
    _emailController =
        TextEditingController(text: widget.initial?.email ?? '');
    _addressController =
        TextEditingController(text: widget.initial?.address ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      CustomerInfo(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: accentColor),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accentColor),
        ),
        errorStyle: const TextStyle(color: Colors.orangeAccent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1C1C1C),
      title: const Text(
        'CLIENT INFORMATION',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Fill in all details before ordering.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 16),
                _field(
                  controller: _fullNameController,
                  label: 'Full name',
                  icon: Icons.person_outline,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter your full name'
                      : null,
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _phoneController,
                  label: 'Cellphone number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    final phone = value?.trim() ?? '';
                    if (phone.isEmpty) return 'Please enter your cellphone number';
                    if (phone.length < 7) return 'Please enter a valid phone number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _emailController,
                  label: 'Email address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return 'Please enter your email address';
                    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _addressController,
                  label: 'Delivery address',
                  icon: Icons.location_on_outlined,
                  maxLines: 3,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter your delivery address'
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'CANCEL',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.black,
          ),
          onPressed: _save,
          child: const Text(
            'SAVE INFORMATION',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ScrollController _scrollController = ScrollController();

  String _customerFullName = '';
  String _customerPhone = '';
  String _customerEmail = '';
  String _deliveryAddress = '';

  bool get _hasCustomerInformation =>
      _customerFullName.trim().isNotEmpty &&
      _customerPhone.trim().isNotEmpty &&
      _customerEmail.trim().isNotEmpty &&
      _deliveryAddress.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadCustomerInfo();
    loadPaidOrders();
    _loadProducts();
  }

  Future<void> _loadCustomerInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _customerFullName = prefs.getString('saved_customer_name') ?? '';
      _customerPhone = prefs.getString('saved_customer_phone') ?? '';
      _customerEmail = prefs.getString('saved_customer_email') ?? '';
      _deliveryAddress = prefs.getString('saved_customer_address') ?? '';
    });
  }

  Future<void> _saveCustomerInfo(CustomerInfo info) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_customer_name', info.fullName);
    await prefs.setString('saved_customer_phone', info.phone);
    await prefs.setString('saved_customer_email', info.email);
    await prefs.setString('saved_customer_address', info.address);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<bool> _showCustomerProfileDialog() async {
    final result = await showDialog<CustomerInfo>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CustomerInfoDialog(
        initial: CustomerInfo(
          fullName: _customerFullName,
          phone: _customerPhone,
          email: _customerEmail,
          address: _deliveryAddress,
        ),
      ),
    );

    if (result == null || !mounted) return false;

    await _saveCustomerInfo(result);

    setState(() {
      _customerFullName = result.fullName;
      _customerPhone = result.phone;
      _customerEmail = result.email;
      _deliveryAddress = result.address;
    });

    return true;
  }

  List<Product> _products = [];
  Map<String, int> _stockById = {};
  bool _loadingProducts = true;

  /// Loads the products from the Supabase `products` table.
  Future<void> _loadProducts() async {
    try {
      final rows = await Supabase.instance.client
          .from('products')
          .select()
          .order('id');

      final loaded = rows
          .map<Product>((r) => Product(
                id: r['id'].toString(),
                name: (r['name'] ?? '').toString(),
                price: (r['price'] as num).toDouble(),
                imageUrl: (r['image_url'] ?? '').toString(),
                description: (r['description'] ?? '').toString(),
              ))
          .toList();

      final stocks = <String, int>{
        for (final r in rows)
          if (r['stock'] != null) r['id'].toString(): (r['stock'] as num).toInt(),
      };

      if (!mounted) return;
      setState(() {
        _products = loaded;
        _stockById = stocks;
        _loadingProducts = false;
      });
    } catch (e) {
      debugPrint('Error loading products: $e');
      if (!mounted) return;
      setState(() => _loadingProducts = false);
    }
  }

  Future<void> _openProduct(Product product) async {
    if (!_hasCustomerInformation) {
      final saved = await _showCustomerProfileDialog();
      if (!saved || !_hasCustomerInformation || !mounted) return;
    }

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductPaymentScreen(
          product: product,
          stock: _stockById[product.id],
          customerFullName: _customerFullName,
          customerPhone: _customerPhone,
          customerEmail: _customerEmail,
          deliveryAddress: _deliveryAddress,
          onAddToCart: (size) {
            addItemToCart(product, size);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${product.name} added to cart'),
                backgroundColor: accentColor,
              ),
            );
          },
        ),
      ),
    );

    // Refresh the stock after coming back from the product page.
    if (mounted) _loadProducts();
  }

  void _openOrderHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: CustomBrandAppBar(
        logoPath: 'assets/images/logo.png',
        hasCustomerInformation: _hasCustomerInformation,
        onProfileTap: () async {
          await _showCustomerProfileDialog();
        },
        onOrdersTap: _openOrderHistory,
        onCartTap: () async {
          if (!_hasCustomerInformation) {
            final saved = await _showCustomerProfileDialog();
            if (!saved || !_hasCustomerInformation || !mounted) return;
          }
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CartScreen(
                customerFullName: _customerFullName,
                customerPhone: _customerPhone,
                customerEmail: _customerEmail,
                deliveryAddress: _deliveryAddress,
                stockById: _stockById,
              ),
            ),
          );
          if (mounted) _loadProducts();
        },
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final columns = screenWidth < 600
                ? 1
                : screenWidth < 900
                    ? 2
                    : 4;

            return Scrollbar(
              controller: _scrollController,
              thumbVisibility: screenWidth >= 600,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 1100,
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            screenWidth < 600 ? 18 : 24,
                            26,
                            screenWidth < 600 ? 18 : 24,
                            22,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'OWN YOUR STYLE.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Discover the latest streetwear collection.',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 25),
                              const Text(
                                'OUR COLLECTION',
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_products.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: _loadingProducts
                              ? const CircularProgressIndicator(
                                  color: accentColor,
                                )
                              : Text(
                                  'NO PRODUCTS AVAILABLE',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth < 600 ? 16 : 24,
                    ),
                    sliver: SliverGrid(
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 16,
                        childAspectRatio: columns == 1
                            ? 0.95
                            : columns == 2
                                ? 0.70
                                : 0.64,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = _products[index];

                          return ZoomProductCard(
                            product: product,
                            stock: _stockById[product.id],
                            onTap: () => _openProduct(product),
                          );
                        },
                        childCount: _products.length,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        30,
                        16,
                        40,
                      ),
                      child: Center(
                        child: Text(
                          'A&Mstreetwear • STYLE YOUR WAY',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class ProductPaymentScreen extends StatefulWidget {
  final Product product;
  final String customerFullName;
  final String customerPhone;
  final String customerEmail;
  final String deliveryAddress;
  final int? stock;
  final ValueChanged<String> onAddToCart;

  const ProductPaymentScreen({
    Key? key,
    required this.product,
    this.stock,
    required this.customerFullName,
    required this.customerPhone,
    required this.customerEmail,
    required this.deliveryAddress,
    required this.onAddToCart,
  }) : super(key: key);

  @override
  State<ProductPaymentScreen> createState() =>
      _ProductPaymentScreenState();
}

class _ProductPaymentScreenState extends State<ProductPaymentScreen> {
  final PaymentService _paymentService = PaymentService();

  String _selectedSize = 'M';
  bool _isLoading = false;
  int? _stock;

  bool get _soldOut => _stock != null && _stock! <= 0;

  @override
  void initState() {
    super.initState();
    _stock = widget.stock;
    _refreshStock();
  }

  Future<void> _refreshStock() async {
    final s = await _paymentService.getProductStock(widget.product.id);
    if (!mounted || s == null) return;
    setState(() => _stock = s);
  }

  void _showSnack(String message, {Color color = Colors.redAccent}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<bool> _isInvoicePaid(String externalId, dynamic webviewResult) async {
    // The Xendit webhook can take a few seconds, so try a few times.
    for (var attempt = 0; attempt < 4; attempt++) {
      try {
        final status = await _paymentService
            .getInvoiceStatus(externalId)
            .timeout(const Duration(seconds: 15));
        final s = (status ?? '').toUpperCase();
        if (s == 'PAID' || s == 'SETTLED') return true;
      } catch (e) {
        debugPrint('Status check failed: $e');
      }
      if (attempt < 3) await Future.delayed(const Duration(seconds: 2));
    }
    // Fallback (test mode): the customer confirmed the payment.
    return kTrustUserConfirmation && webviewResult == true;
  }

  Future<void> _handleCheckout() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final product = widget.product;

      // Always check the latest stock before creating an invoice.
      final freshStock = await _paymentService.getProductStock(product.id);
      if (freshStock != null) {
        if (!mounted) return;
        setState(() => _stock = freshStock);
        if (freshStock <= 0) {
          _showSnack('Sorry, this item is out of stock.');
          return;
        }
      }

      final invoice = await _paymentService
          .createXenditInvoice(
            productName: '${product.name} (Size: $_selectedSize)',
            amount: product.price,
            payerEmail: widget.customerEmail,
            productId: int.tryParse(product.id),
          )
          .timeout(const Duration(seconds: 30));

      final invoiceUrl = invoice?.url;
      final externalId = invoice?.externalId ?? '';

      if (!mounted) return;

      final paymentUri = invoiceUrl == null || invoiceUrl.trim().isEmpty
          ? null
          : Uri.tryParse(invoiceUrl.trim());

      if (paymentUri != null &&
          (paymentUri.scheme == 'https' || paymentUri.scheme == 'http') &&
          paymentUri.host.isNotEmpty) {
        // Save the order as PENDING right away, so it is always recorded
        // even if the app is restarted or closed during payment.
        final order = OrderRecord(
          orderId: externalId,
          productName: product.name,
          imageUrl: product.imageUrl,
          size: _selectedSize,
          amount: product.price,
          createdAt: DateTime.now(),
          customerFullName: widget.customerFullName,
          customerPhone: widget.customerPhone,
          customerEmail: widget.customerEmail,
          deliveryAddress: widget.deliveryAddress,
          status: 'PENDING',
          paymentUrl: invoiceUrl,
        );
        await addPaidOrder(order);

        final dynamic webviewResult = await Navigator.of(context).push<dynamic>(
          MaterialPageRoute<dynamic>(
            builder: (_) => XenditWebViewScreen(
              invoiceUrl: paymentUri.toString(),
            ),
          ),
        );

        if (!mounted) return;

        final paid = await _isInvoicePaid(externalId, webviewResult);

        if (!mounted) return;

        if (paid) {
          order.status = 'PAID';
          await addPaidOrder(order); // updates the same order record
        }

        if (paid) {
          _showSnack(
            'Payment successful! You can now view your order in Order Records.',
            color: Colors.green,
          );
        } else {
          _showSnack(
            'Order recorded as PENDING. You can complete the payment in Order Records.',
            color: Colors.orangeAccent,
          );
        }
      } else {
        _showSnack(
          'Unable to generate Xendit payment link. Please check PaymentService and Xendit API key, then try again.',
        );
      }
    } on TimeoutException {
      _showSnack(
        'Payment request timed out. Please check your internet connection and Xendit setup, then try again.',
      );
    } catch (e) {
      _showSnack('Payment error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'PRODUCT DETAILS',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(18),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AspectRatio(
                    aspectRatio: 1.05,
                    child: Image.network(
                      product.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: cardColor,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.white54,
                          size: 55,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'A&M STREETWEAR COLLECTION',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  product.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'PHP ${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: accentColor,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 26),
                const Text(
                  'SELECT SIZE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: ['S', 'M', 'L', 'XL', 'XXL'].map((size) {
                    final selected = _selectedSize == size;

                    return ChoiceChip(
                      label: Text(size),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _selectedSize = size);
                      },
                      selectedColor: Colors.white,
                      backgroundColor: cardColor,
                      labelStyle: TextStyle(
                        color: selected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      side: BorderSide(
                        color: selected ? Colors.white : Colors.white24,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 26),
                const Text(
                  'PRODUCT DESCRIPTION',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  product.description,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 25),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        color: accentColor,
                        size: 26,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PAYMENT CHECKOUT',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Continue to the Xendit payment page.',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 54,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _soldOut
                        ? null
                        : () {
                            widget.onAddToCart(_selectedSize);
                            Navigator.pop(context);
                          },
                    icon: const Icon(Icons.add_shopping_cart),
                    label: Text(
                      _soldOut ? 'SOLD OUT' : 'ADD TO CART',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    'Selected size: $_selectedSize${_stock != null ? '  •  Stock: $_stock' : ''}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class CartScreen extends StatefulWidget {
  final String customerFullName;
  final String customerPhone;
  final String customerEmail;
  final String deliveryAddress;
  final Map<String, int> stockById;

  const CartScreen({
    Key? key,
    required this.customerFullName,
    required this.customerPhone,
    required this.customerEmail,
    required this.deliveryAddress,
    required this.stockById,
  }) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _checkingOut = false;
  final PaymentService _paymentService = PaymentService();

  double get _total => cartItemsNotifier.value.fold<double>(
        0,
        (sum, item) => sum + item.subtotal,
      );

  void _updateCart(List<CartItem> items) {
    cartItemsNotifier.value = List<CartItem>.from(items);
  }

  void _showMessage(String message, {Color color = Colors.orangeAccent}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<void> _checkout() async {
    if (_checkingOut || cartItemsNotifier.value.isEmpty) return;
    setState(() => _checkingOut = true);

    try {
      final items = List<CartItem>.from(cartItemsNotifier.value);

      // Check current stock before creating one invoice for the whole cart.
      for (final item in items) {
        final stock = await _paymentService.getProductStock(item.product.id);
        if (stock != null && item.quantity > stock) {
          _showMessage(
            'Not enough stock for ${item.product.name}. Available: $stock',
          );
          return;
        }
        if (stock != null && stock <= 0) {
          _showMessage('${item.product.name} is sold out.');
          return;
        }
      }

      final total = items.fold<double>(0, (sum, item) => sum + item.subtotal);
      final description = items
          .map((item) => '${item.product.name} (Size: ${item.size}, Qty: ${item.quantity})')
          .join(', ');

      final invoice = await _paymentService
          .createXenditInvoice(
            productName: description,
            amount: total,
            payerEmail: widget.customerEmail,
            // Do not send a single product ID for a multi-product transaction.
            productId: items.length == 1 && items.first.quantity == 1
                ? int.tryParse(items.first.product.id)
                : null,
          )
          .timeout(const Duration(seconds: 30));

      final invoiceUrl = invoice?.url;
      final externalId = invoice?.externalId ?? '';
      final uri = invoiceUrl == null ? null : Uri.tryParse(invoiceUrl);

      if (invoice == null ||
          externalId.isEmpty ||
          uri == null ||
          uri.host.isEmpty ||
          (uri.scheme != 'https' && uri.scheme != 'http')) {
        _showMessage('Could not create Xendit checkout. Please try again.');
        return;
      }

      final order = OrderRecord(
        orderId: externalId,
        productName: description,
        imageUrl: items.first.product.imageUrl,
        size: items.map((item) => '${item.size} x${item.quantity}').join(', '),
        amount: total,
        createdAt: DateTime.now(),
        customerFullName: widget.customerFullName,
        customerPhone: widget.customerPhone,
        customerEmail: widget.customerEmail,
        deliveryAddress: widget.deliveryAddress,
        status: 'PENDING',
        paymentUrl: uri.toString(),
      );
      await addPaidOrder(order);

      // One invoice and one order record represent the entire transaction.
      _updateCart([]);
      final result = await Navigator.of(context).push<dynamic>(
        MaterialPageRoute(
          builder: (_) => XenditWebViewScreen(invoiceUrl: uri.toString()),
        ),
      );
      if (!mounted) return;

      String? status;
      try {
        status = await _paymentService
            .getInvoiceStatus(externalId)
            .timeout(const Duration(seconds: 15));
      } catch (_) {}

      final normalized = (status ?? '').toUpperCase();
      final paid = normalized == 'PAID' ||
          normalized == 'SETTLED' ||
          (kTrustUserConfirmation && result == true);

      if (paid) {
        order.status = 'PAID';
        await addPaidOrder(order);
        _showMessage('Payment successful! Your whole cart was paid in one transaction.',
            color: accentColor);
      } else {
        _showMessage('Order saved as PENDING. You can continue payment in Order Records.');
      }
      if (mounted) Navigator.of(context).pop();
    } on TimeoutException {
      _showMessage('Checkout timed out. Check your connection and try again.');
    } catch (e) {
      _showMessage('Checkout error: $e');
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('SHOPPING CART',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
      body: ValueListenableBuilder<List<CartItem>>(
        valueListenable: cartItemsNotifier,
        builder: (context, items, _) {
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.remove_shopping_cart_outlined,
                      size: 64, color: Colors.white38),
                  SizedBox(height: 12),
                  Text('YOUR CART IS EMPTY',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1)),
                  SizedBox(height: 6),
                  Text('Add products to checkout together.',
                      style: TextStyle(color: Colors.white54)),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final stock = widget.stockById[item.product.id];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              item.product.imageUrl,
                              width: 78,
                              height: 88,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(
                                width: 78,
                                height: 88,
                                child: Icon(Icons.image_not_supported,
                                    color: Colors.white54),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.product.name,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('Size: ${item.size}',
                                    style: const TextStyle(color: Colors.white60)),
                                const SizedBox(height: 4),
                                Text('PHP ${item.subtotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        color: accentColor,
                                        fontWeight: FontWeight.w900)),
                                if (stock != null)
                                  Text('Stock: $stock',
                                      style: const TextStyle(
                                          color: Colors.white38, fontSize: 11)),
                                Row(
                                  children: [
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: item.quantity > 1
                                          ? () {
                                              item.quantity--;
                                              _updateCart(items);
                                            }
                                          : null,
                                      icon: const Icon(Icons.remove_circle_outline,
                                          color: Colors.white70),
                                    ),
                                    Text('${item.quantity}',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: stock != null && item.quantity >= stock
                                          ? null
                                          : () {
                                              item.quantity++;
                                              _updateCart(items);
                                            },
                                      icon: const Icon(Icons.add_circle_outline,
                                          color: accentColor),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      tooltip: 'Remove item',
                                      onPressed: () {
                                        final updated = List<CartItem>.from(items)
                                          ..removeAt(index);
                                        _updateCart(updated);
                                      },
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.redAccent),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  border: Border(top: BorderSide(color: Colors.white12)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TOTAL',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1)),
                          Text('PHP ${_total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: accentColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _checkingOut ? null : _checkout,
                          icon: _checkingOut
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.black),
                                )
                              : const Icon(Icons.lock_outline),
                          label: Text(
                            _checkingOut
                                ? 'PROCESSING...'
                                : 'CHECKOUT ALL VIA XENDIT',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, letterSpacing: 0.5),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CustomBrandAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String logoPath;
  final bool hasCustomerInformation;
  final VoidCallback onProfileTap;
  final VoidCallback onOrdersTap;
  final VoidCallback onCartTap;

  const CustomBrandAppBar({
    Key? key,
    required this.logoPath,
    required this.hasCustomerInformation,
    required this.onProfileTap,
    required this.onOrdersTap,
    required this.onCartTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 4,
      centerTitle: true,
      actions: [
        ValueListenableBuilder<List<CartItem>>(
          valueListenable: cartItemsNotifier,
          builder: (context, items, _) {
            final count = items.fold<int>(0, (sum, item) => sum + item.quantity);
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                IconButton(
                  tooltip: 'Shopping cart',
                  onPressed: onCartTap,
                  icon: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
                if (count > 0)
                  Positioned(
                    top: 6,
                    right: 3,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        constraints: const BoxConstraints(minWidth: 16),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        ValueListenableBuilder<List<OrderRecord>>(
          valueListenable: paidOrders,
          builder: (context, orders, _) {
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                IconButton(
                  tooltip: 'Order records',
                  onPressed: onOrdersTap,
                  icon: const Icon(
                    Icons.receipt_long_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                if (orders.isNotEmpty)
                  Positioned(
                    top: 6,
                    right: 4,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        constraints: const BoxConstraints(minWidth: 16),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${orders.length}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        IconButton(
          tooltip: hasCustomerInformation
              ? 'Edit client information'
              : 'Add client information',
          onPressed: onProfileTap,
          icon: Icon(
            hasCustomerInformation
                ? Icons.account_circle
                : Icons.account_circle_outlined,
            color: hasCustomerInformation ? accentColor : Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 4),
      ],
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            logoPath,
            height: 32,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.shopping_bag_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 8),
          const Flexible(
            child: Text(
              'A&Mstreetwear',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 19,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class ZoomProductCard extends StatefulWidget {
  final Product product;
  final int? stock;
  final VoidCallback onTap;

  const ZoomProductCard({
    Key? key,
    required this.product,
    this.stock,
    required this.onTap,
  }) : super(key: key);

  @override
  State<ZoomProductCard> createState() => _ZoomProductCardState();
}

class _ZoomProductCardState extends State<ZoomProductCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    final scale = _isPressed
        ? 0.98
        : _isHovered
            ? 1.015
            : 1.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 180),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? accentColor : Colors.white10,
              width: _isHovered ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? accentColor.withOpacity(0.12)
                    : Colors.black.withOpacity(0.25),
                blurRadius: _isHovered ? 16 : 8,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF292929),
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white54,
                              size: 45,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'STREETWEAR',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                        if (_isHovered)
                          Container(
                            color: Colors.black.withOpacity(0.12),
                            alignment: Alignment.center,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward,
                                color: Colors.black,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'PHP ${product.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: accentColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (widget.stock != null)
                              Text(
                                widget.stock! <= 0
                                    ? 'SOLD OUT'
                                    : 'Stock: ${widget.stock}',
                                style: TextStyle(
                                  color: widget.stock! <= 0
                                      ? Colors.redAccent
                                      : (widget.stock! <= 5
                                          ? Colors.orangeAccent
                                          : Colors.white54),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: _isHovered ? accentColor : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'VIEW PRODUCT',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}