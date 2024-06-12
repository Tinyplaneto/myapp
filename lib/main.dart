import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'home.dart'; // Import your HomeScreen here

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController logController = TextEditingController();

  String userNumber = '';

  FirebaseAuth auth = FirebaseAuth.instance;

  var otpFieldVisibility = false;
  var receivedID = '';

  void log(String message) {
    logController.text += '$message\n';
    setState(() {});
  }

  void verifyUserPhoneNumber() {
    auth.verifyPhoneNumber(
      phoneNumber: userNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await auth.signInWithCredential(credential).then(
          (value) {
            log('Logged In Successfully');
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomePage()), // Navigate to HomeScreen
            );
          },
        );
      },
      verificationFailed: (FirebaseAuthException e) {
        log(e.message ?? 'Verification Failed');
      },
      codeSent: (String verificationId, int? resendToken) {
        receivedID = verificationId;
        otpFieldVisibility = true;
        setState(() {});
        log('Code Sent');
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<void> verifyOTPCode() async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: receivedID,
      smsCode: otpController.text,
    );
    await auth
        .signInWithCredential(credential)
        .then((value) {
          log('User Logged In Successfully');
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HomePage()), // Navigate to HomeScreen
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Phone Authentication'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: IntlPhoneField(
                  controller: phoneController,
                  initialCountryCode: 'NG',
                  decoration: const InputDecoration(
                    hintText: 'Phone Number',
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    userNumber = val.completeNumber;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Visibility(
                  visible: otpFieldVisibility,
                  child: TextField(
                    controller: otpController,
                    decoration: const InputDecoration(
                      hintText: 'OTP Code',
                      labelText: 'OTP',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (otpFieldVisibility) {
                    verifyOTPCode();
                  } else {
                    verifyUserPhoneNumber();
                  }
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                child: Text(
                  otpFieldVisibility ? 'Login' : 'Verify',
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: TextField(
                  controller: logController,
                  maxLines: 10,
                  readOnly: true,
                  decoration: const InputDecoration(
                    hintText: 'Logs',
                    labelText: 'Logs',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
