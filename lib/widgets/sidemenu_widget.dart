import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class SideMenu extends StatelessWidget {
  final String? userEmail;
  
  const SideMenu({super.key, this.userEmail});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children:[ 
            // User Profile Section
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
              color: Color(0xFFDEF3E0),
              borderRadius: BorderRadius.all(Radius.circular(12),),
              ),
              child: Row(
              children: [
                
                Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                  color: const Color(0xFF399942),
                  width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                  'assets/images/leaf-avatar.png', 
                  fit: BoxFit.cover,
                  width: 52,
                  height: 52,
                  ),
                ),
                ),
                const SizedBox(width: 16),

                
                // User Info
                Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  const Text(
                    'Plant Lover',
                    style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF399942),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail ?? 'user@email.com',
                    style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    ),
                  ),
                  ],
                ),
                ),
              ],
              ),
            ),
            
            
             // Divider
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Divider(
                color: Color(0xFFE0E0E0),
                thickness: 1,
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Menu Items
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // My Plants
                    _buildMenuItem(
                      context,
                      icon: Icons.spa,
                      title: 'My Plants',
                      route: '/home',
                      isSelected: true, 
                    ),
                    
                    // Diagnose Plant
                    _buildMenuItem(
                      context,
                      icon: Icons.health_and_safety,
                      title: 'Diagnose Plant',
                      route: '/leaf_diagnosis',
                    ),
                    
                    // Reminders
                    _buildMenuItem(
                      context,
                      icon: Icons.notifications,
                      title: 'Reminders',
                      route: '/reminders',
                    ),

                    _buildMenuItem(
                      context,
                      icon: Icons.book,
                      title: 'Diary',
                      route: '/plant_diary',
                    ),
                    
                    // Divider
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(
                        color: Color(0xFFE0E0E0),
                        thickness: 1,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Logout
                    _buildMenuItem(
                      context,
                      icon: Icons.logout,
                      title: 'Logout',
                      route: '/logout',
                      isLogout: true,
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    bool isSelected = false,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleMenuSelection(context, route, isLogout),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected 
                ? const Color(0xFFDEF3E0) 
                : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isLogout 
                    ? Colors.red 
                    : isSelected 
                      ? const Color(0xFF399942)
                      : Colors.grey[600],
                  size: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isLogout 
                        ? Colors.red 
                        : isSelected 
                          ? const Color(0xFF399942)
                          : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleMenuSelection(BuildContext context, String route, bool isLogout) {
    Navigator.pop(context); // Close drawer
    
    if (isLogout) {
      
      _showLogoutDialog(context);
    } else {
      Navigator.pushNamed(context, route);
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                
                Navigator.pushNamedAndRemoveUntil(
                  context, 
                  '/login', 
                  (route) => false,
                );
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}



