@extends('layouts.app', [ 
    'page' => __('Edit Menu'),
    'pageSlug' => 'menus'
])

@section('content')

<div class="row">
    <div class="col-md-8">
        <div class="card">

            <div class="card-header">
                <h4 class="card-title">Edit Menu</h4>
            </div>

            <div class="card-body">

                @if ($errors->any())
                    <div class="alert alert-danger">
                        <ul class="mb-0">
                            @foreach ($errors->all() as $error)
                                <li>{{ $error }}</li>
                            @endforeach
                        </ul>
                    </div>
                @endif

                <form action="{{ route('menus.update', $menu->menu_id) }}" method="POST" enctype="multipart/form-data">
                    @csrf
                    @method('PUT')

                    {{-- NAME --}}
                    <div class="form-group">
                        <label>Name</label>
                        <input type="text" 
                               name="name" 
                               class="form-control" 
                               value="{{ old('name', $menu->name) }}">
                    </div>

                    {{-- CATEGORY --}}
                    <div class="form-group">
                        <label>Category</label>
                        <select name="category_id" class="form-control">
                            @foreach($categories as $cat)
                                <option value="{{ $cat->category_id }}" 
                                    {{ $menu->category_id == $cat->category_id ? 'selected' : '' }}>
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
                                  rows="3">{{ old('description', $menu->description) }}</textarea>
                    </div>

                    {{-- AVAILABLE --}}
                    <div class="form-group">
                        <label>Available</label>
                        <div class="d-flex align-items-center mt-2">
                            <label class="switch">
                                <input type="checkbox" 
                                       name="available" 
                                       value="1"
                                       {{ old('available', $menu->available) ? 'checked' : '' }}>
                                <span class="slider"></span>
                            </label>
                            <span class="ml-2 text-primary">
                                {{ old('available', $menu->available) ? 'Yes' : 'No' }}
                            </span>
                        </div>
                    </div>

                    {{-- IMAGE --}}
                    <div class="form-group">
                        <label>Image</label>

                        <div class="mb-2">
                            <img id="preview-image" 
                                 src="{{ $menu->image ? asset('storage/' . $menu->image) : '#' }}" 
                                 alt="Preview" 
                                 style="{{ $menu->image ? '' : 'display:none;' }} width:120px; height:120px; object-fit:cover; border-radius:8px;">
                        </div>

                        <label class="btn btn-info btn-sm">
                            Change Image
                            <input type="file" 
                                   name="image" 
                                   accept="image/*"
                                   onchange="previewImage(event)"
                                   hidden>
                        </label>
                    </div>

                    <button type="submit" class="btn btn-primary">
                        Update
                    </button>

                    <a href="{{ route('menus.index') }}" class="btn btn-secondary">
                        Back
                    </a>
                </form>

            </div>
        </div>
    </div>
</div>

@endsection