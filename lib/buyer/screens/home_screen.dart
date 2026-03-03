import 'package:flutter/material.dart';
import '../widgets/buyers_menu.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    // These values could eventually come from your Login logic
    const String currentUserName = "Emmanuel Igwe";
    const String currentUserEmail = "mikefavour07@gmail.com";

    return Scaffold(
      // Mobile Drawer - PASSING REQUIRED ARGUMENTS HERE
      drawer: isDesktop
          ? null
          : Drawer(
              child: BuyersMenu(
                userName: currentUserName,
                userEmail: currentUserEmail,
              ),
            ),

      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              title: const Text(
                "Store Hub",
                style: TextStyle(color: Colors.black),
              ),
            ),

      body: Row(
        children: [
          // Sidebar for Desktop - PASSING REQUIRED ARGUMENTS HERE
          if (isDesktop)
            BuyersMenu(
              isDesktop: true,
              userName: currentUserName,
              userEmail: currentUserEmail,
            ),

          // Main Content Area
          const Expanded(
            child: Center(
              child: Text(
                "Welcome to the Dashboard",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
