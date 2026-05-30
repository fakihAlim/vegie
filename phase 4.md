# implementation_plan.md — Phase 4: Groups Feature

Sesuai permintaan Anda, kita akan melompati perbaikan notifikasi dan lanjut ke **Phase 4: Fitur Grup Komunitas**. Fitur ini memungkinkan pengguna untuk membuat grup, bergabung dengan kode unik, dan berbagi kiriman (*posts*) di dalam grup.

## User Review Required

> [!NOTE]
> Fitur grup ini sepenuhnya bergantung pada koneksi internet (*online-only*) sesuai dengan skema di `implementation_plan.md` utama.

---

## Proposed Changes

### [Flutter - Models]
Membuat struktur data untuk menampung informasi grup dan kiriman.

#### [NEW] [group.dart](file:///c:/xampp/htdocs/Vegie/vegie_app/lib/models/group.dart)
#### [NEW] [group_post.dart](file:///c:/xampp/htdocs/Vegie/vegie_app/lib/models/group_post.dart)

### [Flutter - Services]
Menghubungkan aplikasi dengan API backend yang sudah ada.

#### [NEW] [group_service.dart](file:///c:/xampp/htdocs/Vegie/vegie_app/lib/services/group_service.dart)
- `getGroups()`: Mengambil daftar grup yang diikuti.
- `createGroup(name, description)`: Membuat grup baru.
- `joinGroup(code)`: Bergabung grup lewat kode.
- `getGroupPosts(groupId)`: Mengambil kiriman di dalam grup.
- `createPost(groupId, content)`: Mengirim pesan ke grup.

### [Flutter - Providers]
Mengelola *state* grup agar data sinkron di seluruh aplikasi.

#### [NEW] [group_provider.dart](file:///c:/xampp/htdocs/Vegie/vegie_app/lib/providers/group_provider.dart)

### [Flutter - Screens]
Membangun antarmuka pengguna yang selaras dengan tema "Green Natural".

#### [NEW] [groups_screen.dart](file:///c:/xampp/htdocs/Vegie/vegie_app/lib/screens/groups/groups_screen.dart)
- Daftar grup dengan kartu yang cantik.
- Tombol (+) untuk opsi "Buat Grup" atau "Gabung Grup".

#### [NEW] [create_group_screen.dart](file:///c:/xampp/htdocs/Vegie/vegie_app/lib/screens/groups/create_group_screen.dart)
- Form input nama dan deskripsi grup.

#### [NEW] [join_group_screen.dart](file:///c:/xampp/htdocs/Vegie/vegie_app/lib/screens/groups/join_group_screen.dart)
- Input kode 6 karakter.

#### [NEW] [group_detail_screen.dart](file:///c:/xampp/htdocs/Vegie/vegie_app/lib/screens/groups/group_detail_screen.dart)
- Tab "Feed" untuk melihat kiriman anggota.
- Tab "Anggota" untuk melihat siapa saja yang bergabung.
- Fitur bagi kode grup (*Share Code*).

### [Flutter - Core Integration]

#### [MODIFY] [home_screen.dart](file:///c:/xampp/htdocs/Vegie/vegie_app/lib/screens/home/home_screen.dart)
- Mengganti `_DummyScreen` dengan `GroupsScreen` yang baru.

#### [MODIFY] [app.dart](file:///c:/xampp/htdocs/Vegie/vegie_app/lib/app.dart)
- Mendaftarkan `GroupProvider` ke dalam `MultiProvider`.

---

## Verification Plan

### Automated Tests
- Menjalankan `flutter analyze` untuk memastikan tidak ada error pada kode baru.

### Manual Verification
1.  **Daftar Grup**: Mengecek apakah daftar grup kosong menampilkan *empty state* yang bagus.
2.  **Buat Grup**: Membuat grup "Vegie Lovers" dan memastikan kode unik muncul.
3.  **Gabung Grup**: Menggunakan akun lain (atau minta saya simulasikan via API) untuk gabung menggunakan kode tersebut.
4.  **Posting**: Mengirim pesan di dalam grup dan memastikan muncul di feed anggota lain.
