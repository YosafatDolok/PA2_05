@extends('layouts.app', [
    'page' => __('Edit Sopir'),
    'pageSlug' => 'drivers'
])

@section('content')
    <div class="row">
        <div class="col-xl-8 col-lg-10 mx-auto">
            <div class="card aura-card shadow-lg">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <div class="d-flex align-items-center">
                        <h4 class="m-0 font-weight-bold">Edit Sopir: {{ $driver->name }}</h4>
                        @if($driver->invite_token)
                            <span class="badge bg-warning-light text-warning ms-3 px-3 py-2 rounded-pill small letter-spacing-1 border-warning-soft">MENUNGGU AKTIVASI</span>
                        @endif
                    </div>
                    <a href="{{ route('drivers.index') }}" class="btn btn-outline-secondary btn-sm rounded-pill px-3">
                        <i class="fas fa-arrow-left me-2"></i> KEMBALI KE DAFTAR
                    </a>
                </div>

                <div class="card-body p-4">
                    <form action="{{ route('drivers.update', $driver) }}" method="POST">
                        @csrf
                        @method('PUT')

                        <div class="row g-4">
                            {{-- NAME --}}
                            <div class="col-md-6">
                                <div class="form-group mb-0">
                                    <label>NAMA LENGKAP</label>
                                    <input type="text" name="name" class="form-control form-control-aura @error('name') is-invalid @enderror" value="{{ old('name', $driver->name) }}" required>
                                    @error('name')
                                        <span class="invalid-feedback">{{ $message }}</span>
                                    @enderror
                                </div>
                            </div>

                            {{-- EMAIL --}}
                            <div class="col-md-6">
                                <div class="form-group mb-0">
                                    <label>ALAMAT EMAIL</label>
                                    <input type="email" name="email" class="form-control form-control-aura @error('email') is-invalid @enderror" value="{{ old('email', $driver->email) }}" required>
                                    @error('email')
                                        <span class="invalid-feedback">{{ $message }}</span>
                                    @enderror
                                </div>
                            </div>

                            {{-- PHONE NUMBER --}}
                            <div class="col-md-12">
                                <div class="form-group mb-0">
                                    <label>NOMOR TELEPON</label>
                                    <input type="text" name="phone_number" class="form-control form-control-aura @error('phone_number') is-invalid @enderror" value="{{ old('phone_number', $driver->phone_number) }}">
                                    @error('phone_number')
                                        <span class="invalid-feedback">{{ $message }}</span>
                                    @enderror
                                </div>
                            </div>

                            @if($driver->invite_token)
                            {{-- INVITATION MANAGEMENT --}}
                            <div class="col-12 mt-4 pt-4 border-top border-secondary border-opacity-10">
                                <h6 class="text-muted small uppercase letter-spacing-1">Manajemen Undangan</h6>
                            </div>
                            <div class="col-12">
                                <div class="alert aura-card border-0 p-4 d-flex justify-content-between align-items-center" style="background: rgba(0, 0, 0, 0.02);">
                                    <div>
                                        <div class="fw-bold text-warning mb-1">Status: Menunggu Aktivasi</div>
                                        <div class="small text-muted">Undangan kedaluwarsa pada: {{ \Carbon\Carbon::parse($driver->invite_expires_at)->format('d M Y, H:i') }}</div>
                                    </div>
                                    <form action="{{ route('drivers.resend', $driver) }}" method="POST">
                                        @csrf
                                        <button type="submit" class="btn btn-aura-outline btn-sm">
                                            <i class="fas fa-paper-plane me-2"></i> KIRIM ULANG UNDANGAN
                                        </button>
                                    </form>
                                </div>
                            </div>
                            @else
                            {{-- SECURITY MANAGEMENT --}}
                            <div class="col-12 mt-4 pt-4 border-top border-secondary border-opacity-10">
                                <h6 class="text-muted small uppercase letter-spacing-1">Keamanan & Akses</h6>
                            </div>
                            <div class="col-12">
                                <div class="alert aura-card border-0 p-4 d-flex justify-content-between align-items-center" style="background: rgba(0, 0, 0, 0.02);">
                                    <div>
                                        <div class="fw-bold text-success mb-1">Akun Aktif</div>
                                        <div class="small text-muted">Pengguna telah mengatur kata sandi dan mengaktifkan profil mereka.</div>
                                    </div>
                                    <form action="{{ route('drivers.reset-link', $driver) }}" method="POST">
                                        @csrf
                                        <button type="submit" class="btn btn-aura-outline btn-sm text-danger border-danger">
                                            <i class="fas fa-key me-2"></i> KIRIM LINK RESET PASSWORD
                                        </button>
                                    </form>
                                </div>
                            </div>
                            @endif

                            <div class="col-12 mt-5">
                                <button type="submit" class="btn btn-primary w-100 py-3 font-weight-bold">
                                    PERBARUI DATA UTAMA
                                </button>
                            </div>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
@endsection
