import '../cart/widgets/cart_badge.dart';

import 'dart:async';

import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../auth/pages/account_page.dart';
import '../auth/data/auth_api.dart';
import '../booking/data/booking_api.dart';
import '../booking/pages/booking_page.dart';
import '../branches/data/branch_api.dart';
import '../branches/pages/branch_list_page.dart';
import '../branches/models/branch.dart';
import '../cart/pages/cart_page.dart';
import '../cart/data/cart_api.dart';
import '../home/home_page.dart';
import '../news/pages/news_list_page.dart';
import '../products/pages/product_list_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    this.authApi,
    this.cartApi,
    this.branchApi,
    this.bookingApi,
  });

  final AuthApi? authApi;
  final CartApi? cartApi;
  final BranchApi? branchApi;
  final BookingApi? bookingApi;

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
      inActiveItem: CartBadge(color: Color(0xFFFFD6D6)),
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
  Branch? _bookingBranch;
  int _bookingRevision = 0;
  bool _bookingTimelineVisible = false;
  bool _cartCheckoutVisible = false;
  int _accountRevision = 0;
  bool _exitArmed = false;
  Timer? _exitTimer;

  void _resetExitConfirmation() {
    _exitTimer?.cancel();
    _exitArmed = false;
  }

  void _confirmExit() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vuốt hoặc bấm quay lại lần nữa để thoát'),
        duration: Duration(seconds: 2),
      ),
    );
    setState(() => _exitArmed = true);
    _exitTimer?.cancel();
    _exitTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _exitArmed = false);
    });
  }

  void _onTabSelected(int index) {
    if (_navigationController.index != index) {
      _navigationController.jumpTo(index);
    }
    setState(() {
      _resetExitConfirmation();
      // Login can happen on a pushed page while this tab stays in IndexedStack.
      // Fetch the current session whenever the user returns to their account.
      if (index == 4 && _currentIndex != 4) _accountRevision++;
      _currentIndex = index;
    });
  }

  void _openBookingForBranch(Branch branch) {
    if (_navigationController.index != 2) {
      _navigationController.jumpTo(2);
    }
    setState(() {
      _bookingBranch = branch;
      _resetExitConfirmation();
      _bookingTimelineVisible = true;
      _bookingRevision++;
      _currentIndex = 2;
    });
  }

  void _onCartSelectionChanged(bool hasSelection) {
    if (_cartCheckoutVisible == hasSelection) return;
    setState(() {
      _resetExitConfirmation();
      _cartCheckoutVisible = hasSelection;
    });
  }

  @override
  void dispose() {
    _exitTimer?.cancel();
    _navigationController.dispose();
    super.dispose();
  }

  void _openNewsPage() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const NewsListPage()));
  }

  Future<void> _openBranchPage() async {
    final branch = await Navigator.of(context).push<Branch>(
      MaterialPageRoute<Branch>(
        builder: (_) => BranchListPage(
          branchApi: widget.branchApi,
          bookingApi: widget.bookingApi,
        ),
      ),
    );
    if (branch != null && mounted) {
      _openBookingForBranch(branch);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timelineVisible = _currentIndex == 2 && _bookingTimelineVisible;
    final cartCheckoutVisible = _currentIndex == 3 && _cartCheckoutVisible;
    final hideBottomNavigation = timelineVisible || cartCheckoutVisible;
    final pages = [
      HomePage(
        onBookCourtPressed: () => _onTabSelected(2),
        onViewProductsPressed: () => _onTabSelected(1),
        onViewNewsPressed: _openNewsPage,
        onViewBranchesPressed: _openBranchPage,
        onBookBranchPressed: _openBookingForBranch,
      ),
      ProductListPage(onCartPressed: () => _onTabSelected(3)),
      BookingPage(
        key: ValueKey('booking-${_bookingBranch?.id}-$_bookingRevision'),
        initialBranch: _bookingBranch,
        branchApi: widget.branchApi,
        bookingApi: widget.bookingApi,
        authApi: widget.authApi,
        onTimelineVisibilityChanged: (visible) {
          if (_bookingTimelineVisible != visible) {
            setState(() {
              _resetExitConfirmation();
              _bookingTimelineVisible = visible;
            });
          }
        },
      ),
      CartPage(
        cartApi: widget.cartApi,
        onSelectionChanged: _onCartSelectionChanged,
      ),
      AccountPage(
        key: ValueKey('account-$_accountRevision'),
        authApi: widget.authApi,
      ),
    ];

    return PopScope(
      canPop: _exitArmed && !timelineVisible,
      onPopInvokedWithResult: (didPop, result) {
        // The timeline handles Back by returning to the branch list.
        if (!didPop && !timelineVisible) _confirmExit();
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: pages),
        bottomNavigationBar: Offstage(
          offstage: hideBottomNavigation,
          child: SafeArea(
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
