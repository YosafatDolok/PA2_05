@extends('layouts.app', [
    'page' => __('Add Gallery'),
    'pageSlug' => 'galleries'
])

@section('content')
    <div class="row">
        <div class="col-xl-7 col-lg-9 mx-auto">
            <div class="card aura-card shadow-lg">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h4 class="m-0 font-weight-bold">Upload New Image</h4>
                    <a href="{{ route('galleries.index') }}" class="btn btn-outline-secondary btn-sm rounded-pill px-3">
                        <i class="fas fa-arrow-left me-2"></i> CANCEL
                    </a>
                </div>

                <div class="card-body p-4">
                    <form method="POST" action="{{ route('galleries.store') }}" enctype="multipart/form-data">
                        @csrf

                        <div class="row g-4">
                            {{-- IMAGE --}}
                            <div class="col-12">
                                <div class="form-group mb-0 text-center">
                                    <label class="d-block mb-3">IMAGE FILE</label>
                                    
                                    <div class="aura-upload-zone mb-4" id="uploadZone">
                                        <div class="aura-upload-placeholder" id="placeholder">
                                            <i class="fas fa-cloud-arrow-up"></i>
                                            <p class="text-muted small mb-0">Choose an image to upload</p>
                                        </div>
                                        <img id="previewImage" src="#" alt="Preview" class="aura-upload-preview">
                                    </div>

                                    <label class="btn btn-aura px-5 py-3">
                                        <i class="fas fa-image me-2"></i> SELECT IMAGE
                                        <input type="file" name="image" accept="image/*" onchange="handleImagePreview(event)" hidden required>
                                    </label>
                                </div>
                            </div>

                            {{-- DESCRIPTION --}}
                            <div class="col-12 mt-4">
                                <div class="form-group mb-0">
                                    <label>DESCRIPTION</label>
                                    <textarea name="description" class="form-control" rows="3" placeholder="Add a description for this image...">{{ old('description') }}</textarea>
                                </div>
                            </div>

                            <div class="col-12 mt-5">
                                <button type="submit" class="btn btn-primary w-100 py-3 font-weight-bold fs-5 shadow-lg">
                                    SAVE TO GALLERY
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
            placeholder.style.opacity = '0';
            setTimeout(() => {
                placeholder.style.display = 'none';
            }, 300);
        };
        
        if(event.target.files[0]) {
            reader.readAsDataURL(event.target.files[0]);
        }
    }
    </script>
@endsection