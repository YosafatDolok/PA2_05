@extends('layouts.app', [ 
    'page' => __('Edit Profil'),
    'pageSlug' => 'profile'
])

@section('content')
    <div class="row">
        <div class="col-xl-10 col-lg-12 mx-auto">
            <div class="card aura-card shadow-lg border-0 overflow-hidden">
                <div class="card-header border-0 p-5 pb-0">
                    <div class="d-flex align-items-center gap-4">
                        <div class="stat-icon" style="width: 60px; height: 60px; background: var(--aura-crimson); color: white; border-radius: 18px; display: flex; align-items: center; justify-content: center; font-size: 1.5rem; box-shadow: 0 10px 20px rgba(204, 78, 70, 0.2);">
                            <i class="fas fa-user-shield"></i>
                        </div>
                        <div>
                            <h3 class="m-0 font-weight-bold">Pengaturan Profil</h3>
                            <p class="text-muted small uppercase letter-spacing-1 mb-0">Kelola informasi akun Anda</p>
                        </div>
                    </div>
                </div>

                <div class="card-body p-5">
                    {{-- SUCCESS MESSAGE --}}
                    @if(session('success'))
                        <div class="alert alert-success bg-success-light border-0 py-3 mb-5 border-start border-4 border-success">
                            <div class="d-flex align-items-center">
                                <i class="fas fa-check-double me-3 fs-5"></i>
                                <div>
                                    <div class="fw-bold fs-6">BERHASIL</div>
                                    <div class="small opacity-75">{{ session('success') }}</div>
                                </div>
                            </div>
                        </div>
                    @endif

                    <form method="POST" action="{{ route('profile.update') }}" enctype="multipart/form-data">
                        @csrf
                        @method('PUT')

                        <div class="row g-5">
                            {{-- LEFT: AVATAR --}}
                            <div class="col-lg-4 text-center">
                                <div class="position-relative d-inline-block mb-4">
                                    <div class="avatar-ring position-absolute top-50 start-50 translate-middle" style="width: 220px; height: 220px; border: 2px dashed rgba(204, 78, 70, 0.3); border-radius: 50%;"></div>
                                    <div class="aura-upload-zone rounded-circle mx-auto" style="width:180px; height:180px; min-height: 180px; z-index: 2; border: 4px solid var(--aura-crimson); padding: 5px; overflow: hidden;">
                                        <img id="previewImage" src="{{ $user->profile_picture ? asset('storage/' . $user->profile_picture) : 'https://ui-avatars.com/api/?name=' . urlencode($user->name) . '&background=EB4D4B&color=fff' }}" alt="Profile" class="aura-upload-preview active rounded-circle" style="width: 100%; height: 100%; object-fit: cover; padding: 0; position: static;">
                                    </div>
                                </div>
                                
                                <div class="px-4">
                                    <label class="btn btn-outline-secondary w-100 py-3 rounded-4 mb-3" style="border: 1px dashed var(--aura-border); color: var(--aura-text-main);">
                                        <i class="fas fa-camera me-2"></i> UBAH FOTO
                                        <input type="file" name="profile_picture" accept="image/*" onchange="handleImagePreview(event)" hidden>
                                    </label>
                                    <p class="extra-small text-muted text-uppercase">Ukuran maks: 2MB</p>
                                </div>
                            </div>

                            {{-- RIGHT: CREDENTIALS --}}
                            <div class="col-lg-8 border-start border-secondary border-opacity-10">
                                <div class="row g-4">
                                    <div class="col-12">
                                        <div class="form-group mb-0">
                                            <label>NAMA LENGKAP</label>
                                            <input type="text" name="name" class="form-control form-control-aura @error('name') is-invalid @enderror" value="{{ old('name', $user->name) }}">
                                            @error('name')
                                                <span class="invalid-feedback">{{ $message }}</span>
                                            @enderror
                                        </div>
                                    </div>

                                    <div class="col-md-6">
                                        <div class="form-group mb-0">
                                            <label>ALAMAT EMAIL</label>
                                            <input type="email" name="email" class="form-control form-control-aura @error('email') is-invalid @enderror" value="{{ old('email', $user->email) }}">
                                            @error('email')
                                                <span class="invalid-feedback">{{ $message }}</span>
                                            @enderror
                                        </div>
                                    </div>

                                    <div class="col-md-6">
                                        <div class="form-group mb-0">
                                            <label>NOMOR TELEPON</label>
                                            <input type="tel" name="phone_number" class="form-control form-control-aura @error('phone_number') is-invalid @enderror" value="{{ old('phone_number', $user->phone_number) }}" oninput="this.value = this.value.replace(/[^0-9]/g, '');">
                                            @error('phone_number')
                                                <span class="invalid-feedback">{{ $message }}</span>
                                            @enderror
                                        </div>
                                    </div>

                                    <div class="col-12 mt-5">
                                        <button type="submit" class="btn btn-primary btn-lg w-100 py-4 font-weight-bold shadow-sm">
                                            SIMPAN PERUBAHAN
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>



    <script>
    function handleImagePreview(event) {
        const reader = new FileReader();
        const preview = document.getElementById('previewImage');
        
        reader.onload = function () {
            preview.src = reader.result;
            preview.classList.add('active');
        };
        if(event.target.files[0]) reader.readAsDataURL(event.target.files[0]);
    }
    </script>
@if(session('requires_password_confirmation'))
    <div class="modal fade" id="passwordConfirmModal" tabindex="-1" data-bs-backdrop="static">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content border-0 shadow-lg">
                <div class="modal-header border-0 bg-light">
                    <h5 class="modal-title fw-bold text-dark"><i class="fas fa-lock text-primary me-2"></i>Konfirmasi Password</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body p-4">
                    <p class="text-muted mb-4">Untuk alasan keamanan, masukkan password Anda saat ini untuk mengonfirmasi perubahan email atau nomor telepon.</p>
                    <form action="{{ route('profile.confirm') }}" method="POST">
                        @csrf
                        <div class="form-group mb-4">
                            <label class="fw-bold">PASSWORD SAAT INI</label>
                            <input type="password" name="current_password" class="form-control form-control-lg form-control-aura bg-light" required autofocus>
                        </div>
                        <div class="d-flex gap-2 justify-content-end">
                            <button type="button" class="btn btn-light px-4" data-bs-dismiss="modal">Batal</button>
                            <button type="submit" class="btn btn-primary px-4 fw-bold">Konfirmasi</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            var myModal = new bootstrap.Modal(document.getElementById('passwordConfirmModal'));
            myModal.show();
        });
    </script>
@endif
@endsection
