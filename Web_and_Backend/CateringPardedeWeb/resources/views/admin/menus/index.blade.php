@extends('layouts.app', [
    'page' => __('Menu List'),
    'pageSlug' => 'menus'
])

@section('content')

<div class="row">
    <div class="col-md-12">

        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h4 class="card-title">Menu List</h4>

                <a href="{{ route('menus.create') }}" class="btn btn-primary btn-sm">
                    Add Menu
                </a>
            </div>

            <div class="card-body">
                <div class="table-responsive">
                    <table class="table tablesorter">
                        <thead class="text-primary">
                            <tr>
                                <th>Image</th>
                                <th>Name</th>
                                <th>Description</th>
                                <th>Category</th>
                                <th>Available</th>
                                <th class="text-center">Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($menus as $menu)
                            <tr>

                                {{-- IMAGE --}}
                                <td>
                                    @if($menu->image)
                                        <img src="{{ asset('storage/' . $menu->image) }}" 
                                             alt="menu image" 
                                             style="width:60px; height:60px; object-fit:cover; border-radius:6px;">
                                    @else
                                        <span class="text-muted">No Image</span>
                                    @endif
                                </td>

                                <td>{{ $menu->name }}</td>

                                {{-- DESCRIPTION --}}
                                <td>
                                    {{ $menu->description 
                                        ? \Illuminate\Support\Str::limit($menu->description, 50) 
                                        : '-' 
                                    }}
                                </td>

                                <td>{{ $menu->category->name ?? '-' }}</td>

                                <td>
                                    @if($menu->available)
                                        <span class="badge badge-success">Yes</span>
                                    @else
                                        <span class="badge badge-danger">No</span>
                                    @endif
                                </td>

                                <td class="text-center">
                                    <a href="{{ route('menus.edit', $menu->menu_id) }}" 
                                       class="btn btn-warning btn-sm">
                                        Edit
                                    </a>

                                    {{-- SWEETALERT DELETE --}}
                                    <form action="{{ route('menus.destroy', $menu->menu_id) }}" 
                                          method="POST" 
                                          class="d-inline">
                                        @csrf
                                        @method('DELETE')

                                        <button type="button" 
                                                class="btn btn-danger btn-sm btn-delete"
                                                data-name="{{ $menu->name }}">
                                            Delete
                                        </button>
                                    </form>

                                </td>

                            </tr>
                            @endforeach

                        </tbody>
                    </table>
                </div>
            </div>

        </div>

    </div>
</div>

@endsection