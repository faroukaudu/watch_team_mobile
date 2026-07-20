import 'package:flutter/material.dart';
import '../main.dart';
import '../routes.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:watch_team/session_data.dart';
import 'package:watch_team/global.dart' as g;
import 'package:watch_team/services/worked_hours_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_team/screens/auth/forgot_password_email_screen.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../services/api_client.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
  // 192.168.43.39

  bool _isloading = false;

  void _showLoader() {
    if (!mounted) return;

    setState(() {
      _isloading = true;
    });
  }

  void _hideLoader() {
    if (!mounted) return;

    setState(() {
      _isloading = false;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            child: Container(
              decoration: BoxDecoration(
                  image: DecorationImage(image: AssetImage('images/login-bg.jpg'), fit: BoxFit.cover, opacity: 0.04)
              ),
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
                        PhoneForm(
                          key: const ValueKey('phone'),
                          formKey: _phoneFormKey,
                          phoneController: _phoneController,
                          passwordController: _passwordController,
                          loaderOnPressed: _showLoader,
                          loaderOff: () {
                            if (!mounted) return;

                            setState(() {
                              _isloading = false;
                            });
                          },
                        ):
                        EmailForm(
                          key: const ValueKey('email'),
                          formKey: _emailFormKey,
                          emailController: _emailController,
                          passwordController: _passwordController,
                          loaderOnPressed: _showLoader,
                          hideLoader: _hideLoader,
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),
        ),
        if(_isloading) ...[
          Positioned.fill(child: Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.blue,

              ),

            ),
          )),
        ],



      ],
    );

  }
}

class PhoneForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final VoidCallback loaderOnPressed;
  final VoidCallback loaderOff;

  const PhoneForm({
    super.key,
    required this.formKey,
    required this.phoneController,
    required this.passwordController,
    required this.loaderOnPressed,
    required this.loaderOff,
  });

  @override
  State<PhoneForm> createState() => _PhoneFormState();
}

class _PhoneFormState extends State<PhoneForm> {
  Future<void> _submitPhoneLogin() async {
    if (!(widget.formKey.currentState?.validate() ?? false)) {
      return;
    }

    widget.loaderOnPressed();

    try {
      final phone = widget.phoneController.text.trim();
      final password = widget.passwordController.text;

      final api = ApiClient(
        baseUrl: '${g.baseUrl}',
      );

      final loginResponse = await api.guardPhoneSignIn(
        phone: phone,
        password: password,
      );

      if (!mounted) return;

      if (loginResponse['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loginResponse['message']?.toString() ??
                  'Phone login failed',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );

        return;
      }

      final requiresSelection =
          loginResponse['requiresAccountSelection'] == true;

      if (requiresSelection) {
        final accountsRaw =
            loginResponse['accounts'] as List? ?? [];

        final accounts = accountsRaw
            .whereType<Map>()
            .map(
              (item) => Map<String, dynamic>.from(item),
        )
            .toList();

        final selectedAccountId =
        await _showAccountSelection(accounts);

        if (!mounted || selectedAccountId == null) {
          return;
        }

        final selectedResponse =
        await api.selectGuardPhoneLoginAccount(
          userId: selectedAccountId,
        );

        if (!mounted) return;

        if (selectedResponse['success'] != true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                selectedResponse['message']?.toString() ??
                    'Unable to select account',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );

          return;
        }

        await _completeLogin(selectedResponse);
        return;
      }

      await _completeLogin(loginResponse);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      widget.loaderOff();
    }
  }

  Future<String?> _showAccountSelection(
      List<Map<String, dynamic>> accounts,
      ) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF2B2F35),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              18,
              18,
              18,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Your Guard Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'More than one guard account uses this phone number and password.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: accounts.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final account = accounts[index];

                      final userId =
                          account['userId']?.toString() ?? '';

                      final fullname =
                          account['fullname']?.toString() ??
                              'Guard Account';

                      final company =
                          account['compName']?.toString() ??
                              account['assignedCompanyID']
                                  ?.toString() ??
                              '';

                      final postSites =
                          account['guardPostSite'] as List? ??
                              [];

                      String postSiteName = '';

                      if (postSites.isNotEmpty &&
                          postSites.first is Map) {
                        final site = Map<String, dynamic>.from(
                          postSites.first as Map,
                        );

                        postSiteName =
                            site['siteName']?.toString() ??
                                site['name']?.toString() ??
                                '';
                      }

                      return InkWell(
                        onTap: userId.isEmpty
                            ? null
                            : () {
                          Navigator.pop(
                            sheetContext,
                            userId,
                          );
                        },
                        borderRadius:
                        BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius:
                            BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF444444),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.blue
                                      .withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person_outline,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fullname,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight:
                                        FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (company.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        company,
                                        style: TextStyle(
                                          color: Colors.white
                                              .withOpacity(0.6),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                    if (postSiteName.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        postSiteName,
                                        style: const TextStyle(
                                          color: Colors.blueAccent,
                                          fontSize: 12,
                                          fontWeight:
                                          FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.white54,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _completeLogin(
      Map<String, dynamic> response,
      ) async {
    final userId =
        response['userId']?.toString() ??
            response['id']?.toString() ??
            '';

    if (userId.isEmpty) {
      throw Exception(
        'Login succeeded, but no user ID was returned.',
      );
    }

    await fetchUserProfile(userId);

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.dashboard,
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Login Via Phone',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(
            vertical: 30,
          ),
          child: Form(
            key: widget.formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: widget.phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'Enter phone number',
                    labelStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                    prefixIcon: const Icon(
                      Icons.phone_outlined,
                      color: Colors.grey,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.grey,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.blueAccent,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Phone number cannot be empty';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: widget.passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) =>
                      _submitPhoneLogin(),
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Colors.grey,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.grey,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.blueAccent,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return 'Password cannot be empty';
                    }

                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 30),
                SizedBox(
                  height: 60,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitPhoneLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                const ForgotPasswordEmailScreen(),
              ),
            );
          },
          child: const Text(
            'Forgot Password?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            final version = snapshot.data?.version ?? '';
            final buildNumber = snapshot.data?.buildNumber ?? '';

            return Text(
              version.isEmpty
                  ? 'Version'
                  : 'Version $version ($buildNumber)',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w300,
              ),
            );
          },
        ),
      ],
    );
  }
}


class EmailForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback loaderOnPressed;
  final VoidCallback hideLoader;


  // final String formKey;
  const EmailForm({
    Key? key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.loaderOnPressed,
    required this.hideLoader,
  }) : super(key: key);




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
                    child: ElevatedButton(onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        loaderOnPressed();

                        final email = emailController.text.trim();
                        final password = passwordController.text.trim();

                        final loginResponse = await signInRequest(email, password);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(loginResponse['message'] ?? 'Login failed'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }

                        if (loginResponse['success'] == true && loginResponse['id'] != null) {
                          final profileLoaded = await fetchUserProfile(loginResponse['id']);

                          if (profileLoaded == true) {
                            final prefs = await SharedPreferences.getInstance();

                            await prefs.setBool('isLoggedIn', true);
                            await prefs.setString('userId', loginResponse['id']);
                            await prefs.setString('email', loginResponse['email'] ?? '');

                            hideLoader();

                            if (context.mounted) {
                              Navigator.pushReplacementNamed(
                                context,
                                AppRoutes.dashboard,
                              );
                            }
                          } else {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.clear();

                            hideLoader();

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Unable to load guard profile. Please login again.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        } else {
                          hideLoader();
                        }
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
        InkWell(
          child:  TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const ForgotPasswordEmailScreen(),
                ),
              );
            },
            child: const Text(
              'Forgot Password?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            final version = snapshot.data?.version ?? '';
            final buildNumber = snapshot.data?.buildNumber ?? '';

            return Text(
              version.isEmpty
                  ? 'Version'
                  : 'Version $version ($buildNumber)',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w300,
              ),
            );
          },
        ),
      ],
    );
  }
}

Future<Map<String, dynamic>> signInRequest(
    String email,
    String password,
    ) async {
  final normalizedEmail = email.trim();

  if (normalizedEmail.isEmpty || password.isEmpty) {
    return {
      'success': false,
      'message': 'Please enter your email and password.',
      'email': null,
      'id': null,
    };
  }

  final url = Uri.parse(
    '${g.baseUrl}/guard-signin',
  );

  try {
    final response = await http
        .post(
      url,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'username': normalizedEmail,
        'password': password,
      }),
    )
        .timeout(
      const Duration(seconds: 20),
    );

    Map<String, dynamic> data = {};

    try {
      final decodedResponse = jsonDecode(response.body);

      if (decodedResponse is Map) {
        data = Map<String, dynamic>.from(
          decodedResponse,
        );
      }
    } catch (error) {
      debugPrint(
        'Unable to decode login response: $error',
      );

      debugPrint(
        'Raw login response: ${response.body}',
      );
    }

    final message =
        data['message']?.toString() ??
            _getLoginErrorMessage(response.statusCode);

    final userId =
        data['userId']?.toString() ??
            data['id']?.toString();

    return {
      'success':
      response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data['success'] == true,
      'message': message,
      'email':
      data['email']?.toString() ??
          normalizedEmail,
      'id': userId,
      'statusCode': response.statusCode,
    };
  } on TimeoutException {
    return {
      'success': false,
      'message':
      'The server took too long to respond. Please try again.',
      'email': null,
      'id': null,
    };
  } on SocketException catch (error) {
    debugPrint(
      'Mobile login connection error: $error',
    );

    return {
      'success': false,
      'message':
      'The app cannot reach the Watch Team server.',
      'email': null,
      'id': null,
    };
  } catch (error, stackTrace) {
    debugPrint(
      'Mobile guard login error: $error',
    );

    debugPrintStack(
      stackTrace: stackTrace,
    );

    return {
      'success': false,
      'message':
      'Unable to sign in. Please try again.',
      'email': null,
      'id': null,
    };
  }
}

String _getLoginErrorMessage(int statusCode) {
  switch (statusCode) {
    case 400:
      return 'Please enter your email and password.';

    case 401:
      return 'The email or password is incorrect.';

    case 403:
      return 'This guard account is inactive or not authorized for mobile login.';

    case 404:
      return 'The mobile login service was not found.';

    case 500:
      return 'The server encountered an error. Please try again.';

    default:
      return 'Login failed. Server response: $statusCode.';
  }
}


Future<bool> fetchUserProfile(String id) async {
  try {
    final response = await http.get(
      Uri.parse('${g.baseUrl}/guard-info?id=$id'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['guardData'] == null) {
        return false;
      }

      SessionData.userProfile = data['guardData'];
      SessionData.companyInfo = data['company'];

      return true;
    }

    print('Failed to fetch user profile: ${response.statusCode}');
    return false;
  } catch (e) {
    print('Failed to fetch user profile: $e');
    return false;
  }
}
