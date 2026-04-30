@extends('layouts.app', [ 
    'page' => __('Edit Menu'),
    'pageSlug' => 'menus'
])

@section('content')
    <div class="row">
        <div class="col-xl-8 col-lg-10 mx-auto">
            <div class="card aura-card shadow-lg">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h4 class="m-0 font-weight-bold">Edit Menu Item</h4>
                    <a href="{{ route('menus.index') }}" class="btn btn-outline-secondary btn-sm rounded-pill px-3">
                        <i class="fas fa-arrow-left me-2"></i> CANCEL
                    </a>
                </div>

                <div class="card-body p-4">
                    <form action="{{ route('menus.update', $menu->menu_id) }}" method="POST" enctype="multipart/form-data">
                        @csrf
                        @method('PUT')

                        <div class="row g-4">
                            {{-- NAME --}}
                            <div class="col-md-6">
                                <div class="form-group mb-0">
                                    <label>MENU NAME</label>
                                    <input type="text" name="name" class="form-control @error('name') is-invalid @enderror" value="{{ old('name', $menu->name) }}">
                                    @error('name')
                                        <span class="invalid-feedback">{{ $message }}</span>
                                    @enderror
                                </div>
                            </div>

                            {{-- CATEGORY --}}
                            <div class="col-md-6">
                                <div class="form-group mb-0">
                                    <label>CATEGORY</label>
                                    <select name="category_id" class="form-select @error('category_id') is-invalid @enderror">
                                        @foreach($categories as $cat)
                                            <option value="{{ $cat->category_id }}" {{ old('category_id', $menu->category_id) == $cat->category_id ? 'selected' : '' }}>
                                                {{ $cat->name }}
                                            </option>
                                        @endforeach
                                    </select>
                                    @error('category_id')
                                        <span class="invalid-feedback">{{ $message }}</span>
                                    @enderror
                                </div>
                            </div>

                            {{-- DESCRIPTION --}}
                            <div class="col-12">
                                <div class="form-group mb-0">
                                    <label>DESCRIPTION</label>
                                    <textarea name="description" class="form-control @error('description') is-invalid @enderror" rows="4">{{ old('description', $menu->description) }}</textarea>
                                    @error('description')
                                        <span class="invalid-feedback">{{ $message }}</span>
                                    @enderror
                                </div>
                            </div>

                            {{-- IMAGE --}}
                            <div class="col-md-8">
                                <div class="form-group mb-0">
                                    <label>MENU IMAGE</label>
                                    <div class="d-flex align-items-center gap-4 mt-2">
                                        <div class="aura-upload-zone" style="width: 120px; min-height: 120px; border-radius: 15px;">
                                            @if($menu->image)
                                                <img id="previewImage" src="{{ asset('storage/' . $menu->image) }}" alt="Preview" class="aura-upload-preview active">
                                            @else
                                                <div class="aura-upload-placeholder" id="placeholder" style="padding: 10px;">
                                                    <i class="fas fa-image mb-0" style="font-size: 1.5rem;"></i>
                                                </div>
                                                <img id="previewImage" src="#" alt="Preview" class="aura-upload-preview">
                                            @endif
                                        </div>
                                        <label class="btn btn-aura btn-sm mb-0">
                                            <i class="fas fa-image me-2"></i> REPLACE IMAGE
                                            <input type="file" name="image" accept="image/*" onchange="handleImagePreview(event)" hidden>
                                        </label>
                                    </div>
                                </div>
                            </div>

                            {{-- AVAILABLE --}}
                            <div class="col-md-4">
                                <div class="form-group mb-0">
                                    <label class="d-block">STATUS</label>
                                    <div class="form-check form-switch mt-2">
                                        <input class="form-check-input" type="checkbox" name="available" value="1" id="availableSwitch" {{ old('available', $menu->available) ? 'checked' : '' }} style="transform: scale(1.4);">
                                        <label class="form-check-label ms-3 text-white-50" for="availableSwitch">AVAILABLE</label>
                                    </div>
                                </div>
                            </div>

                            <div class="col-12 mt-5">
                                <button type="submit" class="btn btn-primary w-100 py-3 font-weight-bold">
                                    UPDATE MENU ITEM
                                </button>
                            </div>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <script>
    function handleImagePreview(event) {
        const reader = new FileReader();
        const placeholder = document.getElementById('placeholder');
        const preview = document.getElementById('previewImage');
        
        reader.onload = function(){
            preview.src = reader.result;
            preview.classList.add('active');
            if(placeholder) placeholder.style.display = 'none';
        };
        
        if(event.target.files[0]) {
            reader.readAsDataURL(event.target.files[0]);
        }
    }
    </script>
@endsection