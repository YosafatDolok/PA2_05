@extends('layouts.app')

@section('content')

<h3>Edit Menu</h3>

<form action="{{ route('menus.update', $menu->id) }}" method="POST" enctype="multipart/form-data">
    @csrf
    @method('PUT')

    <div>
        Name:
        <input type="text" name="name" value="{{ $menu->name }}">
    </div>

    <div>
        Category:
        <select name="category_id">
            @foreach($categories as $cat)
                <option value="{{ $cat->id }}" {{ $menu->category_id == $cat->id ? 'selected' : '' }}>
                    {{ $cat->name }}
                </option>
            @endforeach
        </select>
    </div>

    <div>
        Description:
        <textarea name="description">{{ $menu->description }}</textarea>
    </div>

    <div>
        Image:
        <input type="file" name="image">
    </div>

    <div>
        Available:
        <input type="checkbox" name="available" {{ $menu->available ? 'checked' : '' }}>
    </div>

    <button type="submit">Update</button>
</form>

@endsection