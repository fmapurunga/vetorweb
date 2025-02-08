// lib/app/screens/app_bar_screen.dart
import 'package:flutter/material.dart';
import 'whatsapp_screen.dart';
import 'profile_screen.dart';

class AppBarScreen extends StatefulWidget {
  const AppBarScreen({super.key});

  @override
  AppBarScreenState createState() => AppBarScreenState();
}

class AppBarScreenState extends State<AppBarScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const WhatsAppScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'WhatsApp',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}