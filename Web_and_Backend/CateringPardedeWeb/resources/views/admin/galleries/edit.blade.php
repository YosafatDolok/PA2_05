@extends('layouts.app', [
    'page' => __('Edit Galeri'),
    'pageSlug' => 'galleries'
])

@section('content')
    <div class="row">
        <div class="col-xl-7 col-lg-9 mx-auto">
            <div class="card aura-card shadow-lg">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h4 class="m-0 font-weight-bold">Edit Gambar Galeri</h4>
                    <a href="{{ route('galleries.index') }}" class="btn btn-outline-secondary btn-sm rounded-pill px-3">
                        <i class="fas fa-arrow-left me-2"></i> BATAL
                    </a>
                </div>

                <div class="card-body p-4">
                    <form method="POST" action="{{ route('galleries.update', $gallery->id) }}" enctype="multipart/form-data">
                        @csrf
                        @method('PUT')

                        <div class="row g-4">
                            <div class="col-md-5">
                                <div class="form-group mb-0">
                                    <label class="mb-3 text-center d-block">GAMBAR SEKARANG</label>
                                    <div class="preview-only-zone">
                                        <img src="{{ asset('storage/' . $gallery->image) }}" alt="gallery image" class="img-fluid rounded-3" style="max-height: 230px;">
                                    </div>
                                </div>
                            </div>

                            <div class="col-md-7">
                                <div class="form-group mb-4">
                                    <label class="mb-3 text-center d-block">GANTI GAMBAR</label>
                                    <div class="aura-upload-zone" style="min-height: 230px;">
                                        <div class="aura-upload-placeholder" id="placeholder">
                                            <i class="fas fa-upload"></i>
                                            <p class="text-muted extra-small mb-0">Pilih gambar baru</p>
                                        </div>
                                        <img id="previewImage" src="#" alt="Preview" class="aura-upload-preview">
                                    </div>
                                    <label class="btn btn-aura btn-sm w-100 mt-3">
                                        <i class="fas fa-image me-2"></i> PILIH FILE
                                        <input type="file" name="image" accept="image/*" onchange="handleImagePreview(event)" hidden>
                                    </label>
                                </div>

                                <div class="form-group mb-0">
                                    <label>DESKRIPSI</label>
                                    <textarea name="description" class="form-control form-control-aura" rows="2" placeholder="Tambahkan deskripsi...">{{ old('description', $gallery->description) }}</textarea>
                                </div>
                            </div>

                            <div class="col-12 mt-4">
                                <button type="submit" class="btn btn-primary w-100 py-3 font-weight-bold shadow-lg">
                                    PERBARUI ASET GALERI
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