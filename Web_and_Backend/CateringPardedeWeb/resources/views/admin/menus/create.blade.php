@extends('layouts.app', [
    'page' => __('Add Menu'),
    'pageSlug' => 'menus'
])

@section('content')
    <div class="row">
        <div class="col-xl-8 col-lg-10 mx-auto">
            <div class="card aura-card shadow-lg">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h4 class="m-0 font-weight-bold">Add New Menu Item</h4>
                    <a href="{{ route('menus.index') }}" class="btn btn-outline-secondary btn-sm rounded-pill px-3">
                        <i class="fas fa-arrow-left me-2"></i> BACK TO LIST
                    </a>
                </div>

                <div class="card-body p-4">
                    <form action="{{ route('menus.store') }}" method="POST" enctype="multipart/form-data">
                        @csrf

                        <div class="row g-4">
                            {{-- NAME --}}
                            <div class="col-md-6">
                                <div class="form-group mb-0">
                                    <label>MENU NAME</label>
                                    <input type="text" name="name" class="form-control @error('name') is-invalid @enderror" placeholder="e.g. Fried Rice" value="{{ old('name') }}">
                                    @error('name')
                                        <span class="invalid-feedback">{{ $message }}</span>
                                    @enderror
                                </div>
                            </div>

                             {{-- CATEGORY --}}
                             <div class="col-md-6">
                                 <div class="form-group mb-0">
                                     <label>CATEGORY</label>
                                     <div class="aura-select-container" id="categorySelect">
                                         <div class="aura-select-trigger">
                                             <span>{{ old('category_id') ? $categories->firstWhere('category_id', old('category_id'))->name : 'Pilih Kategori' }}</span>
                                             <i class="fas fa-chevron-down"></i>
                                         </div>
                                         <div class="aura-select-options">
                                             @foreach($categories as $cat)
                                                 <div class="aura-option {{ old('category_id') == $cat->category_id ? 'selected' : '' }}" 
                                                      data-value="{{ $cat->category_id }}">
                                                     {{ $cat->name }}
                                                 </div>
                                             @endforeach
                                         </div>
                                         <input type="hidden" name="category_id" value="{{ old('category_id') }}" required>
                                     </div>
                                     @error('category_id')
                                         <span class="invalid-feedback d-block">{{ $message }}</span>
                                     @enderror
                                 </div>
                             </div>

                            {{-- DESCRIPTION --}}
                            <div class="col-12">
                                <div class="form-group mb-0">
                                    <label>DESCRIPTION</label>
                                    <textarea name="description" class="form-control @error('description') is-invalid @enderror" rows="4" placeholder="Enter dish details...">{{ old('description') }}</textarea>
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
                                            <div class="aura-upload-placeholder" id="placeholder" style="padding: 10px;">
                                                <i class="fas fa-image mb-0" style="font-size: 1.5rem;"></i>
                                            </div>
                                            <img id="previewImage" src="#" alt="Preview" class="aura-upload-preview">
                                        </div>
                                        <label class="btn btn-aura btn-sm mb-0">
                                            <i class="fas fa-upload me-2"></i> UPLOAD IMAGE
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
                                        <input class="form-check-input" type="checkbox" name="available" value="1" id="availableSwitch" {{ old('available', 1) ? 'checked' : '' }} style="transform: scale(1.4);">
                                        <label class="form-check-label ms-3 text-white-50" for="availableSwitch">AVAILABLE</label>
                                    </div>
                                </div>
                            </div>

                            <div class="col-12 mt-5">
                                <button type="submit" class="btn btn-primary w-100 py-3 font-weight-bold">
                                    SAVE MENU ITEM
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
            placeholder.style.display = 'none';
        };
        
        if(event.target.files[0]) {
            reader.readAsDataURL(event.target.files[0]);
        }
    }
    
    // Custom Select Interaction
    const selectContainer = document.getElementById('categorySelect');
    const selectTrigger = selectContainer.querySelector('.aura-select-trigger');
    const selectOptions = selectContainer.querySelector('.aura-select-options');
    const optionsList = selectContainer.querySelectorAll('.aura-option');
    const hiddenInput = selectContainer.querySelector('input[type="hidden"]');
    
    selectTrigger.addEventListener('click', () => {
        selectContainer.classList.toggle('active');
    });
    
    optionsList.forEach(option => {
        option.addEventListener('click', () => {
            const value = option.getAttribute('data-value');
            const text = option.textContent.trim();
            
            // Update Trigger
            selectTrigger.querySelector('span').textContent = text;
            
            // Update Hidden Input
            hiddenInput.value = value;
            
            // Toggle selected class
            optionsList.forEach(opt => opt.classList.remove('selected'));
            option.classList.add('selected');
            
            // Close dropdown
            selectContainer.classList.remove('active');
        });
    });
    
    // Close when clicking outside
    document.addEventListener('click', (e) => {
        if (!selectContainer.contains(e.target)) {
            selectContainer.classList.remove('active');
        }
    });
    </script>
@endsection
