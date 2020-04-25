import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';

void showBottomToast(String message, int durationInSeconds) {
  showToast(
    message,
    duration: Duration(seconds: durationInSeconds),
    position: ToastPosition.bottom,
    backgroundColor: Colors.white,
    radius: 5.0,
    textStyle: TextStyle(fontSize: 16.0, color: Colors.black),
  );
}