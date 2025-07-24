import 'package:flutter/material.dart';
import '../main.dart';
import '../routes.dart';
// import 'package:animations/animations.dart';

// import 'package:flutter/material.dart';
 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _phoneFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _emailFormKey = GlobalKey<FormState>();
  // final _loginFormKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _email;
  String? _password;
  bool isPhoneSelected = true;
  bool _wasPhoneSelected = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
          child: Container(
            margin: EdgeInsets.all(20),
            child: Column(
              // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Hero(
                  tag: "logo",
                    child: Image.asset("images/logonew.png", scale: 18),
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Watch',
                        style: TextStyle(
                            color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: 'Team',
                        style: TextStyle(color: Colors.blue, fontSize: 30,fontWeight: FontWeight.w700 ),
                      ),
                    ],
                  ),
                ),

                Text("Asset Protection Suite", style: TextStyle(fontWeight: FontWeight.bold, ),),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 30),
                  height: 60,
                  decoration: BoxDecoration(color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey)),
                  child: Row(

                    children: [
                      Expanded(child: GestureDetector(
                        onTap: (){
                          setState(() {
                            // _wasPhoneSelected = isPhoneSelected;
                            isPhoneSelected = true;
                          });
                          },
                        child: Container(
                          // color: Colors.black,
                          decoration: BoxDecoration(color: isPhoneSelected?Colors.black:Colors.transparent,
                          borderRadius: BorderRadius.circular(10)),
                          alignment: Alignment.center,
                          child: Text("Phone",
                          style: TextStyle(
                            color: isPhoneSelected? Colors.blue:Colors.grey,
                            fontWeight: FontWeight.bold,

                          ),),
                        ),
                      )),
                      Container(
                        width: 1, // Thickness of the line
                        height: 60, // Height of the line
                        color: Colors.grey,
                      ),
                      Expanded(child: GestureDetector(
                        onTap: (){
                          setState(() {
                            // _wasPhoneSelected = isPhoneSelected;
                            isPhoneSelected = false;
                          });
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: isPhoneSelected?Colors.transparent:Colors.black,
                              borderRadius: BorderRadius.circular(10)),
                          child: Text("Email",
                            style: TextStyle(
                              color: isPhoneSelected?Colors.grey:Colors.deepOrangeAccent,
                              fontWeight: FontWeight.bold,

                            ),),
                        ),
                      ))
                    ],
                  ),

                ),
                Expanded(
                  child: SingleChildScrollView(
                    child:isPhoneSelected?
                    PhoneForm(key: ValueKey('phone'), formKey: _phoneFormKey,
                        phoneController: _phoneController,
                        passwordController: _passwordController):
                    EmailForm(key: ValueKey('email'), formKey: _emailFormKey,
                        emailController: _emailController,
                        passwordController: _passwordController),
                ),
                ),

              ],
            ),
          ),
        ),
      );

  }
}

class PhoneForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController phoneController;
  final TextEditingController passwordController;


  // final String formKey;
  const PhoneForm({Key? key, required this.formKey, required this.phoneController, required this.passwordController}): super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isPhoneSelected = true;
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text("Login Via Phone",
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(vertical: 30),
          child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextFormField(
                    controller: phoneController,

                    decoration: InputDecoration(labelText: "Phone Number",
                      labelStyle: TextStyle(color: Colors.grey, fontSize: 12),

                      // Default border when field is not focused
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey), // Outline color
                      ),

                      // Border when the field is focused
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blueGrey, width: 2), // Highlight color
                      ),),
                    // onSaved: (value) => _email = value,
                    validator: (value) => value!.isEmpty? "Number cannot be empty":null,
                  ),
                  SizedBox(height: 30),
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(labelText: "Password",
                      labelStyle: TextStyle(color: Colors.grey, fontSize: 12),

                      // Default border when field is not focused
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey), // Outline color
                      ),

                      // Border when the field is focused
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blueGrey, width: 2), // Highlight color
                      ),), obscureText: true,
                    // onSaved: (value) => _password = value,
                    validator: (value) => value!.length < 6 ?"Password must be at lest 6 characters":null,
                  ),
                  SizedBox(height: 30),
                  SizedBox(
                    height: 60,
                    width: double.infinity,
                    child: ElevatedButton(onPressed: (){
                      Navigator.pushNamed(context, AppRoutes.dashboard);
                      if(formKey.currentState!.validate()){

                        // formKey.currentState!.save();
                        print("phone: ${phoneController.text}");
                        print("password: ${passwordController.text}");

                      }
                    },
                        style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(Colors.blueAccent),
                            shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))

                        ),

                        child: Text("Submit", style: TextStyle(color: Colors.white , fontSize: 18),)),
                  )
                ],
              )
          ),
        ),
        TextButton(onPressed: (){
          print("Forgot Password");
        }, child: Text("Forgot Password?",
          style: TextStyle(fontWeight:FontWeight.bold, fontSize: 15 ),)),
        Text("Version 1.0.0",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w300)
        ),
      ],
    );
  }
}


class EmailForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;


  // final String formKey;
  const EmailForm({Key? key, required this.formKey, required this.emailController, required this.passwordController}): super(key: key);



  @override
  Widget build(BuildContext context) {
    bool isPhoneSelected = true;
    return  Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text("Login Via Email",
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(vertical: 30),
          child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextFormField(
                    controller: emailController,

                    decoration: InputDecoration(labelText: "Email",
                      labelStyle: TextStyle(color: Colors.grey, fontSize: 12),

                      // Default border when field is not focused
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey), // Outline color
                      ),

                      // Border when the field is focused
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.orangeAccent, width: 2), // Highlight color
                      ),),
                    // onSaved: (value) => _email = value,
                    validator: (value) => value!.isEmpty? "Number cannot be empty":null,
                  ),
                  SizedBox(height: 30),
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(labelText: "Password",
                      labelStyle: TextStyle(color: Colors.grey, fontSize: 12),

                      // Default border when field is not focused
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey), // Outline color
                      ),

                      // Border when the field is focused
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.orangeAccent, width: 2), // Highlight color
                      ),), obscureText: true,
                    // onSaved: (value) => _password = value,
                    validator: (value) => value!.length < 6 ?"Password must be at lest 6 characters":null,
                  ),
                  SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(onPressed: (){

                      if(formKey.currentState!.validate()){
                        Navigator.pushNamed(context, AppRoutes.dashboard);
                        // formKey.currentState!.save();
                        print("Email: ${emailController.text}");
                        print("password: ${passwordController.text}");
                      }
                    },
                        style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(Colors.deepOrange),
                            shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))

                        ),

                        child: Text("Login", style: TextStyle(color: Colors.white , fontSize: 18),)),
                  )
                ],
              )
          ),
        ),
        TextButton(onPressed: (){
          print("Forgot Password");
        }, child: Text("Forgot Password?",
          style: TextStyle(fontWeight:FontWeight.bold, fontSize: 15 ),)),
        Text("Version 1.0.0",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w300)
        ),
      ],
    );
  }
}

