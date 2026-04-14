 @extends('layouts.app')

@section('content')

<h3>Edit Gallery</h3>

<form method="POST" action="{{ route('galleries.update', $gallery->id) }}" enctype="multipart/form-data">
    @csrf
    @method('PUT')

    <img src="{{ asset('storage/' . $gallery->image) }}" width="120"><br><br>

    <input type="file" name="image"><br><br>
    <textarea name="description">{{ $gallery->description }}</textarea><br><br>

    <button type="submit">Update</button>
</form>

@endsection