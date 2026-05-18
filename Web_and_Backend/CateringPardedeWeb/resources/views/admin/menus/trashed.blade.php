@extends('layouts.app', [
    'page' => __('Trashed Menus'),
    'pageSlug' => 'menus'
])

@section('content')
    <div class="d-flex justify-content-between align-items-center mb-5">
        <div>
            <h2 class="m-0 font-weight-bold">Trashed Menus</h2>
            <p class="text-muted small uppercase letter-spacing-1 mb-0">Restore deleted items back to the active menu</p>
        </div>
        <a href="{{ route('menus.index') }}" class="btn btn-secondary rounded-pill px-4">
            <i class="fas fa-arrow-left me-2"></i> BACK TO LIST
        </a>
    </div>

    <div class="row">
        <div class="col-12">
            <div class="card aura-card border-0 shadow-lg">
                <div class="table-responsive">
                    <table class="table align-items-center mb-0">
                        <thead>
                            <tr>
                                <th>IMAGE</th>
                                <th>NAME</th>
                                <th>CATEGORY</th>
                                <th>DELETED AT</th>
                                <th class="text-center">ACTIONS</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($menus as $menu)
                            <tr>
                                <td>
                                    <div class="aura-avatar">
                                        @if($menu->image)
                                            <img src="{{ asset('storage/' . $menu->image) }}" alt="menu image" class="rounded-pill shadow-sm" style="width:45px; height:45px; object-fit:cover; border: 1px solid var(--aura-border); opacity: 0.5;">
                                        @else
                                            <div class="bg-dark rounded-pill d-flex align-items-center justify-content-center shadow-sm" style="width:45px; height:45px; border: 1px solid var(--aura-border);">
                                                <i class="fas fa-image text-muted opacity-25"></i>
                                            </div>
                                        @endif
                                    </div>
                                </td>
                                <td>
                                    <div class="mb-0 font-weight-bold text-white-50 fs-6">{{ $menu->name }}</div>
                                    <div class="text-muted extra-small uppercase mt-1">{{ \Illuminate\Support\Str::limit($menu->description, 30) }}</div>
                                </td>
                                <td>
                                    <span class="badge border border-secondary text-muted small">{{ $menu->category->name ?? 'Unclassified' }}</span>
                                </td>
                                <td>
                                    <span class="text-muted small">{{ $menu->deleted_at->format('d M Y, H:i') }}</span>
                                </td>
                                <td class="text-center">
                                    <div class="d-flex justify-content-center gap-3">
                                        <form action="{{ route('menus.restore', $menu->menu_id) }}" method="POST" class="d-inline">
                                            @csrf
                                            <button type="submit" class="btn btn-sm btn-icon btn-outline-success shadow-sm rounded-circle" title="Restore Item">
                                                <i class="fas fa-rotate-left"></i>
                                            </button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                            @empty
                            <tr>
                                <td colspan="5" class="text-center py-5">
                                    <i class="fas fa-trash-can fa-3x text-muted opacity-25 mb-3"></i>
                                    <p class="text-muted">Trash is empty. All your items are safe!</p>
                                </td>
                            </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
@endsection
