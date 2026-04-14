@extends('layouts.app')

@section('content')

<h3>Add Category</h3>

<form method="POST" action="{{ route('categories.store') }}">
    @csrf

    <input type="text" name="name" placeholder="Category name">

    <button type="submit">Save</button>
</form>

@endsection