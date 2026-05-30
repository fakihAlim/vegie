# implementation_plan.md — Phase 3: News & Recipes Polish

Berdasarkan masukan Anda bahwa tampilan Berita dan Resep "belum bagus", rencana ini fokus pada penyempurnaan UI/UX (estetika) dan fungsionalitas di kedua sisi (Admin Panel & Flutter) agar terlihat lebih premium dan profesional.

---

## Proposed Changes

### [Admin Panel - Web]
Meningkatkan kemudahan penggunaan (UX) bagi admin saat mengelola konten.

#### [MODIFY] [news/index.php](file:///c:/xampp/htdocs/Vegie/admin/pages/news/index.php) & [recipes/index.php](file:///c:/xampp/htdocs/Vegie/admin/pages/recipes/index.php)
- Memperbarui desain tabel dengan *badge* status (Published/Draft) yang lebih mencolok.
- Menambahkan kolom *thumbnail* kecil di daftar agar admin mudah mengenali konten.

#### [MODIFY] [create.php & edit.php (News/Recipes)](file:///c:/xampp/htdocs/Vegie/admin/pages/news/create.php)
- Mendesain ulang tata letak form menggunakan *grid* yang lebih rapi.
- Memperbaiki komponen *image upload* dengan pratinjau yang lebih besar dan tombol hapus gambar yang jelas.

---

### [Flutter App - Mobile]
Mencapai estetika "Green Natural" yang premium dan nyaman dipandang.

#### [NEW] [news_card.dart](file:///c:/xampp/htdocs/Vegie/vegie_app/lib/widgets/news_card.dart) & [recipe_card.dart](file:///c:/xampp/htdocs/Vegie/vegie_app/lib/widgets/recipe_card.dart)
- Memisahkan komponen kartu menjadi widget tersendiri.
- **News Card**: Desain modern dengan gambar penuh ke pinggir (*edge-to-edge*), bayangan halus (*soft shadow*), dan gradasi pada teks.
- **Recipe Card**: Penambahan ikon kalori dan waktu masak yang lebih ikonik (visual yang lebih kuat).

#### [MODIFY] [news_detail_screen.dart](file:///c:/xampp/htdocs/Vegie/vegie_app/lib/screens/news/news_detail_screen.dart)
- Implementasi *SliverAppBar* agar gambar berita bisa mengecil saat di-scroll (efek premium).
- Pengaturan tipografi (konten berita) dengan `LineHeight` yang lebih lega agar nyaman dibaca.

#### [MODIFY] [recipe_detail_screen.dart](file:///c:/xampp/htdocs/Vegie/vegie_app/lib/screens/recipes/recipe_detail_screen.dart)
- Visualisasi bahan-bahan (*Ingredients*) dalam format kartu kecil atau list dengan ikon.
- Visualisasi langkah memasak (*Steps*) dengan penomoran yang artistik dan jelas.
- Penambahan efek animasi saat pindah ke halaman detail.

---

## Verification Plan

### Manual Verification
1.  **Admin Panel**: Mencoba menambah resep dengan banyak bahan/langkah, pastikan form tetap rapi.
2.  **Flutter List View**: Memastikan tidak ada teks yang menumpuk (*overflow*) pada judul berita yang panjang.
3.  **Flutter Detail View**: Mengecek apakah gambar resep muncul dengan rasio yang benar dan langkah-langkah memasak mudah diikuti.
