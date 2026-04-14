@extends('layouts.app')

@section('content')

<h3>Add Menu</h3>

<form action="{{ route('menus.store') }}" method="POST" enctype="multipart/form-data">
    @csrf

    <div>
        Name:
        <input type="text" name="name">
    </div>

    <div>
        Category:
        <select name="category_id">
            @foreach($categories as $cat)
                <option value="{{ $cat->id }}">{{ $cat->name }}</option>
            @endforeach
        </select>
    </div>

    <div>
        Description:
        <textarea name="description"></textarea>
    </div>

    <div>
        Image:
        <input type="file" name="image">
    </div>

    <button type="submit">Save</button>
</form>

@endsection