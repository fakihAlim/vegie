# LovingHarmony — Phase 1: Backend Foundation ✅

## Database
- [x] Create `database/lovingharmony.sql` schema
- [x] Import database to MySQL (12 tables)

## API Core
- [x] `api/.htaccess` — URL rewriting
- [x] `api/index.php` — Entry point + router
- [x] `api/config/database.php` — MySQL PDO connection
- [x] `api/config/firebase.php` — FCM config placeholder
- [x] `api/helpers/response.php` — JSON response helper
- [x] `api/helpers/jwt.php` — JWT encode/decode
- [x] `api/helpers/upload.php` — Image upload helper
- [x] `api/middleware/auth.php` — JWT verification

## API Controllers
- [x] `api/controllers/AuthController.php` — Register, Login, Profile, FCM Token
- [x] `api/controllers/FoodLogController.php` — CRUD + Sync
- [x] `api/controllers/NewsController.php` — List + Detail
- [x] `api/controllers/RecipeController.php` — List + Detail (w/ ingredients & steps)
- [x] `api/controllers/GroupController.php` — Create, Join, Posts, Members, Leave
- [x] `api/controllers/NotificationController.php` — List

## Admin Panel
- [x] `admin/assets/css/style.css` — Green natural theme
- [x] `admin/includes/header.php` — Head + navbar
- [x] `admin/includes/sidebar.php` — Sidebar navigation
- [x] `admin/includes/footer.php` — Footer + scripts
- [x] `admin/login.php` — Admin login page
- [x] `admin/logout.php` — Logout handler
- [x] `admin/index.php` — Dashboard with stats
- [x] `admin/pages/news/index.php` — List berita
- [x] `admin/pages/news/create.php` — Tambah berita
- [x] `admin/pages/news/edit.php` — Edit berita
- [x] `admin/pages/recipes/index.php` — List resep
- [x] `admin/pages/recipes/create.php` — Tambah resep (dynamic ingredients + steps)
- [x] `admin/pages/recipes/edit.php` — Edit resep
- [x] `admin/pages/users/index.php` — List users
- [x] `admin/pages/notifications/index.php` — Notifikasi + send modal

## Verification
- [x] Database creation — 12 tables, admin seeded
- [x] API auth register — ✅ tested
- [x] API auth login — ✅ tested
- [x] API auth profile — ✅ tested
- [x] API food-logs create — ✅ tested
- [x] API groups create — ✅ tested
- [x] Admin login — ✅ verified in browser
- [x] Admin dashboard — ✅ stats, recent users, recent logs all showing
