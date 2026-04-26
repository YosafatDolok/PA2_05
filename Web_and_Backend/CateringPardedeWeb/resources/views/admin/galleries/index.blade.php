@extends('layouts.app', [
    'page' => __('Galleries'),
    'pageSlug' => 'galleries'
])

@section('content')
    <div class="d-flex justify-content-between align-items-center mb-5">
        <div>
            <h2 class="m-0 font-weight-bold">Gallery</h2>
            <p class="text-muted small uppercase letter-spacing-1 mb-0">Manage your images</p>
        </div>
        <a href="{{ route('galleries.create') }}" class="btn btn-primary rounded-pill px-4">
            <i class="fas fa-plus me-2"></i> UPLOAD IMAGE
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
                                <th>DESCRIPTION</th>
                                <th class="text-center">ACTIONS</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($galleries as $g)
                            <tr>
                                <td>
                                    @if($g->image)
                                        <img src="{{ asset('storage/' . $g->image) }}" alt="gallery image" class="rounded-3 shadow-sm border border-secondary p-1" style="width:70px; height:70px; object-fit:cover;">
                                    @else
                                        <div class="bg-dark rounded-3 d-flex align-items-center justify-content-center shadow-sm border border-secondary" style="width:70px; height:70px;">
                                            <i class="fas fa-image text-muted opacity-25"></i>
                                        </div>
                                    @endif
                                </td>
                                <td>
                                    <div class="text-white mb-1 fw-bold">{{ $g->description ? \Illuminate\Support\Str::limit($g->description, 60) : 'NO METADATA AVAILABLE' }}</div>
                                </td>
                                <td class="text-center">
                                    <div class="d-flex justify-content-center gap-3">
                                        <a href="{{ route('galleries.edit', $g->id) }}" class="btn btn-sm btn-icon btn-secondary rounded-circle">
                                            <i class="fas fa-terminal"></i>
                                        </a>

                                        <form action="{{ route('galleries.destroy', $g->id) }}" method="POST" class="d-inline">
                                            @csrf
                                            @method('DELETE')
                                            <button type="button" class="btn btn-sm btn-icon btn-outline-danger shadow-sm rounded-circle btn-delete" data-name="this visual asset">
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
