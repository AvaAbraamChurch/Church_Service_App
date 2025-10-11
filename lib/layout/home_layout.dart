import 'package:church/core/styles/themeScaffold.dart';
import 'package:circle_nav_bar/circle_nav_bar.dart';
import 'package:flutter/material.dart';
import '../core/styles/colors.dart';
import '../modules/Home/home_screen.dart';

class HomeLayout extends StatefulWidget {
  const HomeLayout({super.key});

  @override
  State<HomeLayout> createState() => _HomeLayoutState();
}

class _HomeLayoutState extends State<HomeLayout>
    with SingleTickerProviderStateMixin {
  int _tabIndex = 2;

  int get tabIndex => _tabIndex;

  set tabIndex(int v) {
    _tabIndex = v;
    setState(() {});
  }

  late PageController pageController;

  // Messages ---> 0
  // Profile ---> 1
  // Home ---> 2
  // Events ---> 3
  // Notifications ---> 4

  activeIcons() {
    return [
      const Icon(Icons.message, color: Colors.white),
      const Icon(Icons.person_pin, color: Colors.white),
      const Icon(Icons.home, color: Colors.white),
      const Icon(Icons.list, color: Colors.white),
      const Icon(Icons.notifications, color: Colors.white),
    ];
  }

  inActiveIcons() {
    return [
      const Icon(Icons.message, color: teal900),
      const Icon(Icons.person_pin, color: teal900),
      const Icon(Icons.home, color: teal900),
      const Icon(Icons.list, color: teal900),
      const Icon(Icons.notifications, color: teal900),
    ];
  }

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: _tabIndex);
  }

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      bottomNavigationBar: Directionality(
        textDirection: TextDirection.ltr,
        child: CircleNavBar(
          height: MediaQuery.of(context).size.height * 0.08,
          circleWidth: MediaQuery.of(context).size.height * 0.08,
          shadowColor: Colors.black54,
          circleColor: teal500,
          activeIndex: tabIndex,
          activeIcons: activeIcons(),
          inactiveIcons: inActiveIcons(),
          onTap: (index) {
            tabIndex = index;
            pageController.jumpToPage(tabIndex);
          },
          color: teal100,
          cornerRadius: const BorderRadius.only(
            topLeft: Radius.circular(60),
            topRight: Radius.circular(60),
          ),
          elevation: 10,
        ),
      ),
      body: PageView(
        controller: pageController,
        onPageChanged: (index) {
          tabIndex = index;
          print(tabIndex);
        },
        children: [
          const Center(child: Text('Messages Page')),
          const Center(child: Text('Profile Page')),
          HomeScreen(),
          const Center(child: Text('Events Page')),
          const Center(child: Text('Notifications Page')),
        ],
      ),
    );
  }
}
