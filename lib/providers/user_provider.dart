// user의 상태를 관리하는 provider
import 'package:flutter/material.dart';
import 'package:flog/models/user.dart';

import '../resources/auth_methods.dart';

class UserProvider extends ChangeNotifier {
  User? _user; //현재 사용자의 정보를 가지는 User 객체
  final AuthMethods _authMethods = AuthMethods();

  User get getUser => _user!; //_user의 값을 가져오는 getter 메서드

  Future<void> refreshUser() async {
    User user = await _authMethods.getUserDetails();
    _user = user;
    notifyListeners();
  }
}
