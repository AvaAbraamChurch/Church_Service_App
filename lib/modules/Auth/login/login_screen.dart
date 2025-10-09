import 'package:flutter/material.dart';

import '../../../core/constants/strings.dart';
import '../../../core/styles/colors.dart';
import '../../../core/styles/themeScaffold.dart';
import '../../../shared/widgets.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            Text(welcomeMessage, style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white
            )),
            SizedBox(height: 30.0),
            Text(login, style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white
            )),
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),


            coloredTextField(
              enabledBorder: InputBorder.none,
                prefixIcon: Icons.person,
              fillColor: brown300,
                controller: TextEditingController(),
                label: username
            ),
            SizedBox(height: 20.0),
            coloredTextField(
              enabledBorder: InputBorder.none,
              prefixIcon: Icons.lock,
              fillColor: red500,
                controller: TextEditingController(),
                label: password
            ),
            SizedBox(height: 40.0),

            ElevatedButton(
              onPressed: (){},
              style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
              backgroundColor: teal100,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              textStyle: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ), child: Text(login),),


          ],
        ),
      ),
    );
  }
}
