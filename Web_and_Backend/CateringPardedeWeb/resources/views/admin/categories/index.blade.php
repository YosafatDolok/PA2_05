@extends('layouts.app')

@section('content')

<h3>Categories</h3>

<a href="{{ route('categories.create') }}">Add Category</a>

<table border="1" cellpadding="10">
    <tr>
        <th>Name</th>
        <th>Action</th>
    </tr>

    @foreach($categories as $cat)
    <tr>
        <td>{{ $cat->name }}</td>
        <td>
            <a href="{{ route('categories.edit', $cat->id) }}">Edit</a>

            <form action="{{ route('categories.destroy', $cat->id) }}" method="POST" style="display:inline;">
                @csrf
                @method('DELETE')
                <button type="submit">Delete</button>
            </form>
        </td>
    </tr>
    @endforeach

</table>

@endsection