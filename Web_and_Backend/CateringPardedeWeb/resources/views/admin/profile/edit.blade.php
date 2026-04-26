@extends('layouts.app', [ 
    'page' => __('Edit Profile'),
    'pageSlug' => 'profile'
])

@section('content')
    <div class="row">
        <div class="col-xl-10 col-lg-12 mx-auto">
            <div class="card aura-card shadow-lg border-0 overflow-hidden">
                <div class="card-header border-0 p-5 pb-0">
                    <div class="d-flex align-items-center gap-4">
                        <div class="stat-icon" style="width: 60px; height: 60px; background: var(--aura-crimson); color: white; border-radius: 18px; display: flex; align-items: center; justify-content: center; font-size: 1.5rem; box-shadow: 0 10px 20px rgba(255, 51, 75, 0.3);">
                            <i class="fas fa-user-shield"></i>
                        </div>
                        <div>
                            <h3 class="m-0 font-weight-bold">Profile Settings</h3>
                            <p class="text-muted small uppercase letter-spacing-1 mb-0">Manage your account information</p>
                        </div>
                    </div>
                </div>

                <div class="card-body p-5">
                    {{-- SUCCESS MESSAGE --}}
                    @if(session('success'))
                        <div class="alert alert-success bg-success-light border-0 py-3 mb-5 border-start border-4 border-success">
                            <div class="d-flex align-items-center">
                                <i class="fas fa-check-double me-3 fs-5"></i>
                                <div>
                                    <div class="fw-bold fs-6">SUCCESS</div>
                                    <div class="small opacity-75">{{ session('success') }}</div>
                                </div>
                            </div>
                        </div>
                    @endif

                    <form method="POST" action="{{ route('profile.update') }}" enctype="multipart/form-data">
                        @csrf
                        @method('PUT')

                        <div class="row g-5">
                            {{-- LEFT: AVATAR --}}
                            <div class="col-lg-4 text-center">
                                <div class="position-relative d-inline-block mb-4">
                                    <div class="avatar-ring position-absolute top-50 start-50 translate-middle" style="width: 220px; height: 220px; border: 2px dashed rgba(255, 51, 75, 0.3); border-radius: 50%; animation: spin 10s linear infinite;"></div>
                                    <div class="aura-upload-zone rounded-circle mx-auto" style="width:180px; height:180px; min-height: 180px; z-index: 2; border: 4px solid var(--aura-crimson); padding: 5px; overflow: hidden;">
                                        <img id="previewImage" src="{{ $user->profile_picture ? asset('storage/' . $user->profile_picture) : 'https://ui-avatars.com/api/?name=' . urlencode($user->name) . '&background=EB4D4B&color=fff' }}" alt="Profile" class="aura-upload-preview active rounded-circle" style="width: 100%; height: 100%; object-fit: cover; padding: 0; position: static;">
                                    </div>
                                </div>
                                
                                <div class="px-4">
                                    <label class="btn btn-secondary w-100 py-3 rounded-4 mb-3 border-0" style="background: rgba(255,255,255,0.05);">
                                        <i class="fas fa-camera me-2"></i> CHANGE PHOTO
                                        <input type="file" name="profile_picture" accept="image/*" onchange="handleImagePreview(event)" hidden>
                                    </label>
                                    <p class="extra-small text-muted text-uppercase">Max size: 2MB</p>
                                </div>
                            </div>

                            {{-- RIGHT: CREDENTIALS --}}
                            <div class="col-lg-8 border-start border-secondary border-opacity-10">
                                <div class="row g-4">
                                    <div class="col-12">
                                        <div class="form-group mb-0">
                                            <label>FULL NAME</label>
                                            <input type="text" name="name" class="form-control form-control-aura" value="{{ old('name', $user->name) }}" required>
                                        </div>
                                    </div>

                                    <div class="col-md-6">
                                        <div class="form-group mb-0">
                                            <label>EMAIL ADDRESS</label>
                                            <input type="email" name="email" class="form-control form-control-aura" value="{{ old('email', $user->email) }}" required>
                                        </div>
                                    </div>

                                    <div class="col-md-6">
                                        <div class="form-group mb-0">
                                            <label>PHONE NUMBER</label>
                                            <input type="text" name="phone_number" class="form-control form-control-aura" value="{{ old('phone_number', $user->phone_number) }}">
                                        </div>
                                    </div>

                                    <div class="col-12 mt-5">
                                        <button type="submit" class="btn btn-primary btn-lg w-100 py-4 font-weight-bold shadow-aura">
                                            SAVE CHANGES
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <style>
    @keyframes spin { from { transform: translate(-50%, -50%) rotate(0deg); } to { transform: translate(-50%, -50%) rotate(360deg); } }
    .shadow-aura { box-shadow: 0 15px 35px rgba(255, 51, 75, 0.4); }
    </style>

    <script>
    function handleImagePreview(event) {
        const reader = new FileReader();
        const preview = document.getElementById('previewImage');
        
        reader.onload = function () {
            preview.src = reader.result;
            preview.classList.add('active');
        };
        if(event.target.files[0]) reader.readAsDataURL(event.target.files[0]);
    }
    </script>
@endsection