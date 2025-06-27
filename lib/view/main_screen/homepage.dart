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
    builder: (context) => AlertDialog(
      title: Text('Confirm Logout'),
      content: Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('Logout'),
        ),
      ],
    ),
  );

  if (confirm == true) {
    await _secureStorage.deleteAll();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginScreen()), // Replace with your login page
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
  automaticallyImplyLeading: false,
  backgroundColor: Colors.transparent,
  elevation: 0,
  title: Row(
    children: [ 
      Image.asset("assets/calicutlogo.png",height: 50,width: 50,),
      const SizedBox(width: 100),
      Text(
        "Calicut Textiles",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
    ],
  ),
  actions: [
    IconButton(
      icon: Icon(Icons.logout, color: Colors.black),
      onPressed: logout,
      tooltip: 'Logout',
    ),
  ],
),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Section
             Row(
               children: [
                 Text(
                  'Hi, $fullName',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                             ),


               ],
             ),
             
            const SizedBox(height: 250),
            
            // Sales Summary Card
           
           
            
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildMenuItem(
                    icon: Icons.receipt_long,
                    title: 'Supplier Orders ',
                    onTap: () {
                      Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => PurchaseOrderPage()),
);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.business_center,
                    title: 'Suppliers',
                    onTap: () {
                      Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => SuppliersPage()),
);
                    },
                  ),
                  
                ],
              ),
            ),

          ],
        ),
      ),



     
    
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: Colors.black,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}