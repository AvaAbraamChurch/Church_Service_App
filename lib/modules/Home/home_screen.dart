import 'package:church/core/blocs/home/home_cubit.dart';
import 'package:church/core/blocs/home/home_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/styles/colors.dart';

class HomeScreen extends StatelessWidget {
  final String userId; // Replace with actual user ID
  const HomeScreen({super.key, required this.userId});

  Widget _buildActivityButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15.0),
      // Set the height to make the buttons prominent like in the image
      height: 80,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          // Subtle shadow for depth
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start, // Align to the right for RTL
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // The icon on the far left (which is visually on the right in RTL)
            Icon(
              icon,
              color: Colors.white,
              size: 30,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) => HomeCubit(),
      child: BlocConsumer<HomeCubit, HomeState>(
        builder: (BuildContext context, state) {
          final cubit = HomeCubit.get(context);
          return StreamBuilder(
              stream: cubit.getUserById(userId).asStream(),
              builder: (context, snapshot) {
                return Scaffold(
                  endDrawer: ,
                  backgroundColor: Colors.transparent,
                  body: SizedBox(
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
                              Text('خدمة ابتدائي - بنين', style: TextStyle(color: brown300, fontSize: 20),),
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
                                Scaffold.of(context).openDrawer();
                             }, icon: Icon(Icons.menu, color: Colors.white,)),
                            ],
                          ),
                        ),
                        SizedBox(height: 10,),
                        ListTile(
                          title: Text('مرحبا بك...\n${cubit.currentUser!.fullName}', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),),
                          subtitle: Text('خادم أسرة القديس أبانوب', style: TextStyle(color: brown300, fontSize: 16),),
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
                                    // Search Bar (White background, light teal container)
                                    Container(
                                      height: 50,
                                      margin: const EdgeInsets.only(bottom: 25.0),
                                      padding: const EdgeInsets.symmetric(horizontal: 15),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Icon(Icons.search, color: Colors.grey),
                                          SizedBox(width: 10),
                                          // This is a placeholder, a TextField would go here
                                          Text(
                                            'بحث',
                                            style: TextStyle(color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Activity Buttons
                                    _buildActivityButton(
                                      title: 'درس الكتاب',
                                      subtitle: 'الخميس - الساعة ٦م',
                                      icon: Icons.book_outlined,
                                      color: brown300,
                                    ),
                                    _buildActivityButton(
                                      title: 'مدارس الأحد',
                                      subtitle: 'الجمعة - الساعة ١٠:٣٠ص',
                                      icon: Icons.school_outlined,
                                      color: red500,
                                    ),
                                    _buildActivityButton(
                                      title: 'القداس',
                                      subtitle: 'الجمعة - الساعة ٧:٣٠ص',
                                      icon: Icons.church_outlined,
                                      color: sage500,
                                    ),
                                    _buildActivityButton(
                                      title: 'مدرسة الشمامسة',
                                      subtitle: 'الخميس - الساعة ٧:٠٠م',
                                      icon: Icons.local_library_outlined, // Changed icon to a book/library icon to better match a school look
                                      color: tawny,
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
