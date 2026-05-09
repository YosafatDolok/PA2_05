@extends('layouts.app', [
    'page' => __('Driver Management'),
    'pageSlug' => 'drivers'
])

@section('content')
    <div class="d-flex justify-content-between align-items-center mb-5">
        <div>
            <h2 class="m-0 font-weight-bold">Driver Management</h2>
            <p class="text-muted small uppercase letter-spacing-1 mb-0">Manage your delivery fleet</p>
        </div>
        <a href="{{ route('drivers.create') }}" class="btn btn-primary rounded-pill px-4">
            <i class="fas fa-plus me-2"></i> REGISTER NEW DRIVER
        </a>
    </div>

    @include('alerts.success')

    <div class="row">
        <div class="col-12">
            <div class="card aura-card border-0 shadow-lg">
                <div class="table-responsive">
                    <table class="table align-items-center mb-0">
                        <thead>
                            <tr>
                                <th>NAME</th>
                                <th>EMAIL</th>
                                <th>PHONE</th>
                                <th class="text-center">ACTIONS</th>
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
                                                <span class="badge bg-warning-light text-warning small ms-2 px-2 border-warning-soft" style="font-size: 10px;">PENDING</span>
                                            @else
                                                <span class="badge bg-success-light text-success small ms-2 px-2 border-success-soft" style="font-size: 10px;">ACTIVE</span>
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

                                        <form action="{{ route('drivers.destroy', $driver) }}" method="POST" class="d-inline">
                                            @csrf
                                            @method('DELETE')
                                            <button type="submit" class="btn btn-sm btn-icon btn-outline-danger shadow-sm rounded-circle" onclick="return confirm('Apakah Anda yakin ingin menghapus driver ini?')">
                                                <i class="fas fa-trash-can"></i>
                                            </button>
                                        </form>
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
@endsection
