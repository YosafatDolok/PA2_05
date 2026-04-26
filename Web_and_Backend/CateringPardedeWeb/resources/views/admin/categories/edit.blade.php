@extends('layouts.app', [
    'page' => __('Edit Category'),
    'pageSlug' => 'categories'
])

@section('content')
    <div class="row">
        <div class="col-xl-6 col-lg-8 mx-auto">
            <div class="card aura-card shadow-lg">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h4 class="m-0 font-weight-bold">Edit Category</h4>
                    <a href="{{ route('categories.index') }}" class="btn btn-outline-secondary btn-sm rounded-pill px-3">
                        <i class="fas fa-arrow-left me-2"></i> CANCEL
                    </a>
                </div>

                <div class="card-body p-4">
                    <form method="POST" action="{{ route('categories.update', $category->category_id) }}">
                        @csrf
                        @method('PUT')

                        <div class="form-group mb-5">
                            <label>CATEGORY NAME</label>
                            <input type="text" name="name" class="form-control {{ $errors->has('name') ? ' is-invalid' : '' }}" value="{{ old('name', $category->name) }}" required>
                            @if($errors->has('name'))
                                <div class="invalid-feedback d-block mt-2">{{ $errors->first('name') }}</div>
                            @endif
                        </div>

                        <button type="submit" class="btn btn-primary w-100 py-3">
                            UPDATE CATEGORY
                        </button>
                    </form>
                </div>
            </div>
        </div>
    </div>
@endsection