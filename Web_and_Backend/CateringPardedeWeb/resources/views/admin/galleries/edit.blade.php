@extends('layouts.app', [
    'page' => __('Edit Gallery'),
    'pageSlug' => 'galleries'
])

@section('content')

<div class="row">
    <div class="col-md-8 ml-auto mr-auto">

        <div class="card">
            <div class="card-header">
                <h4 class="card-title">Edit Gallery</h4>
            </div>

            <div class="card-body">

                <form method="POST" 
                      action="{{ route('galleries.update', $gallery->id) }}" 
                      enctype="multipart/form-data">
                    @csrf
                    @method('PUT')

                    {{-- CURRENT IMAGE --}}
                    <div class="form-group">
                        <label>Current Image</label>
                        <div class="mb-2">
                            <img src="{{ asset('storage/' . $gallery->image) }}" 
                                 alt="gallery image"
                                 style="width:120px; height:120px; object-fit:cover; border-radius:8px;">
                        </div>
                    </div>

                    {{-- NEW IMAGE --}}
                    <div class="form-group">
                        <label>Change Image</label>

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

                    {{-- DESCRIPTION --}}
                    <div class="form-group">
                        <label>Description</label>
                        <textarea name="description" 
                                  class="form-control custom-scrollbar" 
                                  rows="4">{{ old('description', $gallery->description) }}</textarea>
                    </div>

                    <button type="submit" class="btn btn-primary">
                        Update
                    </button>

                    <a href="{{ route('galleries.index') }}" class="btn btn-secondary">
                        Cancel
                    </a>

                </form>

            </div>
        </div>

    </div>
</div>

@endsection