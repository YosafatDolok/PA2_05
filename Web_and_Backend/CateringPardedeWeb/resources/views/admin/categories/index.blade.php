@extends('layouts.app', [
    'page' => __('Categories'),
    'pageSlug' => 'categories'
])

@section('content')

<div class="row">
    <div class="col-md-12">

        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h4 class="card-title">Categories</h4>

                <a href="{{ route('categories.create') }}" class="btn btn-primary btn-sm">
                    Add Category
                </a>
            </div>

            <div class="card-body">
                <div class="table-responsive">
                    <table class="table tablesorter">
                        <thead class="text-primary">
                            <tr>
                                <th>Name</th>
                                <th class="text-center">Action</th>
                            </tr>
                        </thead>
                        <tbody>

                            @foreach($categories as $cat)
                            <tr>
                                <td>{{ $cat->name }}</td>

                                <td class="text-center">
                                    <a href="{{ route('categories.edit', $cat->category_id) }}" 
                                       class="btn btn-warning btn-sm">
                                        Edit
                                    </a>

                                    {{-- DELETE WITH SWEETALERT --}}
                                    <form action="{{ route('categories.destroy', $cat->category_id) }}" 
                                          method="POST" 
                                          class="d-inline">
                                        @csrf
                                        @method('DELETE')

                                        <button type="button" 
                                                class="btn btn-danger btn-sm btn-delete"
                                                data-name="{{ $cat->name }}">
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