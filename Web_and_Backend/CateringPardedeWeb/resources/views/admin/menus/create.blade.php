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
                                <option value="{{ $cat->category_id }}">
                                    {{ $cat->name }}
                                </option>
                            @endforeach
                        </select>
                    </div>

                    {{-- DESCRIPTION --}}
                    <div class="form-group">
                        <label>Description</label>
                        <textarea name="description" 
                                  class="form-control custom-scrollbar" 
                                  rows="4">{{ old('description') }}</textarea>
                    </div>

                    {{-- AVAILABLE --}}
                    <div class="form-group">
                        <label>Available</label>
                        <div class="d-flex align-items-center mt-2">
                            <label class="switch">
                                <input type="checkbox" 
                                       name="available" 
                                       value="1"
                                       {{ old('available', 1) ? 'checked' : '' }}>
                                <span class="slider round"></span>
                            </label>
                            <span class="ml-2 text-primary">
                                {{ old('available', 1) ? 'Yes' : 'No' }}
                            </span>
                        </div>
                    </div>

                    {{-- IMAGE --}}
                    <div class="form-group">
                        <label>Image</label>

                        <div class="mb-2">
                            <img id="preview-image" 
                                 src="#" 
                                 alt="Preview" 
                                 style="display:none; width:120px; height:120px; object-fit:cover; border-radius:8px;">
                        </div>

                        <label class="btn btn-info btn-sm">
                            Choose Image
                            <input type="file" 
                                   name="image" 
                                   accept="image/*"
                                   onchange="previewImage(event)"
                                   hidden>
                        </label>
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
