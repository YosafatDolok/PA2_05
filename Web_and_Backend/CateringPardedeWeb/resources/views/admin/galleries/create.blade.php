@extends('layouts.app')

@section('content')

<h3>Add Gallery</h3>

<form method="POST" action="{{ route('galleries.store') }}" enctype="multipart/form-data">
    @csrf

    <input type="file" name="image"><br><br>
    <textarea name="description" placeholder="Description"></textarea><br><br>

    <button type="submit">Save</button>
</form>

@endsection