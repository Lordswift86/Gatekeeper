# Flutter API Integration Guide

## ✅ Completed

### Dependencies Added
- `http: ^1.1.0` - HTTP requests
- `shared_preferences: ^2.2.2` - Token storage

### Files Created

1. **`lib/services/api_config.dart`** - API configuration
2. **`lib/services/api_service.dart`** - Base HTTP service with token management
3. **`lib/services/api_client.dart`** - High-level API client with all endpoints

### Models Updated

All models now have JSON serialization:
- ✅ `User.fromJson()` and `User.toJson()`
- ✅ `GuestPass.fromJson()` and `GuestPass.toJson()`  
- ✅ `Bill.fromJson()` and `Bill.toJson()`

---

## 🔄 Screen Updates Needed

Replace `MockService()` with `ApiClient` in all screens:

### 1. Login Screen

**Before:**
```dart
import 'package:gatekeeper_resident/services/mock_service.dart';

final user = await MockService().login(email);
```

**After:**
```dart
import 'package:gatekeeper_resident/services/api_client.dart';

try {
  final result = await ApiClient.login(email, password);
  final user = result['user'] as User;
  // Navigate to home
} catch (e) {
  // Show error
  print('Login failed: $e');
}
```

### 2. Passes Screen

**Before:**
```dart
final passes = MockService().getUserPasses(userId);
```

**After:**
```dart
Future<void> loadPasses() async {
  try {
    setState(() => isLoading = true);
    final passes = await ApiClient.getUserPasses();
    setState(() {
      this.passes = passes;
      isLoading = false;
    });
  } catch (e) {
    setState(() => isLoading = false);
    // Show error snackbar
  }
}
```

### 3. Generate Pass Screen

**Before:**
```dart
final newPass = MockService().generatePass(
  userId: user.id,
  guestName: guestName,
  type: selectedType,
);
```

**After:**
```dart
Future<void> generatePass() async {
  try {
    setState(() => isGenerating = true);
    final newPass = await ApiClient.generatePass(
      guestName: guestName,
      type: selectedType.name,
      exitInstruction: exitInst,
    );
    setState(() => isGenerating = false);
    Navigator.pop(context, newPass);
  } catch (e) {
    setState(() => isGenerating = false);
    // Show error
  }
}
```

### 4. Bills Screen

**Before:**
```dart
final bills = MockService().getUserBills(userId);
```

**After:**
```dart
Future<void> loadBills() async {
  try {
    setState(() => isLoading = true);
    final bills = await ApiClient.getUserBills();
    setState(() {
      this.bills = bills;
      isLoading = false;
    });
  } catch (e) {
    setState(() => isLoading = false);
  }
}
```

### 5. Pay Bill

**Before:**
```dart
await MockService().payBill(billId);
```

**After:**
```dart
Future<void> payBill(String billId) async {
  try {
    setState(() => isPaying = true);
    await ApiClient.payBill(billId);
    await loadBills(); // Refresh list
    setState(() => isPaying = false);
  } catch (e) {
    setState(() => isPaying = false);
    // Show error
  }
}
```

---

## 📝 Implementation Checklist

### Resident App
- [ ] Update login screen
- [ ] Update passes list screen
- [ ] Update generate pass screen
- [ ] Update bills screen  
- [ ] Update pay bill functionality
- [ ] Update profile screen
- [ ] Add loading states
- [ ] Add error handling
- [ ] Test with backend

### Security App (Similar Pattern)
- [ ] Add http and shared_preferences packages
- [ ] Create api_config.dart
- [ ] Create api_service.dart
- [ ] Create api_client.dart with security endpoints
- [ ] Update models with JSON serialization
- [ ] Update all screens

---

## 🧪 Testing

### Test Credentials
```
Resident:
Email: bob@sunset.com
Password: password123

Security:
Email: sam@sunset.com
Password: password123
```

### Backend Status
```bash
# Check backend is running
curl http://localhost:3000/api/health

# Test login
curl -X POST http://localhost:3000/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"bob@sunset.com","password":"password123"}'
```

---

## 🚨 Common Issues

### Issue 1: Network Error
**Error**: `SocketException: Connection refused`  
**Solution**: Ensure backend is running on `http://localhost:3000`

### Issue 2: 401 Unauthorized
**Error**: `Unauthorized. Please login again`  
**Solution**: Token expired or invalid. Re-login to get new token.

### Issue 3: JSON Parsing Error
**Error**: `type 'String' is not a subtype of type 'int'`  
**Solution**: Check timestamp parsing in models. Backend sends ISO strings, we convert to milliseconds.

---

## 🎯 Next Steps

1. Update main.dart to check for existing token on app start
2. Add auto-logout on 401 errors
3. Add pull-to-refresh on list screens
4. Add offline caching (optional)
5. Test all flows end-to-end

## Example: Complete Login Screen Update

```dart
import 'package:flutter/material.dart';
import 'package:gatekeeper_resident/services/api_client.dart';
import 'package:gatekeeper_resident/models/user.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiClient.login(
        _emailController.text,
        _passwordController.text,
      );
      
      final user = result['user'] as User;
      
      // Navigate to home
      Navigator.pushReplacementNamed(context, '/home', arguments: user);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            if (_errorMessage  != null)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(_errorMessage!, style: TextStyle(color: Colors.red)),
              ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
```
