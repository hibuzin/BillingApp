import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final List<String> _tabs = ['Today', 'Week', 'Month', 'Year'];
  int _selectedIndex = 0;
  bool _loading = false;
  String? _error;

  Map<String, dynamic>? _data;

  final List<String> _endpoints = [
    'https://billing-system-y42h.onrender.com/api/retail/bill/sales/today',
    'https://billing-system-y42h.onrender.com/api/retail/bill/sales/week',
    'https://billing-system-y42h.onrender.com/api/retail/bill/sales/month',
    'https://billing-system-y42h.onrender.com/api/retail/bill/sales/year',
  ];

  @override
  void initState() {
    super.initState();
    _fetchData(0);
  }

  Future<void> _fetchData(int index) async {
    setState(() {
      _loading = true;
      _error = null;
      _data = null;
    });

    try {
      final response = await http.get(Uri.parse(_endpoints[index]));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          _data = json['data'];
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load data';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error';
        _loading = false;
      });
    }
  }


  String _formatDate(String raw) {
    try {
      final parts = raw.split(', ');
      final dateParts = parts[0].split('/');
      final day = dateParts[0].padLeft(2, '0');
      final month = dateParts[1].padLeft(2, '0');
      final year = dateParts[2];
      return '$day/$month/$year';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F5),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Sales'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildTabBar(),
          const SizedBox(height: 24),
          Expanded(
            child: _loading
                ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Colors.black45,
              ),
            )
                : _error != null
                ? Center(
              child: Text(
                _error!,
                style: const TextStyle(
                  color: Colors.black38,
                  fontSize: 14,
                ),
              ),
            )
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: List.generate(_tabs.length, (i) {
            final selected = i == _selectedIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedIndex = i);
                  _fetchData(i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? Colors.black : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _tabs[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                      selected ? Colors.white : Colors.black54,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_data == null) return const SizedBox();

    final totalSales = _data!['totalSales'] ?? 0;
    final totalBills = _data!['totalBills'];
    final from = _data!['from'];
    final to = _data!['to'];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        _buildMainCard(totalSales, from, to),
        if (totalBills != null) ...[
          const SizedBox(height: 12),
          _buildBillsCard(totalBills),
        ],
        if (from != null && to != null) ...[
          const SizedBox(height: 12),
          _buildDateRangeCard(from, to),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildMainCard(num totalSales, String? from, String? to) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF000000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL SALES',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white70,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '₹${totalSales.toString()}',
            style: const TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillsCard(int totalBills) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL BILLS',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black38,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$totalBills',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeCard(String from, String to) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _dateBlock("FROM", from),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.black.withOpacity(0.08),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: _dateBlock("TO", to),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateBlock(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black38,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatDate(value),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}