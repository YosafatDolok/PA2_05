@extends('layouts.app', [
    'page' => __('Kategori'),
    'pageSlug' => 'categories'
])

@section('content')
    <div class="d-flex justify-content-between align-items-center mb-5">
        <div>
            <h2 class="m-0 font-weight-bold">Kategori</h2>
            <p class="text-muted small uppercase letter-spacing-1 mb-0">Kelola grup menu</p>
        </div>
        <a href="{{ route('categories.create') }}" class="btn btn-primary rounded-pill px-4">
            <i class="fas fa-layer-group me-2"></i> KATEGORI BARU
        </a>
    </div>

    <div class="row">
        <div class="col-12">
            <div class="card aura-card border-0 shadow-lg">
                <div class="table-responsive">
                    <table class="table align-items-center mb-0">
                        <thead>
                            <tr>
                                <th>NAMA KATEGORI</th>
                                <th class="text-center">AKSI</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($categories as $cat)
                            <tr>
                                <td>
                                    <div class="d-flex align-items-center">
                                        <div class="stat-icon me-3" style="width: 40px; height: 40px; font-size: 1rem;">
                                            <i class="fas fa-folder-open"></i>
                                        </div>
                                        <span class="font-weight-bold text-white fs-6">{{ $cat->name }}</span>
                                    </div>
                                </td>
                                <td class="text-center">
                                    <div class="d-flex justify-content-center gap-3">
                                        <a href="{{ route('categories.edit', $cat->category_id) }}" class="btn btn-sm btn-icon btn-secondary rounded-circle">
                                            <i class="fas fa-terminal"></i>
                                        </a>

                                        <form action="{{ route('categories.destroy', $cat->category_id) }}" method="POST" class="d-inline">
                                            @csrf
                                            @method('DELETE')
                                            <button type="button" class="btn btn-sm btn-icon btn-outline-danger shadow-sm rounded-circle btn-delete" data-name="{{ $cat->name }}">
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