<?php
/**
 * Admin Footer Include
 * LovingHarmony Admin Panel
 */
?>
    <!-- SweetAlert2 for beautiful alerts -->
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <script>
        // Mobile sidebar toggle
        function toggleSidebar() {
            document.getElementById('sidebar').classList.toggle('open');
        }

        // Confirmation dialog for delete actions
        function confirmDelete(url, itemName) {
            Swal.fire({
                title: 'Hapus Item?',
                text: `Apakah Anda yakin ingin menghapus "${itemName}"?`,
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#DC3545',
                cancelButtonColor: '#6B7280',
                confirmButtonText: 'Ya, Hapus!',
                cancelButtonText: 'Batal'
            }).then((result) => {
                if (result.isConfirmed) {
                    window.location.href = url;
                }
            });
        }

        // Show flash messages
        <?php if (isset($_SESSION['flash_success'])): ?>
            Swal.fire({
                icon: 'success',
                title: 'Berhasil!',
                text: '<?= addslashes($_SESSION['flash_success']) ?>',
                timer: 2000,
                showConfirmButton: false
            });
            <?php unset($_SESSION['flash_success']); ?>
        <?php endif; ?>

        <?php if (isset($_SESSION['flash_error'])): ?>
            Swal.fire({
                icon: 'error',
                title: 'Error!',
                text: '<?= addslashes($_SESSION['flash_error']) ?>'
            });
            <?php unset($_SESSION['flash_error']); ?>
        <?php endif; ?>

        // Image upload preview
        function previewImage(input, previewId) {
            const preview = document.getElementById(previewId);
            if (input.files && input.files[0]) {
                const reader = new FileReader();
                reader.onload = function(e) {
                    preview.innerHTML = `
                        <div class="upload-preview">
                            <img src="${e.target.result}" alt="Preview">
                            <button type="button" class="remove-btn" onclick="removePreview('${input.id}', '${previewId}')">×</button>
                        </div>
                    `;
                };
                reader.readAsDataURL(input.files[0]);
            }
        }

        function removePreview(inputId, previewId) {
            document.getElementById(inputId).value = '';
            document.getElementById(previewId).innerHTML = '';
        }
    </script>
</body>
</html>
