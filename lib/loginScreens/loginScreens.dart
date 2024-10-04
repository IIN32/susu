import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  bool showPassword = false;
  //Get user input
  dynamic userName='';
  dynamic passWord='';
  dynamic defaultuserName="Ibrahim";
  dynamic defaultpassWord="Susu@22";
  @override
  Widget build(BuildContext context) {
    return Form(key: formKey, child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(30),
          child: Image.asset('assets/images/fedco.png',width: 80, height: 60,),
        ),
        const Text(
          'susu',
        ),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.person_2_rounded,color: Colors.brown),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value!.isEmpty) {
              return 'Please enter your username';
            }
            return null;
          },
          onChanged: (value) => userName = value,
        ),
        TextFormField(
          obscureText: showPassword,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.person_2_rounded,color: Colors.brown),
            suffixIcon: IconButton(
                onPressed: (){
              setState(() {
                showPassword=!showPassword;
              });
            },
                icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),),
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value!.isEmpty && value.length<8) {
              return 'Please enter a password greater or equal to 8 characters.';
            }
            return null;
          },
          onSaved: (value) => userName = value,
        ),
        ElevatedButton(onPressed: (){
          if(formKey.currentState!.validate()){
            formKey.currentState!.save();
            //Calling the login
            if (kDebugMode) {
              print('Email: $userName, Password: $passWord');
            }
          }
        },
            child: const Text('Login'),
        ),
      ],),);
  }
}
