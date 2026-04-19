@extends('layouts.app', [
    'page' => __('Edit Category'),
    'pageSlug' => 'categories'
])

@section('content')

<div class="row">
    <div class="col-md-6 ml-auto mr-auto">

        <div class="card">
            <div class="card-header">
                <h4 class="card-title">Edit Category</h4>
            </div>

            <div class="card-body">

                <form method="POST" action="{{ route('categories.update', $category->category_id) }}">
                    @csrf
                    @method('PUT')

                    {{-- NAME --}}
                    <div class="form-group">
                        <label>Category Name</label>
                        <input 
                            type="text" 
                            name="name" 
                            class="form-control {{ $errors->has('name') ? ' is-invalid' : '' }}"
                            value="{{ old('name', $category->name) }}"
                        >

                        @if($errors->has('name'))
                            <div class="invalid-feedback d-block">
                                {{ $errors->first('name') }}
                            </div>
                        @endif
                    </div>

                    <button type="submit" class="btn btn-primary">
                        Update
                    </button>

                    <a href="{{ route('categories.index') }}" class="btn btn-secondary">
                        Cancel
                    </a>

                </form>

            </div>
        </div>

    </div>
</div>

@endsection