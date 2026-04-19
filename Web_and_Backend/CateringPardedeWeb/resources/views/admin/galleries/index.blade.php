@extends('layouts.app', [
    'page' => __('Galleries'),
    'pageSlug' => 'galleries'
])

@section('content')

<div class="row">
    <div class="col-md-12">

        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h4 class="card-title">Galleries</h4>

                <a href="{{ route('galleries.create') }}" class="btn btn-primary btn-sm">
                    Add Gallery
                </a>
            </div>

            <div class="card-body">
                <div class="table-responsive">
                    <table class="table tablesorter">
                        <thead class="text-primary">
                            <tr>
                                <th>Image</th>
                                <th>Description</th>
                                <th class="text-center">Action</th>
                            </tr>
                        </thead>
                        <tbody>

                            @foreach($galleries as $g)
                            <tr>

                                {{-- IMAGE --}}
                                <td>
                                    @if($g->image)
                                        <img src="{{ asset('storage/' . $g->image) }}" 
                                             alt="gallery image"
                                             style="width:60px; height:60px; object-fit:cover; border-radius:6px;">
                                    @else
                                        <span class="text-muted">No Image</span>
                                    @endif
                                </td>

                                {{-- DESCRIPTION --}}
                                <td>
                                    {{ $g->description 
                                        ? \Illuminate\Support\Str::limit($g->description, 50) 
                                        : '-' 
                                    }}
                                </td>

                                {{-- ACTION --}}
                                <td class="text-center">
                                    <a href="{{ route('galleries.edit', $g->id) }}" 
                                       class="btn btn-warning btn-sm">
                                        Edit
                                    </a>

                                    {{-- SWEETALERT DELETE --}}
                                    <form action="{{ route('galleries.destroy', $g->id) }}" 
                                          method="POST" 
                                          class="d-inline">
                                        @csrf
                                        @method('DELETE')

                                        <button type="button" 
                                                class="btn btn-danger btn-sm btn-delete"
                                                data-name="this gallery">
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