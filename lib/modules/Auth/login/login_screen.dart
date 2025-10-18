import 'package:church/core/blocs/auth/auth_cubit.dart';
import 'package:church/core/blocs/auth/auth_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/strings.dart';
import '../../../core/styles/colors.dart';
import '../../../core/styles/themeScaffold.dart';
import '../../../layout/home_layout.dart';
import '../../../shared/widgets.dart';
import '../register/register_screen.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) => AuthCubit(),
      child: BlocConsumer<AuthCubit, AuthState>(
        builder: (BuildContext context, state) {
          final cubit = AuthCubit.get(context);

          return ThemedScaffold(
            body: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                    Text(
                      welcomeMessage,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                    ),
                    SizedBox(height: 30.0),
                    Text(
                      login,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.15),

                    coloredTextField(
                      enabledBorder: InputBorder.none,
                      prefixIcon: Icons.person,
                      fillColor: brown300,
                      controller: emailController,
                      label: email,
                    ),
                    SizedBox(height: 20.0),
                    coloredTextField(
                      isPassword: true,
                      enabledBorder: InputBorder.none,
                      prefixIcon: Icons.lock,
                      fillColor: red500,
                      controller: passwordController,
                      label: password,
                    ),
                    SizedBox(height: 40.0),

                    ElevatedButton(
                      onPressed: () {
                        cubit.logIn(
                          emailController.text,
                          passwordController.text,
                        );
                      },
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
                          fontFamily: 'Alexandria',
                        ),
                      ),
                      child: Text(login),
                    ),

                    SizedBox(height: 20.0),

                    Center(
                      child: InkWell(
                        onTap: () {},
                        child: Text(
                          forgotPassword,
                          style: TextStyle(color: Colors.white, fontSize: 16.0),
                        ),
                      ),
                    ),

                    SizedBox(height: 20.0),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          registerPrompt,
                          style: TextStyle(color: Colors.white, fontSize: 16.0),
                        ),
                        TextButton(
                          onPressed: () {
                            navigateTo(context, RegisterScreen());
                          },
                          child: Text(
                            registerNow,
                            style: TextStyle(
                              color: teal100,
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        listener: (BuildContext context, state) {
          if (state is AuthLoading) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: teal100,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: teal300.withValues(alpha: 0.3),
                              blurRadius: 15,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              color: teal500,
                              strokeWidth: 3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'جاري تسجيل الدخول...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: teal900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else if (state is AuthSuccess) {
            // Close the loading dialog
            Navigator.of(context, rootNavigator: true).pop();
            navigateAndFinish(context, HomeLayout(userId: state.uId, userType: state.userType, userClass: state.userClass, gender: state.gender,));
          } else if (state is AuthFailure) {
            // Close the loading dialog
            final messenger = ScaffoldMessenger.maybeOf(context);
            messenger?.showSnackBar(SnackBar(content: Text(state.error)));
            Navigator.of(context, rootNavigator: true).pop();
          }
        },
      ),
    );
  }
}
