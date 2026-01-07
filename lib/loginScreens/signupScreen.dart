import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import './loginScreens.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final userName = TextEditingController();
  final passWord = TextEditingController();
  final passwordConfirm = TextEditingController();
  bool  isVisible = false;

  final formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const ListTile(
                    title: Text("Register new account"),
                    titleTextStyle: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.brown.withOpacity(.3)),
                    child: TextFormField(
                      controller: userName,
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
                      controller: passWord,
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

                  Container(
                    margin: const EdgeInsets.all(8),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.brown.withOpacity(.3)),
                    child: TextFormField(
                      controller: passwordConfirm,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Password confirmation is required";
                          }else if(passWord.text!= passwordConfirm.text){
                            return "Password and confirmation don't match";
                          }
                          return null;
                        },
                        obscureText: !isVisible,
                        decoration: InputDecoration(
                            icon: const Icon(Icons.lock),
                            border: InputBorder.none,
                            hintText: 'Confirm Password',
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
                  const SizedBox(height: 10,),
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
                              DatabaseHelper().insertUser(userName.text, passWord.text).then((value){
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account created successfully")));
                                Navigator.push(context, MaterialPageRoute(builder: (context)=> const LoginScreen()));
                              });
                            }
                          },
                          child: const Text(
                            "SIGNUP",
                            style: TextStyle(color: Colors.white),
                          ))),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?"),
                      TextButton(onPressed: () {
                        //Navigate to signup
                        Navigator.push(context, MaterialPageRoute(builder: (context)=> const LoginScreen()));
                      }, child: const Text("LOGIN"))
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
