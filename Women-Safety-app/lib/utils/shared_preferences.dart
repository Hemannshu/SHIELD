import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesUtil {
  // Save login state and user role
  static Future<void> saveLoginState(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', role);  // Save the user role
    await prefs.setBool('isLoggedIn', true);  // Set the login state
  }

  // Logout function to clear saved data
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('role');  // Remove the role
    await prefs.setBool('isLoggedIn', false);  // Set login state to false
  }

  // Retrieve login state
  static Future<String?> getLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');  // Return the saved role
  }

  // Check if user is logged in
  static Future<bool?> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn');  // Return the login state
  }
}
