import 'package:church/core/styles/themeScaffold.dart';
import 'package:church/core/utils/gender_enum.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:circle_nav_bar/circle_nav_bar.dart';
import 'package:flutter/material.dart';
import '../core/styles/colors.dart';
import '../modules/Chat/conversations_list_screen.dart';
import '../modules/Home/home_screen.dart';
import '../modules/Notifications/notifications_screen.dart';
import '../modules/Profile/profile_screen.dart';
import '../modules/Attendance/attendance_screen.dart';
import 'package:church/core/repositories/messages_repository.dart';

class HomeLayout extends StatefulWidget {
  final String userId;
  final UserType userType;
  final String userClass;
  final Gender gender;
  const HomeLayout({super.key, required this.userId, required this.userType, required this.userClass, required this.gender});

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

  // We build icons dynamically in build() using the unread count stream.

  Widget _iconWithBadge(Widget icon, int unreadCount, {bool active = false}) {
    if (unreadCount <= 0) return icon;
    final badgeText = unreadCount > 99 ? '99+' : unreadCount.toString();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -8,
          top: -8,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(minWidth: 22, minHeight: 18),
                  child: Center(
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: _tabIndex);
  }

  @override
  Widget build(BuildContext context) {
    final MessagesRepository _messagesRepo = MessagesRepository();

    // Stream for unread messages count for this user
    final Stream<int> unreadStream = _messagesRepo.getUnreadMessageCount(widget.userId);

    // Icon builders that depend on current unread count
    List<Widget> buildActiveIcons(int unreadCount) => [
          _iconWithBadge(
            Center(
              child: Icon(
                Icons.chat_outlined,
                color: Colors.white,
                size: 28,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            unreadCount,
            active: true,
          ),
          const Icon(Icons.person_pin, color: Colors.white),
          const Icon(Icons.home, color: Colors.white),
          const Icon(Icons.list, color: Colors.white),
          const Icon(Icons.notifications, color: Colors.white),
        ];

    List<Widget> buildInactiveIcons(int unreadCount) => [
          _iconWithBadge(
            Center(
              child: Icon(
                Icons.chat_outlined,
                color: teal900,
                size: 26,
              ),
            ),
            unreadCount,
            active: false,
          ),
          const Icon(Icons.person_pin, color: teal900),
          const Icon(Icons.home, color: teal900),
          const Icon(Icons.list, color: teal900),
          const Icon(Icons.notifications, color: teal900),
        ];

    return ThemedScaffold(
      bottomNavigationBar: Directionality(
        textDirection: TextDirection.ltr,
        child: StreamBuilder<int>(
          stream: unreadStream,
          initialData: 0,
          builder: (context, snapshot) {
            final unread = snapshot.data ?? 0;
            return CircleNavBar(
              height: MediaQuery.of(context).size.height * 0.06,
              circleWidth: MediaQuery.of(context).size.height * 0.06,
              shadowColor: Colors.black54,
              circleColor: teal500,
              activeIndex: tabIndex,
              activeIcons: buildActiveIcons(unread),
              inactiveIcons: buildInactiveIcons(unread),
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
            );
          },
        ),
      ),
      body: PageView(
        controller: pageController,
        reverse: true,
        onPageChanged: (index) {
          tabIndex = index;
          },
        children: [
          ConversationsListScreen(),
          ProfileScreen(),
          HomeScreen(userId: widget.userId),
          AttendanceScreen(userId: widget.userId, userType: widget.userType, userClass: widget.userClass, gender: widget.gender,),
          NotificationsScreen(),


        ],
      ),
    );
  }
}
