@extends('layouts.app', [
    'page' => __('Menu List'),
    'pageSlug' => 'menus'
])

@section('content')
    <div class="d-flex justify-content-between align-items-center mb-5">
        <div>
            <h2 class="m-0 font-weight-bold">Menu List</h2>
            <p class="text-muted small uppercase letter-spacing-1 mb-0">Manage your dishes and items</p>
        </div>
        <div class="d-flex align-items-center">
            <a href="{{ route('menus.trashed') }}" class="btn btn-outline-primary rounded-pill px-4 mr-2">
                <i class="fas fa-trash-arrow-up mr-2"></i> VIEW TRASH
            </a>
            <a href="{{ route('menus.create') }}" class="btn btn-primary rounded-pill px-4">
                <i class="fas fa-plus mr-2"></i> ADD NEW MENU
            </a>
        </div>
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
                                <th>STATUS</th>
                                <th class="text-center">ACTIONS</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($menus as $menu)
                            <tr>
                                <td>
                                    <div class="aura-avatar">
                                        @if($menu->image)
                                            <img src="{{ asset('storage/' . $menu->image) }}" alt="menu image" class="rounded-pill shadow-sm" style="width:45px; height:45px; object-fit:cover; border: 1px solid var(--aura-border);">
                                        @else
                                            <div class="bg-dark rounded-pill d-flex align-items-center justify-content-center shadow-sm" style="width:45px; height:45px; border: 1px solid var(--aura-border);">
                                                <i class="fas fa-image text-muted opacity-25"></i>
                                            </div>
                                        @endif
                                    </div>
                                </td>
                                <td>
                                    <div class="mb-0 font-weight-bold text-white fs-6">{{ $menu->name }}</div>
                                    <div class="text-muted extra-small uppercase mt-1">{{ \Illuminate\Support\Str::limit($menu->description, 30) }}</div>
                                </td>
                                <td>
                                    <span class="badge border border-secondary text-muted small">{{ $menu->category->name ?? 'Unclassified' }}</span>
                                </td>
                                <td>
                                    @if($menu->available)
                                        <span class="badge bg-success-light">AVAILABLE</span>
                                    @else
                                        <span class="badge bg-danger-light">UNAVAILABLE</span>
                                    @endif
                                </td>
                                <td class="text-center">
                                    <div class="d-flex justify-content-center gap-3">
                                        <a href="{{ route('menus.edit', $menu->menu_id) }}" class="btn btn-sm btn-icon btn-secondary rounded-circle">
                                            <i class="fas fa-terminal"></i>
                                        </a>

                                        <form action="{{ route('menus.destroy', $menu->menu_id) }}" method="POST" class="d-inline">
                                            @csrf
                                            @method('DELETE')
                                            <button type="button" class="btn btn-sm btn-icon btn-outline-danger shadow-sm rounded-circle btn-delete" data-name="{{ $menu->name }}">
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