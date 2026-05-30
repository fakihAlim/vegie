# Backend Production Deployment Setup

I have successfully prepared the backend logic to handle a live environment without breaking your local XAMPP setup.

Here are the key changes made:

## 1. Dynamic API Routing
We updated `api/index.php` so that it no longer relies on the hardcoded `/Vegie/api` path. It now automatically detects its own directory. This means when you upload it to `https://yodi.my.id/vegie`, the API will route correctly under `/vegie/api`.

> [!TIP]
> The `.htaccess` file inside the `api` folder handles CORS (cross-origin access) and directs all traffic to `index.php`. Make sure your live hosting supports `.htaccess` (Apache/LiteSpeed servers do this by default).

## 2. Environment Variables (`env.php`)
We implemented a secure way to hold your database credentials. 
- You will find a new file at `api/env.php`. 
- **Action Required on Live Server**: When you upload your code to the live server, open `api/env.php` on the server and enter your live database username, password, and AI API keys.
- Our code in `database.php` will automatically read `env.php` if it's there. If it's not there (like on your laptop), it safely defaults to `localhost` and `root` so your XAMPP setup continues to work!

## 3. Flutter App URL Refactoring
We updated the base URL inside the Flutter app's constants file (`vegie_app/lib/config/constants.dart`). It now uses an intelligent switch:
```dart
static const String baseUrl = bool.fromEnvironment('dart.vm.product')
    ? 'https://yodi.my.id/vegie/api'
    : 'http://192.168.10.161/Vegie/api';
```
> [!NOTE]
> What does this do?
> - **When testing via USB/Emulator**: It will use `http://192.168.10.161/Vegie/api` automatically.
> - **When building APK (`flutter build apk`)**: It will use `https://yodi.my.id/vegie/api` automatically.

## Next Steps for You:
1. Upload the `api` and `admin` folders to your hosting at `public_html/vegie` (or whichever folder maps to `yodi.my.id/vegie`).
2. Go to phpMyAdmin on your hosting control panel, create a database, and **Import** the `.sql` file you mentioned you already had.
3. Edit `api/env.php` on the server with the database details you just created.
4. Your backend is officially live! You can build the release APK for the mobile app now.
