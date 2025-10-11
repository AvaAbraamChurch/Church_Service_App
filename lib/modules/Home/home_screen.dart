import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: null,
        builder: (context, snapshot) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: Text('Home Screen'),
            ),
          );
        }
    );
  }
}
