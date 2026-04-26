@extends('layouts.app', [
    'page' => __('Add Category'),
    'pageSlug' => 'categories'
])

@section('content')
    <div class="row">
        <div class="col-xl-6 col-lg-8 mx-auto">
            <div class="card aura-card shadow-lg">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h4 class="m-0 font-weight-bold">Add New Category</h4>
                    <a href="{{ route('categories.index') }}" class="btn btn-outline-secondary btn-sm rounded-pill px-3">
                        <i class="fas fa-arrow-left me-2"></i> BACK TO LIST
                    </a>
                </div>

                <div class="card-body p-4">
                    <form method="POST" action="{{ route('categories.store') }}">
                        @csrf

                        <div class="form-group mb-5">
                            <label>CATEGORY NAME</label>
                            <input type="text" name="name" class="form-control {{ $errors->has('name') ? ' is-invalid' : '' }}" placeholder="e.g. Appetizers" value="{{ old('name') }}" required>
                            @if($errors->has('name'))
                                <div class="invalid-feedback d-block mt-2">{{ $errors->first('name') }}</div>
                            @endif
                        </div>

                        <button type="submit" class="btn btn-primary w-100 py-3">
                            SAVE CATEGORY
                        </button>
                    </form>
                </div>
            </div>
        </div>
    </div>
@endsection