import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../auth/pages/account_page.dart';
import '../booking/pages/booking_page.dart';
import '../branches/pages/branch_list_page.dart';
import '../cart/pages/cart_page.dart';
import '../home/home_page.dart';
import '../news/pages/news_list_page.dart';
import '../products/pages/product_list_page.dart';
import '../racket_services/pages/racket_service_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _barColor = AppColors.primaryDark;

  static const _navigationItems = <BottomBarItem>[
    BottomBarItem(
      inActiveItem: Icon(Icons.home_outlined, color: Color(0xFFFFD6D6)),
      activeItem: _ActiveNavigationItem(
        icon: Icons.home_rounded,
        label: 'Trang chủ',
      ),
      itemLabel: 'Trang chủ',
    ),
    BottomBarItem(
      inActiveItem: Icon(Icons.shopping_bag_outlined, color: Color(0xFFFFD6D6)),
      activeItem: _ActiveNavigationItem(
        icon: Icons.shopping_bag_rounded,
        label: 'Sản phẩm',
      ),
      itemLabel: 'Sản phẩm',
    ),
    BottomBarItem(
      inActiveItem: Icon(
        Icons.sports_tennis_outlined,
        color: Color(0xFFFFD6D6),
      ),
      activeItem: _ActiveNavigationItem(
        icon: Icons.sports_tennis_rounded,
        label: 'Đặt sân',
      ),
      itemLabel: 'Đặt sân',
    ),
    BottomBarItem(
      inActiveItem: Icon(
        Icons.shopping_cart_outlined,
        color: Color(0xFFFFD6D6),
      ),
      activeItem: _ActiveNavigationItem(
        icon: Icons.shopping_cart_rounded,
        label: 'Giỏ hàng',
      ),
      itemLabel: 'Giỏ hàng',
    ),
    BottomBarItem(
      inActiveItem: Icon(
        Icons.person_outline_rounded,
        color: Color(0xFFFFD6D6),
      ),
      activeItem: _ActiveNavigationItem(
        icon: Icons.person_rounded,
        label: 'Tài khoản',
      ),
      itemLabel: 'Tài khoản',
    ),
  ];

  final NotchBottomBarController _navigationController =
      NotchBottomBarController();
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    if (_navigationController.index != index) {
      _navigationController.jumpTo(index);
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void dispose() {
    _navigationController.dispose();
    super.dispose();
  }

  void _openNewsPage() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const NewsListPage()));
  }

  void _openBranchPage() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const BranchListPage()));
  }

  void _openRacketServicePage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const RacketServicePage()));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        onBookCourtPressed: () => _onTabSelected(2),
        onViewProductsPressed: () => _onTabSelected(1),
        onViewNewsPressed: _openNewsPage,
        onViewBranchesPressed: _openBranchPage,
        onRacketServicePressed: _openRacketServicePage,
      ),
      const ProductListPage(),
      const BookingPage(),
      const CartPage(),
      const AccountPage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 2),
        child: AnimatedNotchBottomBar(
          notchBottomBarController: _navigationController,
          bottomBarItems: _navigationItems,
          onTap: _onTabSelected,
          color: _barColor,
          notchColor: AppColors.surface,
          showLabel: true,
          itemLabelStyle: const TextStyle(
            color: Color(0xFFFFE4E4),
            fontFamily: 'PlusJakartaSans',
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
          textOverflow: TextOverflow.visible,
          maxLine: 1,
          kIconSize: 25,
          kBottomRadius: 24,
          bottomBarHeight: 66,
          bottomBarWidth: 500,
          durationInMilliSeconds: 350,
          topMargin: 7,
          circleMargin: 7,
          elevation: 2,
          shadowElevation: 12,
          showShadow: true,
          removeMargins: false,
        ),
      ),
    );
  }
}

class _ActiveNavigationItem extends StatelessWidget {
  const _ActiveNavigationItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      selected: true,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Icon(icon, color: AppColors.primary, size: 25),
          Positioned(
            top: 49,
            child: SizedBox(
              width: 70,
              child: Text(
                label,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.visible,
                style: const TextStyle(
                  color: AppColors.onPrimary,
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
