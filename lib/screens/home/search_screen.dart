import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allSubServices = [];
  List<dynamic> _filteredSubServices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllSubServices();
  }

  Future<void> _fetchAllSubServices() async {
    // Passing 'all' returns all subservices from the backend
    final data = await ApiService.getSubServicesByCategory('all');
    if (mounted) {
      setState(() {
        _allSubServices = data;
        _filteredSubServices = data;
        _isLoading = false;
      });
    }
  }

  void _filterResults(String query) {
    if (query.isEmpty) {
      setState(() => _filteredSubServices = _allSubServices);
      return;
    }
    
    setState(() {
      _filteredSubServices = _allSubServices.where((ss) {
        final name = (ss['subservice_name'] ?? '').toString().toLowerCase();
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _filterResults,
          decoration: InputDecoration(
            hintText: 'Search for services...',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                _searchController.clear();
                _filterResults('');
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B1464)))
          : _filteredSubServices.isEmpty
              ? _buildEmptyState()
              : _buildResultsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No services found',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredSubServices.length,
      itemBuilder: (context, index) {
        final ss = _filteredSubServices[index];
        final title = ss['subservice_name'] ?? 'Unknown';
        final rating = (ss['avg_rating'] ?? 4.8).toString();
        final time = ss['duration']?.toString() ?? '45';
        final price = '₹${ss['base_price'] ?? 199}';
        final imagePath = ss['image'] != null && ss['image'].toString().isNotEmpty 
            ? ss['image'] 
            : 'assets/images/switch.png';

        return _buildServiceCard(title, rating, time, price, imagePath);
      },
    );
  }

  Widget _buildServiceCard(String title, String rating, String time, String price, String imagePath) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imagePath.startsWith('http')
                ? Image.network(
                    imagePath,
                    height: 90,
                    width: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 90,
                      width: 90,
                      color: Colors.grey.shade100,
                      child: Icon(Icons.image, color: Colors.grey.shade400),
                    ),
                  )
                : Image.asset(
                    imagePath,
                    height: 90,
                    width: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 90,
                      width: 90,
                      color: Colors.grey.shade100,
                      child: Icon(Icons.image, color: Colors.grey.shade400),
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, right: 12, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            rating,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.bolt, color: Colors.green, size: 16),
                      const SizedBox(width: 2),
                      Text(
                        '$time mins',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B1464),
                        ),
                      ),
                      SizedBox(
                        height: 32,
                        child: OutlinedButton(
                          onPressed: () {
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(content: Text('$title added to cart')),
                             );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Add',
                            style: TextStyle(
                              color: Color(0xFF1B1464),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
