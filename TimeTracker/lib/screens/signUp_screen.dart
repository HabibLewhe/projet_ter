import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_login_ui/screens/login_screen.dart';
import 'package:flutter_login_ui/utilities/constants.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:page_transition/page_transition.dart';
import 'package:sqflite/sqflite.dart';
import '../model/InitDatabase.dart';
import '../model/User.dart';
import 'Home.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUPScreenState createState() => _SignUPScreenState();
}

class _SignUPScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  double _height = 60.0;
  static const Color _color = Color(0xFFff3d3d);
  static const Color _color1 = Color(0xFFff3d3d);
  static const Color _color2 = Color(0xFFff2929);
  static const Color _color3 = Color(0xFFff1515);

  void signUp() async {
    String email = emailController.text.toString();
    String password = passwordController.text.toString();
    String name = nameController.text.toString();

    if (_formKey.currentState.validate()) {
      try{

        Database database = await InitDatabase().database;
        //create instance of User
        var user = User(username: name, email: email, password: password);
        //insert user to database
        await database.insert('users', user.toMap());
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt('userId', user.id);
        Fluttertoast.showToast(
            msg: "User registered successfully",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0
        );
        Navigator.push(context, PageTransition(type: PageTransitionType.bottomToTopJoined, child: MyHomePage(), childCurrent: this.widget, duration: Duration(milliseconds: 500)));
      }catch(e){
        print(e.toString());
      }

    }


  }


  Widget _buildEmailTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Email',
          style: kLabelStyle,
        ),
        SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          decoration: kBoxDecorationStyle,

          height: _height,
          child: TextFormField(
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty ) {
                return 'S.V.P entrer votre Email';
              }
              if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                return 'S.V.P entrer un Email valide';
              }
              return null;
            },
            controller: emailController,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'OpenSans',
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.email,
                color: Colors.white,
              ),
              hintText: 'Entrer votre Email',
              hintStyle: kHintTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserNameTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Nom d\'utilisateur',
          style: kLabelStyle,
        ),
        SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          decoration: kBoxDecorationStyle,
          height: _height,
          child: TextFormField(
            keyboardType: TextInputType.name,
            controller: nameController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'S.V.P entrer votre nom d\'utilisateur';
              }
              return null;
            },
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'OpenSans',
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.person,
                color: Colors.white,
              ),
              hintText: 'Entrer votre nom d\'utilisateur',
              hintStyle: kHintTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Mot de passe',
          style: kLabelStyle,
        ),
        SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          decoration: kBoxDecorationStyle,
          height: _height,
          child: TextFormField(
            obscureText: _obscurePassword,
            controller: passwordController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'S.V.P entrer votre mot de passe';
              }
              return null;
            },
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'OpenSans',
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14.0),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              prefixIcon: Icon(
                Icons.lock,
                color: Colors.white,
              ),
              hintText: 'Entrer votre mot de passe',
              hintStyle: kHintTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmePasswordTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Confirmation de mot de passe',
          style: kLabelStyle,
        ),
        SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          decoration: kBoxDecorationStyle,
          height: _height,
          child: TextFormField(
            obscureText: _obscureConfirmPassword,
            controller: confirmPasswordController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'S.V.P entrer votre mot de passe';
              }
              if (value != passwordController.text) {
                return 'S.V.P entrer le même mot de passe';
              }
              return null;
            },
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'OpenSans',
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14.0),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              prefixIcon: Icon(
                Icons.lock,
                color: Colors.white,
              ),
              hintText: 'Vérification de mot de pass' ,
              hintStyle: kHintTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpBtn() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 25.0),
      width: double.infinity,
      child: ElevatedButton (
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.white), //Background Color
          elevation: MaterialStateProperty.all(5), //Defines Elevation
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
              side: BorderSide(color: Colors.white),
            ),
          ),
        ),
        onPressed: () => signUp(),
        child: Text(
          'SIGNUP',
          style: TextStyle(
            color: _color,
            letterSpacing: 1.5,
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'OpenSans',
          ),
        ),
      ),
    );
  }


  Widget _buildSignupBtn() {
    return GestureDetector(
      onTap: () => Navigator.push(context, PageTransition(type: PageTransitionType.leftToRightJoined, child: LoginScreen(),childCurrent: this.widget,duration: Duration(milliseconds: 500))),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'Vous avez déjà un compte? ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.0,
                fontWeight: FontWeight.w400,
              ),
            ),
            TextSpan(
              text: 'Connecter',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: <Widget>[
              Container(
                height: double.infinity,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _color,
                      _color1,
                      _color2,
                      _color3,
                    ],
                    stops: [0.1, 0.4, 0.7, 0.9],
                  ),
                ),
              ),
              Container(
                height: double.infinity,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: 40.0,
                    vertical: 120.0,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'INSCRIPTION',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'OpenSans',
                          fontSize: 30.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _buildEmailTF(),
                      SizedBox(
                        height: 5.0,
                      ),
                      _buildUserNameTF(),
                      SizedBox(
                        height: 5.0,
                      ),
                      _buildPasswordTF(),
                      SizedBox(
                        height: 5.0,
                      ),
                      _buildConfirmePasswordTF(),
                      _buildSignUpBtn(),
                      _buildSignupBtn(),
                    ],
                  ),
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
