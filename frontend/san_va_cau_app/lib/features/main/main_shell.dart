import 'package:flutter/material.dart';

import '../auth/pages/account_page.dart';
import '../booking/pages/booking_page.dart';
import '../branches/pages/branch_list_page.dart';
import '../cart/pages/cart_page.dart';
import '../home/home_page.dart';
import '../news/pages/news_list_page.dart';
import '../products/pages/product_list_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openNewsPage() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const NewsListPage()));
  }

  void _openBranchPage() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const BranchListPage()));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        onBookCourtPressed: () => _onTabSelected(2),
        onViewProductsPressed: () => _onTabSelected(1),
        onViewNewsPressed: _openNewsPage,
        onViewBranchesPressed: _openBranchPage,
      ),
      const ProductListPage(),
      const BookingPage(),
      const CartPage(),
      const AccountPage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag),
            label: 'Sản phẩm',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_tennis_outlined),
            selectedIcon: Icon(Icons.sports_tennis),
            label: 'Đặt sân',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Giỏ hàng',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}
