import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import './signupScreen.dart';
import '../home/homeScreens.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final username = TextEditingController();
  final password = TextEditingController();
  bool isVisible = false;
  //Form global key
  final formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  Image.asset('assets/images/fedco.png', width: 80, height: 60),
                  //Username
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.brown.withOpacity(.3)),
                    child: TextFormField(
                      controller: username,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Username is required";
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          icon: Icon(Icons.person),
                          border: InputBorder.none,
                          hintText: 'Username',
                        )),
                  ),
                  //Login
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.brown.withOpacity(.3)),
                    child: TextFormField(
                      controller: password,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Password is required";
                          }
                          return null;
                        },
                        obscureText: !isVisible,
                        decoration: InputDecoration(
                            icon: const Icon(Icons.lock),
                            border: InputBorder.none,
                            hintText: 'Password',
                            suffixIcon: IconButton(
                                onPressed: () {
                                  //Password visibility
                                  setState(() {
                                    isVisible = !isVisible;
                                  });
                                },
                                icon: Icon(isVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off)))),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  //Button
                  Container(
                      height: 50,
                      width: MediaQuery.of(context).size.width * .9,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.brown),
                      child: TextButton(
                          onPressed: () {
                            if(formKey.currentState!.validate()){
                              //Login method
                              DatabaseHelper().checkUser(username.text, password.text).then((isLogin){
                                if(isLogin){
                                  Navigator.push(context, MaterialPageRoute(builder: (context)=> const HomeScreen()));
                                }else{
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Login Failed. Invalid username or password.")));
                                }
                              });
                            }
                          },
                          child: const Text(
                            "LOGIN",
                            style: TextStyle(color: Colors.white),
                          ))),
                  //Signup
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(onPressed: () {
                        //Navigate to signup
                        Navigator.push(context, MaterialPageRoute(builder: (context)=> const Signup()));
                      }, child: const Text("SIGN UP"))
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
