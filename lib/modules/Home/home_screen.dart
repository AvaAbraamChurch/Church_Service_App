import 'package:church/core/blocs/home/home_cubit.dart';
import 'package:church/core/blocs/home/home_states.dart';
import 'package:church/core/models/user/user_model.dart';
import 'package:church/core/utils/service_enum.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/repositories/auth_repository.dart';
import '../../core/styles/colors.dart';
import '../../core/utils/session_checker.dart';
import 'endrawer.dart';

class HomeScreen extends StatefulWidget {
  final String userId; // Replace with actual user ID
  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Widget _buildActivityButton({
    required String title,
    required String subtitle,
    IconData? icon,
    String? svgAsset,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            color,
            color.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 100,
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              subtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Icon with decorative background - supports both regular icons and SVG
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(14),
                  child: svgAsset != null
                      ? SvgPicture.asset(
                          svgAsset,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                          fit: BoxFit.contain,
                        )
                      : Icon(
                          icon ?? Icons.star,
                          color: Colors.white,
                          size: 32,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  final AuthRepository _authRepository = AuthRepository();
  late SessionChecker _sessionChecker;


  late final HomeCubit cubit;
  late final UserModel currentUser;
  late final Stream userStream;


  /// Called when app resumes from background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check session when user returns to app
      _checkSession();
    }
  }

  /// Check if session is valid
  Future<void> _checkSession() async {
    final isValid = await _sessionChecker.checkAndHandleSession(context);
    if (!isValid) {
      // Session expired, user will be redirected to login
      return;
    }

    // Optional: Show warning if session expiring within 24 hours
    _sessionChecker.checkAndWarnIfExpiringSoon(
      context,
      warningThreshold: const Duration(hours: 24),
    );
  }

  @override
  void initState() {
    super.initState();

    _sessionChecker = SessionChecker(_authRepository);
    WidgetsBinding.instance.addObserver(this);

    // Check session on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSession();
    });
    cubit = HomeCubit();
    // currentUser = cubit.currentUser!;
    userStream = cubit.getUserById(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: BlocConsumer<HomeCubit, HomeState>(
        builder: (BuildContext context, state) {
          final cubit = HomeCubit.get(context);
          return StreamBuilder(
              stream: userStream,
              builder: (context, snapshot) {
                return Scaffold(
                  endDrawer: cubit.currentUser != null ? drawer(context, cubit.currentUser!) : null,
                  backgroundColor: Colors.transparent,
                  body: ConditionalBuilder(
                      condition: cubit.currentUser != null,
                      builder: (BuildContext context) {
                        return SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: MediaQuery.of(context).padding.top,),
                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Row(
                                  children: [
                                    Text(cubit.currentUser!.serviceType.displayName, style: TextStyle(color: brown300, fontSize: 20),),
                                    Spacer(),
                                    Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: brown300, width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.2),
                                              spreadRadius: 2,
                                              blurRadius: 5,
                                              offset: Offset(0, 3), // changes position of shadow
                                            ),
                                          ],
                                          image: const DecorationImage(
                                            image: AssetImage('assets/images/man.png'), // Replace with actual asset path
                                            fit: BoxFit.cover,
                                          ),
                                        )),
                                    SizedBox(width: 10.0,),
                                    IconButton(onPressed: (){
                                      Scaffold.of(context).openEndDrawer();
                                    }, icon: Icon(Icons.menu, color: Colors.white,)),
                                  ],
                                ),
                              ),
                              SizedBox(height: 10,),
                              ListTile(
                                title: Text('مرحبا بك...\n${cubit.currentUser!.username}', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),),
                                subtitle: Text('${cubit.currentUser!.userType.label}: ${cubit.currentUser!.userClass}', style: TextStyle(color: brown300, fontSize: 16),),
                              ),
                              SizedBox(height: 20,),
                              Expanded(
                                child: Container(
                                  height: MediaQuery.of(context).size.height,
                                  width: MediaQuery.of(context).size.width,
                                  decoration: const BoxDecoration(
                                    color: teal300, // The main color of the button/search area
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          SizedBox(height: 30.0,),
                                          // Activity Buttons
                                          _buildActivityButton(
                                            title: 'درس الكتاب',
                                            subtitle: 'الخميس - الساعة ٦م',
                                            svgAsset: 'assets/svg/book.svg',
                                            color: brown300,
                                            onTap: (){
                                              debugPrint('درس الكتاب');
                                            },
                                          ),
                                          _buildActivityButton(
                                            title: 'مدارس الأحد',
                                            subtitle: 'الجمعة - الساعة ١٠:٣٠ص',
                                            svgAsset: 'assets/svg/sunday school.svg',
                                            color: sage900,
                                            onTap: (){
                                              debugPrint('مدارس الأحد');
                                            },
                                          ),
                                          _buildActivityButton(
                                            title: 'القداس',
                                            subtitle: 'الجمعة - الساعة ٧:٣٠ص',
                                            svgAsset: 'assets/svg/church.svg',
                                            color: sage500,
                                            onTap: (){
                                              debugPrint('القداس');
                                            },
                                          ),
                                          _buildActivityButton(
                                            title: 'مدرسة الشمامسة',
                                            subtitle: 'الخميس - الساعة ٧:٠٠م',
                                            svgAsset: 'assets/svg/4mamsa.svg', // Replace with your SVG asset path
                                            color: tawny,
                                            onTap: (){
                                              debugPrint('مدرسة الشمامسة');
                                            },
                                          ),
                                          // Add some padding at the bottom for scroll
                                          const SizedBox(height: 20),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )

                            ],
                          ),
                        );
                      },
                    fallback: (BuildContext context) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: teal100,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: teal300.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 50,
                                height: 50,
                                child: CircularProgressIndicator(
                                  color: teal500,
                                  strokeWidth: 4,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'جاري التحميل...',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: teal900,
                              fontFamily: 'Alexandria',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'يرجى الانتظار',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontFamily: 'Alexandria',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
          );
        },
        listener: (BuildContext context, state) {  },
      ),
    );
  }
}
