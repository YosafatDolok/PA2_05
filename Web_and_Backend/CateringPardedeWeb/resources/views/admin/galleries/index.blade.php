@extends('layouts.app')

@section('content')

<h3>Galleries</h3>

<a href="{{ route('galleries.create') }}">Add Gallery</a>

<table border="1" cellpadding="10">
    <tr>
        <th>Image</th>
        <th>Description</th>
        <th>Action</th>
    </tr>

    @foreach($galleries as $g)
    <tr>
        <td>
            <img src="{{ asset('storage/' . $g->image) }}" width="100">
        </td>
        <td>{{ $g->description }}</td>
        <td>
            <a href="{{ route('galleries.edit', $g->id) }}">Edit</a>

            <form action="{{ route('galleries.destroy', $g->id) }}" method="POST" style="display:inline;">
                @csrf
                @method('DELETE')
                <button type="submit">Delete</button>
            </form>
        </td>
    </tr>
    @endforeach

</table>

@endsection