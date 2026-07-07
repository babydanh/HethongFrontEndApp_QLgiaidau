import 'package:flutter/material.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'gsi_web_stub.dart'
    if (dart.library.js_interop) 'package:google_sign_in_web/google_sign_in_web.dart' as web;

Widget buildGoogleSignInButton() {
  final googleSignInPlugin = GoogleSignInPlatform.instance as web.GoogleSignInPlugin;
  return googleSignInPlugin.renderButton();
}
