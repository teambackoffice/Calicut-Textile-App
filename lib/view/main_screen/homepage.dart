import 'package:calicut_textile_app/view/login_screen/login_page.dart';
import 'package:calicut_textile_app/view/main_screen/purchase_order/purchase_order_page.dart';
import 'package:calicut_textile_app/view/main_screen/supplier/supplier_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  String fullName = '';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    loadFullName();
  }

  void loadFullName() async {
    final name = await _secureStorage.read(key: 'full_name');
    setState(() {
      fullName = name ?? '';
    });
  }

  void logout() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) =>  AlertDialog(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
  title: Row(
    children: [
      Icon(
        Icons.logout,
        color: Colors.blue[900],
        size: 24,
      ),
      SizedBox(width: 12),
      Text(
        'Confirm Logout',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    ],
  ),
  content: Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Text(
      'Are you sure you want to logout? ',
      style: TextStyle(
        fontSize: 16,
        color: Colors.black,
        height: 1.4,
      ),
    ),
  ),
  actionsPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
  actions: [
    TextButton(
      onPressed: () => Navigator.of(context).pop(false),
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        'Cancel',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.grey[600],
        ),
      ),
    ),
    SizedBox(width: 8),
    ElevatedButton(
      onPressed: () => Navigator.of(context).pop(true),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
      ),
      child: Text(
        'Logout',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  ],
)
    );

    if (confirm == true) {
      await _secureStorage.deleteAll();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.1),
        title: Row(
          children: [
            Container(
              
              child: Image.asset("assets/calicutlogo.png", height: 45, width: 45),
            ),
            const SizedBox(width: 12),
            Text(
              "Calicut Textiles",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            
            child: IconButton(
              icon: Icon(Icons.logout, color: Colors.blue[900]),
              onPressed: logout,
              tooltip: 'Logout',
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Greeting Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[700]!, Colors.blue[900]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
  fullName.isNotEmpty
      ? '${fullName[0].toUpperCase()}${fullName.substring(1)}'
      : 'Welcome!',
  style: TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  ),
),

                  SizedBox(height: 12),
                  Text(
                    'Manage your textile business efficiently',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Quick Stats Section
           

            

            // Section Title
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 16),

            // Enhanced Menu Items
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildEnhancedMenuItem(
                  icon: Icons.receipt_long,
                  title: 'Supplier Orders',
                  subtitle: 'Manage supplier orders',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PurchaseOrderPage()),
                    );
                  },
                ),
                _buildEnhancedMenuItem(
                  icon: Icons.business_center,
                  title: 'Suppliers',
                  subtitle: 'View all suppliers',
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SuppliersPage()),
                    );
                  },
                ),
                
              ],
            ),

            const SizedBox(height: 32),

            // Recent Activity Section
            

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  
  Widget _buildEnhancedMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

}