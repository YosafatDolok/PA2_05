@extends('layouts.app', [
    'page' => __('Manajemen Sopir'),
    'pageSlug' => 'drivers'
])

@section('content')
    <div class="d-flex justify-content-between align-items-center mb-5">
        <div>
            <h2 class="m-0 font-weight-bold">Manajemen Sopir</h2>
            <p class="text-muted small uppercase letter-spacing-1 mb-0">Kelola armada pengiriman Anda</p>
        </div>
        <a href="{{ route('drivers.create') }}" class="btn btn-primary rounded-pill px-4">
            <i class="fas fa-plus me-2"></i> DAFTAR SOPIR BARU
        </a>
    </div>

    @include('alerts.success')
    @include('alerts.error')

    <div class="row">
        <div class="col-12">
            <div class="card aura-card border-0 shadow-lg">
                <div class="table-responsive">
                    <table class="table align-items-center mb-0">
                        <thead>
                            <tr>
                                <th>NAMA</th>
                                <th>EMAIL</th>
                                <th>TELEPON</th>
                                <th class="text-center">AKSI</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($drivers as $driver)
                            <tr>
                                <td>
                                    <div class="d-flex align-items-center">
                                        <div class="aura-avatar me-3">
                                            @if($driver->profile_picture)
                                                <img src="{{ asset('storage/' . $driver->profile_picture) }}" alt="profile" class="rounded-pill shadow-sm" style="width:45px; height:45px; object-fit:cover;">
                                            @else
                                                <div class="bg-dark rounded-pill d-flex align-items-center justify-content-center shadow-sm" style="width:45px; height:45px; border: 1px solid var(--aura-border);">
                                                    <i class="fas fa-user text-muted opacity-25"></i>
                                                </div>
                                            @endif
                                        </div>
                                        <div class="mb-0 font-weight-bold text-white fs-6">
                                            {{ $driver->name }}
                                            @if($driver->invite_token)
                                                <span class="badge bg-warning-light text-warning small ms-2 px-2 border-warning-soft" style="font-size: 10px;">TERTUNDA</span>
                                            @endif
                                        </div>
                                    </div>
                                </td>
                                <td>
                                    <div class="text-muted small">{{ $driver->email }}</div>
                                </td>
                                <td>
                                    <div class="text-muted small">{{ $driver->phone_number ?? 'N/A' }}</div>
                                </td>
                                <td class="text-center">
                                    <div class="d-flex justify-content-center gap-3">
                                        <a href="{{ route('drivers.edit', $driver) }}" class="btn btn-sm btn-icon btn-secondary rounded-circle">
                                            <i class="fas fa-user-edit"></i>
                                        </a>

                                        <button type="button" 
                                                class="btn btn-sm btn-icon btn-outline-danger shadow-sm rounded-circle"
                                                onclick="confirmSecureDelete('{{ $driver->name }}', '{{ route('drivers.destroy', $driver) }}')">
                                            <i class="fas fa-trash-can"></i>
                                        </button>
                                    </div>
                                </td>
                            </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <!-- Secure Delete Modal -->
    <div class="modal fade" id="secureDeleteModal" tabindex="-1" role="dialog" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered" role="document">
            <div class="modal-content aura-card border-0">
                <div class="modal-header border-0 pb-0">
                    <h4 class="modal-title font-weight-bold text-white">Konfirmasi Hapus</h4>
                    <button type="button" class="btn-close btn-close-white opacity-50" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body py-4">
                    <div class="text-center mb-4">
                        <div class="bg-danger-light rounded-circle d-inline-flex align-items-center justify-content-center mb-3" style="width: 60px; height: 60px;">
                            <i class="fas fa-exclamation-triangle text-danger fs-3"></i>
                        </div>
                        <p class="text-white mb-1">Apakah Anda yakin ingin menghapus driver ini?</p>
                        <p class="text-muted small">Tindakan ini tidak dapat dibatalkan dan akan menghapus semua data terkait driver ini.</p>
                    </div>

                    <div class="form-group mb-0">
                        <label class="text-muted small uppercase mb-2">Ketik <span class="text-white font-weight-bold" id="targetNameDisplay"></span> untuk mengonfirmasi</label>
                        <input type="text" id="confirmNameInput" class="form-control bg-dark border-secondary text-white" placeholder="Ketik nama sopir di sini..." autocomplete="off">
                    </div>
                </div>
                <div class="modal-footer border-0 pt-0">
                    <form id="secureDeleteForm" method="POST">
                        @csrf
                        @method('DELETE')
                        <button type="button" class="btn btn-secondary rounded-pill px-4" data-bs-dismiss="modal">BATAL</button>
                        <button type="submit" id="confirmDeleteBtn" class="btn btn-danger rounded-pill px-4" disabled>HAPUS PERMANEN</button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <script>
        let targetName = '';

        function confirmSecureDelete(name, actionUrl) {
            targetName = name;
            document.getElementById('targetNameDisplay').innerText = name;
            document.getElementById('secureDeleteForm').action = actionUrl;
            document.getElementById('confirmNameInput').value = '';
            document.getElementById('confirmDeleteBtn').disabled = true;
            
            // Use Bootstrap 5 way to show modal
            var myModal = new bootstrap.Modal(document.getElementById('secureDeleteModal'));
            myModal.show();
        }

        document.getElementById('confirmNameInput').addEventListener('input', function(e) {
            const inputName = e.target.value.trim();
            const deleteBtn = document.getElementById('confirmDeleteBtn');
            
            if (inputName === targetName) {
                deleteBtn.disabled = false;
                deleteBtn.classList.remove('btn-secondary');
                deleteBtn.classList.add('btn-danger');
            } else {
                deleteBtn.disabled = true;
            }
        });
    </script>
@endsection
