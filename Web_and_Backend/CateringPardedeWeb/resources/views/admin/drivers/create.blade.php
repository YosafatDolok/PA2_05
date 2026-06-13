@extends('layouts.app', [
    'page' => __('Daftar Sopir'),
    'pageSlug' => 'drivers'
])

@section('content')
    <div class="row">
        <div class="col-xl-8 col-lg-10 mx-auto">
            <div class="card aura-card shadow-lg">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h4 class="m-0 font-weight-bold">Daftar Sopir Baru</h4>
                    <a href="{{ route('drivers.index') }}" class="btn btn-outline-secondary btn-sm rounded-pill px-3">
                        <i class="fas fa-arrow-left me-2"></i> KEMBALI KE DAFTAR
                    </a>
                </div>

                <div class="card-body p-4">
                    <form action="{{ route('drivers.store') }}" method="POST">
                        @csrf

                        <div class="row g-4">
                            {{-- NAME --}}
                            <div class="col-md-6">
                                <div class="form-group mb-0">
                                    <label>NAMA LENGKAP</label>
                                    <input type="text" name="name" class="form-control form-control-aura @error('name') is-invalid @enderror" placeholder="misal: Budi Santoso" value="{{ old('name') }}" required>
                                    @error('name')
                                        <span class="invalid-feedback">{{ $message }}</span>
                                    @enderror
                                </div>
                            </div>

                            {{-- EMAIL --}}
                            <div class="col-md-6">
                                <div class="form-group mb-0">
                                    <label>ALAMAT EMAIL</label>
                                    <input type="email" name="email" class="form-control form-control-aura @error('email') is-invalid @enderror" placeholder="misal: budi@example.com" value="{{ old('email') }}" required>
                                    @error('email')
                                        <span class="invalid-feedback">{{ $message }}</span>
                                    @enderror
                                </div>
                            </div>

                            {{-- PHONE NUMBER --}}
                            <div class="col-md-12">
                                <div class="form-group mb-0">
                                    <label>NOMOR TELEPON</label>
                                    <input type="text" name="phone_number" class="form-control form-control-aura @error('phone_number') is-invalid @enderror" placeholder="misal: 08123456789" value="{{ old('phone_number') }}">
                                    @error('phone_number')
                                        <span class="invalid-feedback">{{ $message }}</span>
                                    @enderror
                                </div>
                            </div>

                            <div class="col-12 mt-3">
                                <div class="alert alert-info border-0 p-3 small" style="background: rgba(0, 0, 0, 0.02); color: var(--aura-text-main);">
                                    <i class="fas fa-info-circle me-2 text-info"></i> Kata sandi akan diatur sendiri oleh Sopir melalui tautan undangan yang dikirim ke email mereka.
                                </div>
                            </div>

                            <div class="col-12 mt-5">
                                <button type="submit" class="btn btn-primary w-100 py-3 font-weight-bold">
                                    KIRIM UNDANGAN
                                </button>
                            </div>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
@endsection
