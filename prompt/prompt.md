> ## Bug Fix: Kelola Pengguna — Nonaktifkan Akun Tidak Tersimpan ke Database
>
> ### Masalah
> Di `AdminUserManagementPage`, saat Admin menekan tombol "Nonaktifkan", nilai `is_active` di tabel `profiles` Supabase tidak berubah — tetap `true`. Akun yang seharusnya dinonaktifkan masih bisa login.
>
> ### Yang Perlu Diperiksa & Diperbaiki
>
> **1. Cek `admin_user_management_page.dart`**
> Pastikan fungsi nonaktifkan memanggil update ke Supabase dengan benar:
> ```dart
> // Seharusnya seperti ini
> await supabase
>   .from('profiles')
>   .update({'is_active': false})
>   .eq('id', userId);
> ```
> Jika tidak ada kode seperti ini, tambahkan.
>
> **2. Cek apakah ada error handling yang menelan error**
> ```dart
> // ❌ Jangan seperti ini — error tidak ketahuan
> try {
>   await supabase.from('profiles').update(...)...;
> } catch (e) {
>   // kosong / hanya print
> }
>
> // ✅ Tampilkan error ke user
> try {
>   await supabase.from('profiles').update({'is_active': false}).eq('id', userId);
>   if (mounted) {
>     ScaffoldMessenger.of(context).showSnackBar(
>       const SnackBar(content: Text('Akun berhasil dinonaktifkan'), backgroundColor: Colors.green),
>     );
>     setState(() {}); // refresh list
>   }
> } catch (e) {
>   if (mounted) {
>     ScaffoldMessenger.of(context).showSnackBar(
>       SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
>     );
>   }
> }
> ```
>
> **3. Cek RLS Policy di Supabase**
> Kemungkinan RLS (Row Level Security) memblokir update dari Flutter. Tambahkan policy ini di Supabase SQL Editor:
> ```sql
> -- Izinkan admin update profiles
> CREATE POLICY "Admin can update profiles"
> ON profiles
> FOR UPDATE
> TO authenticated
> USING (
>   EXISTS (
>     SELECT 1 FROM profiles
>     WHERE id = auth.uid()
>     AND role = 'admin'
>   )
> );
> ```
>
> **4. Setelah update berhasil, refresh list pengguna**
> ```dart
> // Pastikan ada setState atau reload setelah update
> await _loadUsers(); // panggil ulang fetch data
> ```
>
> **5. Cek pengecekan `is_active` saat login di `auth_repository_impl.dart`**
> Pastikan ada pengecekan ini setelah login berhasil:
> ```dart
> // Setelah signInWithPassword berhasil
> final profile = await supabaseClient
>   .from('profiles')
>   .select('is_active')
>   .eq('id', supabaseClient.auth.currentUser!.id)
>   .single();
>
> if (profile['is_active'] == false) {
>   await supabaseClient.auth.signOut();
>   return Left(ServerFailure('Akun Anda telah dinonaktifkan oleh Admin. Hubungi administrator.'));
> }
> ```
>
> ### Constraints
> - Tampilkan error yang jelas ke user jika update gagal
> - Jangan biarkan error tertelan tanpa feedback
> - Jalankan `flutter analyze` setelah fix
> - Test dengan cara: nonaktifkan akun → cek database → coba login dengan akun itu

> **Tambahan karena sudah ada MCP Supabase:**
> 1. Cek langsung isi tabel `profiles` untuk verifikasi nilai `is_active`
> 2. Cek apakah RLS policy untuk update `profiles` sudah ada — jika belum, buat langsung via MCP
> 3. Setelah fix kode Flutter, test langsung dengan query ke Supabase untuk konfirmasi nilai `is_active` berubah
> 4. Jika perlu buat policy RLS baru, lakukan langsung tanpa perlu saya jalankan manual

