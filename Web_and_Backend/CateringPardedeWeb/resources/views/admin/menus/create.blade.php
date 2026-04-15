@extends('layouts.app', [
    'page' => __('Add Menu'),
    'pageSlug' => 'menus'
])

@section('content')

<div class="row">
    <div class="col-md-8 ml-auto mr-auto">

        <div class="card">
            <div class="card-header">
                <h4 class="card-title">Add Menu</h4>
            </div>

            <div class="card-body">

                <form action="{{ route('menus.store') }}" method="POST" enctype="multipart/form-data">
                    @csrf

                    {{-- NAME --}}
                    <div class="form-group">
                        <label>Name</label>
                        <input type="text" 
                               name="name" 
                               class="form-control"
                               value="{{ old('name') }}">
                    </div>

                    {{-- CATEGORY --}}
                    <div class="form-group">
                        <label>Category</label>
                        <select name="category_id" class="form-control">
                            @foreach($categories as $cat)
                                <option value="{{ $cat->id }}">
                                    {{ $cat->name }}
                                </option>
                            @endforeach
                        </select>
                    </div>

                    {{-- DESCRIPTION --}}
                    <div class="form-group">
                        <label>Description</label>
                        <textarea name="description" 
                                  class="form-control" 
                                  rows="4">{{ old('description') }}</textarea>
                    </div>

                    {{-- IMAGE --}}
                    <div class="form-group">
                        <label>Image</label>
                        <input type="file" 
                               name="image" 
                               class="form-control">
                    </div>

                    <button type="submit" class="btn btn-primary">
                        Save
                    </button>

                    <a href="{{ route('menus.index') }}" class="btn btn-secondary">
                        Cancel
                    </a>

                </form>

            </div>
        </div>

    </div>
</div>

@endsection