import 'package:flutter/material.dart';

import '../../core/styles/colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: null,
        builder: (context, snapshot) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: MediaQuery.of(context).padding.top,),
                        Text('خدمة ابتدائي - بنين', style: TextStyle(color: brown300),),
                        SizedBox(height: 10,),
                        Text('مرحبا بك\n في تطبيق خدماتي', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),),
                        SizedBox(height: 20,),
                      ],
                    ),
                  ),
                )
            ),
          );
        }
    );
  }
}
